function data = create_trafficSigns_dataset_split_structure(main_dir,percTrain,percValidation,percTest,use_resized_imgs, use_cropped_imgs)
%CREATE_TRAFFICSIGNS_DATASET_SPLIT_STRUCTURE Function
%create_dataset_split_structure(), readapted to deal with the traffic signs
%dataset.
%   Detailed explanation goes here


    trainData =	readtable( strcat(main_dir,    '/Train.csv') );
    testData =	readtable( strcat(main_dir,    '/Test.csv' ) );
    
%   totalNumTrainImgs = height(trainData);
%   totalNumTestImgs  = height(testData);

    if percTrain + percValidation + percTest > 1
        error('The sum of split sets' percentages must not exceed 1!');
    end

    minResolution = [0 0];

    % Keep only the images satisfying the minResolution requirement
    trainData = trainData(check_resolution(trainData, minResolution),:);
    testData = testData(check_resolution(testData, minResolution),:);

    numClasses = max(trainData.('ClassId')) + 1;
    
    idx = 1;

    for c = 1:numClasses
        currClassTrainImgs = trainData( trainData.ClassId == (c-1), : );
        currClassTestImgs  = testData( testData.ClassId == (c-1), : );

        currClassImgs = [currClassTrainImgs; currClassTestImgs];

%         numCurrTrainImgs = height(currClassTrainImgs);
%         numCurrTestImgs = height(currClassTestImgs);
        numCurrClassImgs = height(currClassImgs);

%         if numCurrTrainImgs < Ntrain || numCurrTestImgs < Ntest
%             continue;
%         end



        currNtrain = floor(percTrain * numCurrClassImgs);
        currNValidation = floor(percValidation * numCurrClassImgs);
        currNtest  = floor(percTest * numCurrClassImgs);

        currUsedClassImgs = currNtrain + currNValidation + currNtest;

        ids = randperm(currUsedClassImgs);

        data(idx).n_images = currUsedClassImgs;
        data(idx).classname = int2str(c-1);
        data(idx).files = currClassImgs.('Path')';
        
        data(idx).train_id = false(1,currUsedClassImgs);
        data(idx).train_id(ids(1:currNtrain))=true;

        data(idx).validation_id_saved = false(1,currUsedClassImgs);
        data(idx).validation_id_saved(ids(currNtrain+1:currNtrain + currNValidation))=true;

        data(idx).test_id_saved = false(1,currUsedClassImgs);
        data(idx).test_id_saved(ids(currNtrain + currNValidation + 1:currUsedClassImgs))=true;

        idx = idx + 1;
    end

    idx = idx-1;

    if use_resized_imgs
        for i = 1:idx
            data(i).files(data(i).train_id) = strcat('resized', data(i).files(data(i).train_id));
            data(i).files(data(i).validation_id_saved) = strcat('resized', data(i).files(data(i).validation_id_saved));
            data(i).files(data(i).test_id_saved) = strcat('resized', data(i).files(data(i).test_id_saved));
        end
    elseif use_cropped_imgs
        for i = 1:idx
            data(i).files(data(i).train_id) = strcat('cropped', data(i).files(data(i).train_id));
            data(i).files(data(i).validation_id_saved) = strcat('cropped', data(i).files(data(i).validation_id_saved));
            data(i).files(data(i).test_id_saved) = strcat('cropped', data(i).files(data(i).test_id_saved));
        end
    end

end


function results = check_resolution(table, minResolution)
    resolutions = [table.Roi_X2 - table.Roi_X1, table.Roi_Y2 - table.Roi_Y1];

    results = resolutions(:,1) >= minResolution(1) & resolutions(:,2) >= minResolution(2);
end