% DATASET
dataset_dir = 'TrafficSigns';
%dataset_dir='4_ObjectCategories';
%dataset_dir = '15_ObjectCategories';

% FEATURES extraction methods:
%
% 'sift' for sparse features detection (SIFT descriptors computed at  
% Harris-Laplace keypoints)
% 
% 'csift' for sparse features detection, taking into account color as well
% and not just brightness (basically the same as 'sift', but computing it 3
% times for the red, blue and green channels and concatenating the results)

% 'dsift' for dense features detection (SIFT
% descriptors computed at a grid of overlapped patches)

desc_name = 'sift';
%desc_name = 'csift';
%desc_name = 'dsift';
%desc_name = 'cdsift';
%desc_name = 'msdsift';

% FLAGS
do_feat_extraction = 0;
%do_split_sets = 0;

% reload_sift = ...
%     do_feat_extraction == 1 || ...
%     do_split_sets == 1      || ...
%     not(evalin( 'base', 'exist(''desc_train'',''var'') == 1'));


% If true, use the boxes enclosing the traffic signs defined in the
% datasets's csv files to crop the images
crop_imgs = 0;


% If true, resize the cropped images all to the same width and height
% (defined as parameters inside resize_traffic_signs.m).
resize_cropped_imgs = 0;


% If true, use the cropped images
use_cropped_imgs = 0;

% If true, use the resized cropped images (overrides use_cropped_imgs if true)
use_resized_imgs = 1;


%%%%%%%%%%%%%%%%%%%%%% NEAREST NEIGHBORS SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%

% The upper limit for the neighbors to test; that is, the algorithm checks
% all accuracy results for all k values in the range 1-kMax
kMax = uint32(50);

kRansac = 5; % Numero di immagini più simili da considerare per RANSAC


% If true, use RANSAC-kNN for NN-Chi2; if false, use 1NN-Chi2
use_ransac = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

testIfTrueValidationIfFalse = false;

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
visualize_confmat = 1;
visualize_res = 0;
% have_screen = ~isempty(getenv('DISPLAY'));
have_screen = 1;

% PATHS
basepath = '..';
wdir = pwd;
libsvmpath = [ wdir(1:end-6) fullfile('lib','libsvm-3.11','matlab')];
addpath(libsvmpath)


% BOW PARAMETERS
max_km_iters = 50; % maximum number of iterations for k-means
nfeat_codebook = 60000; % number of descriptors used by k-means for the codebook generation
norm_bof_hist = 1;


% Percentage of images selected for training
trainPerc = .6;
% Percentage of images selected for validation
validationPerc = .2;
% Percentage of images selected for test
testPerc = .2;

% number of codewords (i.e. K for the k-means algorithm)
nwords_codebook = 500;

% image file extension
%file_ext='jpg';
file_ext = 'png';
dotFile_ext = strcat('.', file_ext);