function data = create_trafficSigns_dataset_split_structure(main_dir,Ntrain,Ntest,use_resized_imgs, use_cropped_imgs)
%CREATE_TRAFFICSIGNS_DATASET_SPLIT_STRUCTURE Function
%create_dataset_split_structure(), readapted to deal with the traffic signs
%dataset.
%   Detailed explanation goes here


    trainData =	readtable( strcat(main_dir,    '/Train.csv') );
    testData =	readtable( strcat(main_dir,    '/Test.csv' ) );
    
%   totalNumTrainImgs = height(trainData);
%   totalNumTestImgs  = height(testData);


    minResolution = [56 56];

    % Keep only the images satisfying the minResolution requirement
    trainData = trainData(check_resolution(trainData, minResolution),:);
    testData = testData(check_resolution(testData, minResolution),:);

    numClasses = max(trainData.('ClassId')) + 1;
    
    idx = 1;

    for c = 1:numClasses
        currClassTrainImgs = trainData( trainData.ClassId == (c-1), : );
        currClassTestImgs  = testData( testData.ClassId == (c-1), : );

        numCurrTrainImgs = height(currClassTrainImgs);
        numCurrTestImgs = height(currClassTestImgs);

        if numCurrTrainImgs < Ntrain || numCurrTestImgs < Ntest
            continue;
        end


        currNtrain = min(Ntrain, numCurrTrainImgs);
        currNtest  = min(Ntest, numCurrTestImgs);

        ids_train = randperm(numCurrTrainImgs);
        ids_test = randperm(numCurrTestImgs) + numCurrTrainImgs;

        data(idx).n_images = numCurrTrainImgs + numCurrTestImgs;
        data(idx).classname = int2str(c-1);
        data(idx).files = [currClassTrainImgs.('Path')', currClassTestImgs.('Path')'];
        
        data(idx).train_id = false(1,data(idx).n_images);
        data(idx).train_id(ids_train(1:currNtrain))=true;
        
        data(idx).test_id = false(1,data(idx).n_images);
        data(idx).test_id(ids_test(1:currNtest))=true;

        idx = idx + 1;
    end

    idx = idx-1;

    if use_resized_imgs
        for i = 1:idx
            data(i).files(data(i).train_id) = strcat('resized', data(i).files(data(i).train_id));
            data(i).files(data(i).test_id) = strcat('resized', data(i).files(data(i).test_id));
        end
    elseif use_cropped_imgs
        for i = 1:idx
            data(i).files(data(i).train_id) = strcat('cropped', data(i).files(data(i).train_id));
            data(i).files(data(i).test_id) = strcat('cropped', data(i).files(data(i).test_id));
        end
    end

end


function results = check_resolution(table, minResolution)
    resolutions = [table.Roi_X2 - table.Roi_X1, table.Roi_Y2 - table.Roi_Y1];

    results = resolutions(:,1) >= minResolution(1) & resolutions(:,2) >= minResolution(2);
end