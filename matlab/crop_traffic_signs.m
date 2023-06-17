function crop_traffic_signs(datasetDir, file_ext)
%CROP_TRAFFIC_SIGNS Use the enclosing boxes defined in the csv files
%included with the traffic signs' dataset to crop the images.


fprintf('Cropping images...')

croppedDirs_prefix = 'cropped';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Create directories which will contain the cropped images %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mkdir(datasetDir, strcat(croppedDirs_prefix, 'Test') );
mkdir(datasetDir, strcat(croppedDirs_prefix, 'Train') );

% Classes are named/numbered in the range 0-42, and there's one folder
% per class in the "Train/" subfolder
for i = 0:42
    mkdir(datasetDir, ...
          fullfile( strcat(croppedDirs_prefix, 'Train'), num2str(i) ) ...
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
    srcFile = fullfile(datasetDir, char(imgsInfo.Path(i)))
    destFile = fullfile(datasetDir, [croppedDirs_prefix, char(imgsInfo.Path(i)) ]);

    if exist(destFile, 'file')
            fprintf('File exists! Skipping %s \n',destFile);
            continue;
    end

    imgSrc = imread(srcFile);

    imgCropped = imcrop(imgSrc, ...
                     [imgsInfo.Roi_X1(i), ...
                      imgsInfo.Roi_Y1(i), ...
                      imgsInfo.Roi_X2(i) - imgsInfo.Roi_X1(i), ...
                      imgsInfo.Roi_Y2(i) - imgsInfo.Roi_Y1(i) ...
                     ]);

    

    imwrite(imgCropped, destFile, file_ext);
end

