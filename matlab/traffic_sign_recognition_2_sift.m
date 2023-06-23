% Extract SIFT features fon training and test images
if do_feat_extraction   
    extract_sift_features(fullfile('..','img',dataset_dir),desc_name,file_ext)

    % Extract features from subfolders in the "Train/" folder as well
    extract_sift_features(fullfile('..','img', strcat(dataset_dir, '/Train') ),desc_name,file_ext)
    % Extract features from subfolders in the "resizedTrain/" folder as well
    extract_sift_features(fullfile('..','img', strcat(dataset_dir, '/resizedTrain') ),desc_name,file_ext)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Part 1: quantize pre-computed image features %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Load pre-computed SIFT features for training images

% The resulting structure array 'desc' will contain one
% entry per images with the following fields:
%  desc(i).r :    Nx1 array with y-coordinates for N SIFT features
%  desc(i).c :    Nx1 array with x-coordinates for N SIFT features
%  desc(i).rad :  Nx1 array with radius for N SIFT features
%  desc(i).sift : Nx128 array with N SIFT descriptors
%  desc(i).imgfname : file name of original image



file_desc_train = ['desc_train (training SIFT features) - ', desc_name, '.mat'];
path_file_desc_train = fullfile(basepath,'img',dataset_dir,file_desc_train);

if isfile(path_file_desc_train)
    load(path_file_desc_train);
else
    lasti=1;
    for i = 1:length(data)
         images_descs = get_descriptors_files(data,i,file_ext,desc_name,'train');
         for j = 1:length(images_descs) 
            fname = fullfile(basepath,'img',dataset_dir,images_descs{j});
            fprintf('Loading %s \n',fname);
            tmp = load(fname,'-mat');
            tmp.desc.class=i;
            tmp.desc.imgfname=regexprep(fname,['.' desc_name], dotFile_ext);
            desc_train(lasti)=tmp.desc;
            desc_train(lasti).sift = single(desc_train(lasti).sift);
            lasti=lasti+1;
         end
    end
    
    save(path_file_desc_train,'desc_train');
end





%% Visualize SIFT features for training images
if (visualize_feat && have_screen)
    nti=10;
    fprintf('\nVisualize features for %d training images\n', nti);
    imgind=randperm(length(desc_train));
    for i=1:nti
        d=desc_train(imgind(i));
        clf, showimage(imread(strrep(d.imgfname,'_train','')));
        x=d.c;
        y=d.r;
        rad=d.rad;
        showcirclefeaturesrad([x,y,rad]);
        title(sprintf('%d features in %s',length(d.c),d.imgfname));
        pause
    end
end


%% Load pre-computed SIFT features for test images


if testIfTrueValidationIfFalse
    file_desc_test = ['desc_test (test SIFT features) - ', desc_name, '.mat'];
else
    file_desc_test = ['desc_test (validation SIFT features) - ', desc_name, '.mat'];
end

path_file_desc_test = fullfile(basepath,'img',dataset_dir,file_desc_test);

if isfile(path_file_desc_test)
    load(path_file_desc_test);
else
    lasti=1;
    for i = 1:length(data)
         images_descs = get_descriptors_files(data,i,file_ext,desc_name,'test');
         for j = 1:length(images_descs) 
            fname = fullfile(basepath,'img',dataset_dir,images_descs{j});
            fprintf('Loading %s \n',fname);
            tmp = load(fname,'-mat');
            tmp.desc.class=i;
            tmp.desc.imgfname=regexprep(fname,['.' desc_name], dotFile_ext);
            desc_test(lasti)=tmp.desc;
            desc_test(lasti).sift = single(desc_test(lasti).sift);
            lasti=lasti+1;
         end
    end
    
    save(path_file_desc_test,'desc_test');
end