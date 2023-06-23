if crop_imgs
    crop_traffic_signs( fullfile(basepath, 'img', dataset_dir), file_ext );
end

if resize_cropped_imgs
    resize_traffic_signs( fullfile(basepath, 'img', dataset_dir), file_ext );
end

% Load the dataset split, or create a new one if it wasn't created already
file_split = 'split.mat';
path_file_split = fullfile(basepath,'img',dataset_dir,file_split);

if isfile(path_file_split)
    load(path_file_split);
else
    data = create_trafficSigns_dataset_split_structure( ...
        fullfile(basepath, 'img', dataset_dir), ...
        trainPerc,validationPerc,testPerc,use_resized_imgs, use_cropped_imgs);
    
    save(path_file_split,'data');
end

classes = {data.classname}; % create cell array of class name strings

if testIfTrueValidationIfFalse
    [data.test_id] = deal(data.test_id_saved);
else
    [data.test_id] = deal(data.validation_id_saved);
end

clear path_file_split;