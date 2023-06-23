if crop_imgs
    crop_traffic_signs( fullfile(basepath, 'img', dataset_dir), file_ext );
end

if resize_cropped_imgs
    resize_traffic_signs( fullfile(basepath, 'img', dataset_dir), file_ext );
end

% Create a new dataset split
file_split = 'split.mat';
if do_split_sets    
    data = create_trafficSigns_dataset_split_structure( ...
        fullfile(basepath, 'img', dataset_dir), ...
        trainPerc,validationPerc,testPerc,use_resized_imgs, use_cropped_imgs);
    save(fullfile(basepath,'img',dataset_dir,file_split),'data');
else
    load(fullfile(basepath,'img',dataset_dir,file_split));
end
classes = {data.classname}; % create cell array of class name strings

if testIfTrueValidationIfFalse
    [data.test_id] = deal(data.test_id_saved);
else
    [data.test_id] = deal(data.validation_id_saved);
end