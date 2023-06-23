%% Build visual vocabulary using k-means %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_form_codebook
    fprintf('\nBuild visual vocabulary:\n');

    % concatenate all descriptors from all images into a n x d matrix 
    DESC = [];
    labels_train = cat(1,desc_train.class);
    num_images_per_class = max(arrayfun(@(x) numel(desc_train(labels_train==x)), 1:length(data)));
    for i=1:length(data)
        desc_class = desc_train(labels_train==i);
        randimages = randperm(min(num_images_per_class, numel(desc_class)));
        randimages = randimages(1:5);
        DESC = vertcat(DESC, desc_class(randimages).sift);
    end

    % sample random M (e.g. M=20,000) descriptors from all training descriptors
    r = randperm(size(DESC,1));
    r = r(1:min(length(r),nfeat_codebook));

    DESC = DESC(r,:);

    % run k-means
    K = nwords_codebook; % size of visual vocabulary
    fprintf('running k-means clustering of %d points into %d clusters...\n',...
        size(DESC,1),K)
    % input matrix needs to be transposed as the k-means function expects 
    % one point per column rather than per row

    % form options structure for clustering
    cluster_options.maxiters = max_km_iters;
    cluster_options.verbose  = 1;

    [VC] = kmeans_bo(double(DESC),K,max_km_iters);%visual codebook
    VC = VC';%transpose for compatibility with following functions
    clear DESC;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%   EXERCISE 1: K-means Descriptor quantization                           %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% K-means descriptor quantization means assignment of each feature
% descriptor with the identity of its nearest cluster mean, i.e.
% visual word. Your task is to quantize SIFT descriptors in all
% training and test images using the visual dictionary 'VC'
% constructed above.
%
% TODO:
% 1.1 compute Euclidean distances between VC and all descriptors
%     in each training and test image. Hint: to compute all-to-all
%     distance matrix for two sets of descriptors D1 & D2 use
%     dmat=eucliddist(D1,D2);
% 1.2 compute visual word ID for each feature by minimizing
%     the distance between feature SIFT descriptors and VC.
%     Hint: apply 'min' function to 'dmat' computed above along
%     the dimension (1 or 2) corresponding to VC, i.g.:
%     [mv,visword]=min(dmat,[],2); if you compute dmat as 
%     dmat=eucliddist(dscr(i).sift,VC);

if do_feat_quantization
    fprintf('\nFeature quantization (hard-assignment)...\n');
    for i=1:length(desc_train)  
      sift = desc_train(i).sift(:,:);
      dmat = eucliddist(sift,VC);
      [quantdist,visword] = min(dmat,[],2); 
      % save feature labels
      desc_train(i).visword = visword;
      desc_train(i).quantdist = quantdist;
    end

    for i=1:length(desc_test)    
      sift = desc_test(i).sift(:,:); 
      dmat = eucliddist(sift,VC);
      [quantdist,visword] = min(dmat,[],2);
      % save feature labels
      desc_test(i).visword = visword;
      desc_test(i).quantdist = quantdist;
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   End of EXERCISE 1                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Visualize visual words (i.e. clusters) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  To visually verify feature quantization computed above, we can show 
%  image patches corresponding to the same visual word. 

if (visualize_words && have_screen)
    figure;
    %num_words = size(VC,1) % loop over all visual word types
    num_words = 10;
    fprintf('\nVisualize visual words (%d examples)\n', num_words);
    for i=1:num_words
      patches={};
      for j=1:length(desc_train) % loop over all images
        d=desc_train(j);
        ind=find(d.visword==i);
        if length(ind)
          %img=imread(strrep(d.imgfname,'_train',''));
          img=rgb2gray(imread(d.imgfname));
          
          x=d.c(ind); y=d.r(ind); r=d.rad(ind);
          bbox=[x-2*r y-2*r x+2*r y+2*r];
          for k=1:length(ind) % collect patches of a visual word i in image j      
            patches{end+1}=cropbbox(img,bbox(k,:));
          end
        end
      end
      % display all patches of the visual word i
      clf, showimage(combimage(patches,[],1.5))
      title(sprintf('%d examples of Visual Word #%d',length(patches),i))
      pause
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Part 2: represent images with BOF histograms %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%   EXERCISE 2: Bag-of-Features image classification                      %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Represent each image by the normalized histogram of visual
% word labels of its features. Compute word histogram H over 
% the whole image, normalize histograms w.r.t. L1-norm.
%
% TODO:
% 2.1 for each training and test image compute H. Hint: use
%     Matlab function 'histc' to compute histograms.


N = size(VC,1); % number of visual words

for i=1:length(desc_train) 
    visword = desc_train(i).visword;
    H = histc(visword,[1:nwords_codebook]);
  
    % normalize bow-hist (L1 norm)
    if norm_bof_hist
        H = H/sum(H);
    end
  
    % save histograms
    desc_train(i).bof=H(:)';
end

for i=1:length(desc_test) 
    visword = desc_test(i).visword;
    H = histc(visword,[1:nwords_codebook]);
  
    % normalize bow-hist (L1 norm)
    if norm_bof_hist
        H = H/sum(H);
    end
  
    % save histograms
    desc_test(i).bof=H(:)';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   End of EXERCISE 2                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%