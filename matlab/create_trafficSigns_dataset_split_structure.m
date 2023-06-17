function data = create_trafficSigns_dataset_split_structure(main_dir,Ntrain,Ntest,use_cropped_train_imgs)
%CREATE_TRAFFICSIGNS_DATASET_SPLIT_STRUCTURE Function
%create_dataset_split_structure(), readapted to deal with the traffic signs
%dataset.
%   Detailed explanation goes here


    trainData =	readtable( strcat(main_dir,    '/Train.csv') );
    testData =	readtable( strcat(main_dir,    '/Test.csv' ) );
    
%   totalNumTrainImgs = height(trainData);
%   totalNumTestImgs  = height(testData);

    numClasses = max(trainData.('ClassId')) + 1;
    
    for c = 1:numClasses
        currClassTrainImgs = trainData( trainData.ClassId == (c-1), : );
        currClassTestImgs  = testData( testData.ClassId == (c-1), : );

        numCurrTrainImgs = height(currClassTrainImgs);
        numCurrTestImgs = height(currClassTestImgs);

        currNtrain = min(Ntrain, numCurrTrainImgs);
        currNtest  = min(Ntest, numCurrTestImgs);

        ids_train = randperm(numCurrTrainImgs);
        ids_test = randperm(numCurrTestImgs);

        data(c).n_images = numCurrTrainImgs + numCurrTestImgs;
        data(c).classname = int2str(c-1);
        data(c).files = [currClassTrainImgs.('Path')', currClassTestImgs.('Path')'];
        
        data(c).train_id = false(1,data(c).n_images);
        data(c).train_id(ids_train(1:currNtrain))=true;
        
        data(c).test_id = false(1,data(c).n_images);
        data(c).test_id(ids_test(1:currNtest) + currNtrain)=true;
    end

    if use_cropped_train_imgs
        for i = 1:numClasses
            data(i).files(data(i).train_id) = strcat('cropped', data(i).files(data(i).train_id));
        end
    end

end