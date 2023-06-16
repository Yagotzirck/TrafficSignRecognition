clear;
close all;

% DATASET
dataset_dir = 'TrafficSigns';

desc_name = 'csift';

% FLAGS
do_feat_extraction = 1;
do_split_sets = 1;


do_form_codebook = 1;
do_feat_quantization = 1;

do_L2_NN_classification = 0;
do_chi2_NN_classification = 1;
do_svm_linar_classification = 0;
do_svm_llc_linar_classification = 0;
do_svm_precomp_linear_classification = 0;
do_svm_inter_classification = 0;
do_svm_chi2_classification = 0;

visualize_feat = 0;
visualize_words = 0;
visualize_confmat = 0;
visualize_res = 0;
have_screen = ~isempty(getenv('DISPLAY'));

% PATHS
basepath = '..';
wdir = pwd;
libsvmpath = [ wdir(1:end-6) fullfile('lib','libsvm-3.11','matlab')];
addpath(libsvmpath)

datasetPath = strcat(basepath, '/', dataset_dir, '/');

% BOW PARAMETERS
max_km_iters = 50; % maximum number of iterations for k-means
nfeat_codebook = 60000; % number of descriptors used by k-means for the codebook generation
norm_bof_hist = 1;

% RANSAC PARAMETERS
ransac_threshold = 0.5; % RANSAC inlier threshold
ransac_num_iterations = 1000; % RANSAC maximum number of iterations

% number of images selected for training (e.g. 30 for Caltech-101)
num_train_img = 210;
% number of images selected for test (e.g. 50 for Caltech-101)
num_test_img = 50;

% image file extension
%file_ext='jpg';
file_ext = 'png';
dotFile_ext = strcat('.', file_ext);

% Create a new dataset split
file_split = 'split.mat';
if do_split_sets    
    data = create_trafficSigns_dataset_split_structure( ...
        fullfile(basepath, 'img', dataset_dir), ...
        num_train_img,num_test_img,file_ext);
    save(fullfile(basepath,'img',dataset_dir,file_split),'data');
else
    load(fullfile(basepath,'img',dataset_dir,file_split));
end
classes = {data.classname}; % create cell array of class name strings

% Carica le feature SIFT precedentemente calcolate
desc_train = struct('sift', {}, 'class', {}, 'imgfname', {});
lasti = 0;
for i = 1:length(data)
    images_descs = get_descriptors_files(data, i, file_ext, desc_name, 'train');
    for j = 1:length(images_descs) 
        fname = fullfile(basepath, 'img', dataset_dir, images_descs{j});
        fprintf('Loading %s \n', fname);
        tmp = load(fname, '-mat');
        tmp.desc.class = i;
        tmp.desc.imgfname = regexprep(fname, ['.' desc_name], dotFile_ext);
        
        % Perform RANSAC on csift descriptors
        if strcmp(desc_name, 'csift')
            num_points = size(tmp.desc.sift, 1);
            if num_points >= 2
                [ransac_desc, inliers] = ransac_csift(tmp.desc.sift, ransac_threshold, ransac_num_iterations);
                tmp.desc.sift = single(ransac_desc);
            end
        end
        
        lasti = lasti + 1;
        desc_train(lasti).sift = single(tmp.desc.sift);
        desc_train(lasti).class = tmp.desc.class;
        desc_train(lasti).imgfname = tmp.desc.imgfname;
    end;
end;

% BOW PARAMETERS
num_descriptors = numel(desc_train);
nwords_codebook = 500; % Update the value of nwords_codebook
if nwords_codebook > num_descriptors
    nwords_codebook = num_descriptors;
    fprintf('Reducing the number of codewords to %d\n', nwords_codebook);
end

function [ransac_desc, inliers] = ransac_csift(sift_desc, threshold, num_iterations)
    % RANSAC for csift descriptors
    
    num_points = size(sift_desc, 1);
    best_inliers = [];
    best_num_inliers = 0;
    
    if num_points < 2
        ransac_desc = sift_desc;
        inliers = [];
        return;
    end
    
    for i = 1:num_iterations
        % Randomly select two points
        rand_indices = randperm(num_points, 2);
        pt1 = sift_desc(rand_indices(1), :);
        pt2 = sift_desc(rand_indices(2), :);
        
        % Compute distance between points
        distances = sqrt(sum((sift_desc - pt1).^2, 2));
        
        % Count inliers within threshold distance
        inlier_indices = find(distances < threshold);
        num_inliers = length(inlier_indices);
        
        % Update best inliers
        if num_inliers > best_num_inliers
            best_num_inliers = num_inliers;
            best_inliers = inlier_indices;
        end
    end
    
    % Extract RANSAC inliers
    ransac_desc = sift_desc(best_inliers, :);
    inliers = best_inliers;
end
