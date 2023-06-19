function extract_sift_features(dirname, file_ext, img_ext)

% e.g. Caltech-101
% dirname = '../img/101_ObjectCategories';
% file_ext = 'sift';

%dirname = ['..' dirname '/'];

d = dir(dirname);
d = d(3:end); %remove . and .. 

% Get a logical vector that tells which is a directory.
dirFlags = [d.isdir];
% Extract only those that are directories.
d = d(dirFlags); % A structure with extra info.


for i=1:length(d)
    if strcmp(file_ext,'dsift')
        % DENSE SIFT
        scales = [32];
        detect_features_dsift(fullfile(dirname,d(i).name),file_ext,img_ext,scales);
    elseif strcmp(file_ext,'msdsift')
        % MULTI-SCALE DENSE SIFT
        scales = [16 24 32 48];
        detect_features_dsift(fullfile(dirname,d(i).name),file_ext,img_ext,scales);
    elseif strcmp(file_ext,'sift') || strcmp(file_ext,'csift')
        % SPARSE SIFT or SPARSE COLOR SIFT
        detect_features(fullfile(dirname,d(i).name),file_ext,img_ext);
    end
end

end