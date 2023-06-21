function resize_traffic_signs(datasetDir, file_ext)
%CROP_TRAFFIC_SIGNS Resize the cropped traffic signs all to the same
%resolution.

fprintf('Resizing images...')

croppedDirs_prefix = 'cropped';
resizedDirs_prefix = 'resized';

resizedWidth =  48;
resizedHeight = 48;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Create directories which will contain the resized images %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mkdir(datasetDir, strcat(resizedDirs_prefix, 'Test') );
mkdir(datasetDir, strcat(resizedDirs_prefix, 'Train') );

% Classes are named/numbered in the range 0-42, and there's one folder
% per class in the "Train/" subfolder
for i = 0:42
    mkdir(datasetDir, ...
          fullfile( strcat(resizedDirs_prefix, 'Train'), num2str(i) ) ...
    );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Crop the images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgsInfo = [
        readtable( strcat(datasetDir, '/Train.csv') );
        readtable( strcat(datasetDir, '/Test.csv' ) );
];

numImgs = height(imgsInfo);

parfor i=1:numImgs
    srcFile = fullfile(datasetDir, [croppedDirs_prefix, char(imgsInfo.Path(i)) ]);
    destFile = fullfile(datasetDir, [resizedDirs_prefix, char(imgsInfo.Path(i)) ]);

    if exist(destFile, 'file')
            fprintf('File exists! Skipping %s \n',destFile);
            continue;
    end

    imgSrc = imread(srcFile);
    imgResized = imresize(imgSrc, [resizedHeight, resizedWidth], 'bilinear');
    imwrite(imgResized, destFile, file_ext);
end