%%%%LLC Coding
if do_svm_llc_linar_classification
    for i=1:length(desc_train)
        disp(desc_train(i).imgfname);
        desc_train(i).llc = max(LLC_coding_appr(VC,desc_train(i).sift)); %max-pooling
        desc_train(i).llc=desc_train(i).llc/norm(desc_train(i).llc); %L2 normalization
    end
    for i=1:length(desc_test) 
        disp(desc_test(i).imgfname);
        desc_test(i).llc = max(LLC_coding_appr(VC,desc_test(i).sift));
        desc_test(i).llc=desc_test(i).llc/norm(desc_test(i).llc);
    end
end
%%%%end LLC coding



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Part 3: image classification %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Concatenate bof-histograms into training and test matrices 
bof_train=cat(1,desc_train.bof);
bof_test=cat(1,desc_test.bof);
if do_svm_llc_linar_classification
    llc_train = cat(1,desc_train.llc);
    llc_test = cat(1,desc_test.llc);
end

% Construct label Concatenate bof-histograms into training and test matrices 
labels_train=cat(1,desc_train.class);
labels_test=cat(1,desc_test.class);


%% NN classification %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_L2_NN_classification
    % Compute L2 distance between BOFs of test and training images

    if testIfTrueValidationIfFalse
        file_bof_l2dist = ['bof_l2dist (test) - ', desc_name, '.mat'];
    else
        file_bof_l2dist = ['bof_l2dist (validation) - ', desc_name, '.mat'];
    end


    path_file_bof_l2dist = fullfile(basepath,'img',dataset_dir,file_bof_l2dist);
    
    if isfile(path_file_bof_l2dist)
        load(path_file_bof_l2dist);
    else
        bof_l2dist=eucliddist(bof_test,bof_train);
        save(path_file_bof_l2dist,'bof_l2dist','-v7.3');
    end   


% Nearest neighbor classification (k-NN) using L2 distance
    [mv,mi] = mink(bof_l2dist,kMax,2);
    bof_l2lab = zeros(size(labels_test));

    
    numTrainImgs = length(labels_train);
    numTestImgs = length(labels_test);
    numClasses = length(classes);

   

    % distance weights
    w = 1 ./ mv .^2;

    method_name='NN L2';

    for k = uint32(1):kMax

        for currTestImg = 1:numTestImgs
            classVotes = zeros(size(classes));
    
            for currTrainImg = 1:k
                currTestImgIdx = mi(currTestImg,currTrainImg);
                currTrainImgClassIdx = labels_train(currTestImgIdx);
    
                classVotes(currTrainImgClassIdx) = ...
                    classVotes(currTrainImgClassIdx) + w(currTestImg,currTrainImg);
            end
            
            [~,maxClassIdx] = max(classVotes);
    
            bof_l2lab(currTestImg) = maxClassIdx;
    
        end

        acc=sum(bof_l2lab==labels_test)/length(labels_test);
        fprintf('*** %s (k = %d) ***\nAccuracy = %1.4f%% (classification)\n',method_name, k, acc*100);
     
        % Compute classification accuracy
        compute_accuracy(data,labels_test,bof_l2lab,classes,method_name,desc_test,...
                          visualize_confmat & have_screen,... 
                          visualize_res & have_screen);
    end
         
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%   EXERCISE 3: Image classification                                      %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                           
%% Repeat Nearest Neighbor image classification using Chi2 distance
% instead of L2. Hint: Chi2 distance between two row-vectors A,B can  
% be computed with d=chi2(A,B);
%
% TODO:
% 3.1 Nearest Neighbor classification with Chi2 distance
%     Compute and compare overall and per-class classification
%     accuracies to the L2 classification above


if do_chi2_NN_classification
    % compute pair-wise CHI2
    bof_chi2dist = zeros(size(bof_test,1),size(bof_train,1));
    
    % bof_chi2dist = slmetric_pw(bof_train, bof_test, 'chisq');


    if testIfTrueValidationIfFalse
        file_bof_chi2dist = ['bof_chi2dist (test) - ', desc_name, '.mat'];
    else
        file_bof_chi2dist = ['bof_chi2dist (validation) - ', desc_name, '.mat'];
    end

    path_file_bof_chi2dist = fullfile(basepath,'img',dataset_dir,file_bof_chi2dist);
    
    if isfile(path_file_bof_chi2dist)
        load(path_file_bof_chi2dist);
    else
        for i = 1:size(bof_test,1)
            for j = 1:size(bof_train,1)
                bof_chi2dist(i,j) = chi2(bof_test(i,:),bof_train(j,:)); 
            end
        end

        save(path_file_bof_chi2dist,'bof_chi2dist','-v7.3');
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RANSAC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if use_ransac
        % Nearest neighbor classification (k-NN) using
        % Chi2 distance + homography + RANSAC
        bestImageIndices = find_best_match(desc_train, desc_test, bof_chi2dist, kRansac);
        bof_chi2lab = labels_train(bestImageIndices);

%%%%%%%%%%%%%%%%%%%%%%%%%% END OF RANSAC PART %%%%%%%%%%%%%%%%%%%%%%%%%%%

    else
        % Nearest neighbor classification (k-NN) using Chi2 distance
        [mv,mi] = mink(bof_chi2dist,kMax,2);
        bof_chi2lab = zeros(size(labels_test));
    
        
        numTrainImgs = length(labels_train);
        numTestImgs = length(labels_test);
        numClasses = length(classes);
    
       
    
        % distance weights
        w = 1 ./ mv .^2;
    
        method_name='NN Chi-2';
    
        for k = uint32(1):kMax
    
            for currTestImg = 1:numTestImgs
                classVotes = zeros(size(classes));
        
                for currTrainImg = 1:k
                    currTestImgIdx = mi(currTestImg,currTrainImg);
                    currTrainImgClassIdx = labels_train(currTestImgIdx);
        
                    classVotes(currTrainImgClassIdx) = ...
                        classVotes(currTrainImgClassIdx) + w(currTestImg,currTrainImg);
                end
                
                [~,maxClassIdx] = max(classVotes);
        
                bof_chi2lab(currTestImg) = maxClassIdx;
        
            end
    
            acc=sum(bof_chi2lab==labels_test)/length(labels_test);
            fprintf('*** %s (k = %d) ***\nAccuracy = %1.4f%% (classification)\n',method_name, k, acc*100);
         
            % Compute classification accuracy
            compute_accuracy(data,labels_test,bof_chi2lab,classes,method_name,desc_test,...
                              visualize_confmat & have_screen,... 
                              visualize_res & have_screen);
        end
         
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   End of EXERCISE 3.1                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% SVM classification (using libsvm) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Use cross-validation to tune parameters:
% - the -v 5 options performs 5-fold cross-validation, this is useful to tune 
% parameters
% - the result of the 5 fold train/test split is averaged and reported
%
% example: for the parameter C (soft margin) use log2space to generate 
%          (say 5) different C values to test
%          xval_acc=svmtrain(labels_train,bof_train,'-t 0 -v 5');


% LINEAR SVM
if do_svm_linar_classification
    
    file_model_linearSVM = ['SVM linear model - ', desc_name, '.mat'];
    path_file_model_linearSVM = fullfile(basepath,'img',dataset_dir,file_model_linearSVM);

    if isfile(path_file_model_linearSVM)
        load(path_file_model_linearSVM);
    else

        % cross-validation
        C_vals=log2space(7,10,5);
        for i=1:length(C_vals);
            opt_string=['-t 0  -v 5 -c ' num2str(C_vals(i))];
            xval_acc(i)=svmtrain(labels_train,bof_train,opt_string);
        end
        %select the best C among C_vals and test your model on the testing set.
        [v,ind]=max(xval_acc);
    
        % train the model and test
        model=svmtrain(labels_train,bof_train,['-t 0 -c ' num2str(C_vals(ind))]);
        
        save(path_file_model_linearSVM,'model','-v7.3');
    end

    
    disp('*** SVM - linear ***');
    svm_lab=svmpredict(labels_test,bof_test,model);
    
    method_name='SVM linear';
    % Compute classification accuracy
    compute_accuracy(data,labels_test,svm_lab,classes,method_name,desc_test,...
                      visualize_confmat & have_screen,... 
                      visualize_res & have_screen);
end

%% LLC LINEAR SVM
if do_svm_llc_linar_classification
    % cross-validation
    C_vals=log2space(7,10,5);
    for i=1:length(C_vals);
        opt_string=['-t 0  -v 5 -c ' num2str(C_vals(i))];
        xval_acc(i)=svmtrain(labels_train,llc_train,opt_string);
    end
    %select the best C among C_vals and test your model on the testing set.
    [v,ind]=max(xval_acc);

    % train the model and test
    model=svmtrain(labels_train,llc_train,['-t 0 -c ' num2str(C_vals(ind))]);
    disp('*** SVM - linear LLC max-pooling ***');
    svm_llc_lab=svmpredict(labels_test,llc_test,model);
    method_name='llc+max-pooling';
    compute_accuracy(data,labels_test,svm_llc_lab,classes,method_name,desc_test,...
                      visualize_confmat & have_screen,... 
                      visualize_res & have_screen);    
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%   EXERCISE 4: Image classification: SVM classifier                      %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pre-computed LINEAR KERNELS. 
% Repeat linear SVM image classification; let's try this with a 
% pre-computed kernel.
%
% TODO:
% 4.1 Compute the kernel matrix (i.e. a matrix of scalar products) and
%     use the LIBSVM precomputed kernel interface.
%     This should produce the same results.


if do_svm_precomp_linear_classification

     file_model_precompLinearSVM = ['SVM precomp. linear model - ', desc_name, '.mat'];
     path_file_model_precompLinearSVM = fullfile(basepath,'img',dataset_dir,file_model_precompLinearSVM);

    if isfile(path_file_model_precompLinearSVM)
        load(path_file_model_precompLinearSVM);
    else

        % compute kernel matrix
        Ktrain = bof_train*bof_train';

        % cross-validation
        C_vals=log2space(7,10,5);
        for i=1:length(C_vals);
            opt_string=['-t 4  -v 5 -c ' num2str(C_vals(i))];
            xval_acc(i)=svmtrain(labels_train,[(1:size(Ktrain,1))' Ktrain],opt_string);
        end
        [v,ind]=max(xval_acc);
        
        % train the model and test
        model=svmtrain(labels_train,[(1:size(Ktrain,1))' Ktrain],['-t 4 -c ' num2str(C_vals(ind))]);
        % we supply the missing scalar product (actually the values of 
        % non-support vectors could be left as zeros.... 
        % consider this if the kernel is computationally inefficient.

        
        save(path_file_model_precompLinearSVM,'model','-v7.3');
    end

    % compute kernel matrix
    Ktest = bof_test*bof_train';
    
    disp('*** SVM - precomputed linear kernel ***');
    precomp_svm_lab=svmpredict(labels_test,[(1:size(Ktest,1))' Ktest],model);
    
    method_name='SVM precomp linear';
    % Compute classification accuracy
    compute_accuracy(data,labels_test,precomp_svm_lab,classes,method_name,desc_test,...
                      visualize_confmat & have_screen,... 
                      visualize_res & have_screen);
    % result is the same??? must be!
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   End of EXERCISE 4.1                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Pre-computed NON-LINAR KERNELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% TODO:
% 4.2 Train the SVM with a precomputed non-linear histogram intersection 
%     kernel and select the best C parameter for the trained model using  
%     cross-validation.
% 4.3 Experiment with other different non-linear kernels: RBF and Chi^2.
%     Chi^2 must be precomputed as in the previous exercise.
% 4.4 Certain kernels have other parameters (e.g. gamma for RBF/Chi^2)... 
%     implement a cross-validation procedure to select the optimal 
%     parameters (as in 3).


%% 4.2: INTERSECTION KERNEL (pre-compute kernel) %%%%%%%%%%%%%%%%%%%%%%%%%%
% try a non-linear svm with the histogram intersection kernel!

if do_svm_inter_classification
    
    file_model_interSVM = ['SVM inters. kernel model - ', desc_name, '.mat'];
    path_file_model_interSVM = fullfile(basepath,'img',dataset_dir,file_model_interSVM);

    if isfile(path_file_model_interSVM)
        load(path_file_model_interSVM);
    else

       Ktrain=zeros(size(bof_train,1),size(bof_train,1));
        for i=1:size(bof_train,1)
            for j=1:size(bof_train,1)
                hists = [bof_train(i,:);bof_train(j,:)];
                Ktrain(i,j)=sum(min(hists));
            end
        end
    
        % cross-validation
        C_vals=log2space(3,10,5);
        for i=1:length(C_vals);
            opt_string=['-t 4  -v 5 -c ' num2str(C_vals(i))];
            xval_acc(i)=svmtrain(labels_train,[(1:size(Ktrain,1))' Ktrain],opt_string);
        end
        [v,ind]=max(xval_acc);
    
        % train the model and test
        model=svmtrain(labels_train,[(1:size(Ktrain,1))' Ktrain],['-t 4 -c ' num2str(C_vals(ind))] );
        % we supply the missing scalar product (actually the values of non-support vectors could be left as zeros.... consider this if the kernel is computationally inefficient.
  
        save(path_file_model_interSVM,'model','-v7.3');
    end

    Ktest=zeros(size(bof_test,1),size(bof_train,1));
        for i=1:size(bof_test,1)
            for j=1:size(bof_train,1)
                hists = [bof_test(i,:);bof_train(j,:)];
                Ktest(i,j)=sum(min(hists));
            end
        end

    
    disp('*** SVM - intersection kernel ***');
    [precomp_ik_svm_lab,conf]=svmpredict(labels_test,[(1:size(Ktest,1))' Ktest],model);

    method_name='SVM IK';
    % Compute classification accuracy
    compute_accuracy(data,labels_test,precomp_ik_svm_lab,classes,method_name,desc_test,...
                      visualize_confmat & have_screen,... 
                      visualize_res & have_screen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   End of EXERCISE 4.2                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% 4.3 & 4.4: CHI-2 KERNEL (pre-compute kernel) %%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_svm_chi2_classification


    file_model_chi2SVM = ['SVM chi-2 kernel model - ', desc_name, '.mat'];
    path_file_model_chi2SVM = fullfile(basepath,'img',dataset_dir,file_model_chi2SVM);

    if isfile(path_file_model_chi2SVM)
        load(path_file_model_chi2SVM);
    else

        % compute kernel matrix
        Ktrain = kernel_expchi2(bof_train,bof_train);
        
        
        % cross-validation
        C_vals=log2space(2,10,5);
        for i=1:length(C_vals);
            opt_string=['-t 4  -v 5 -c ' num2str(C_vals(i))];
            xval_acc(i)=svmtrain(labels_train,[(1:size(Ktrain,1))' Ktrain],opt_string);
        end
        [v,ind]=max(xval_acc);
    
        % train the model and test
        model=svmtrain(labels_train,[(1:size(Ktrain,1))' Ktrain],['-t 4 -c ' num2str(C_vals(ind))] );
        % we supply the missing scalar product (actually the values of non-support vectors could be left as zeros.... 
        % consider this if the kernel is computationally inefficient.
  
        save(path_file_model_chi2SVM,'model','-v7.3');
    end


    Ktest = kernel_expchi2(bof_test,bof_train);
   
    disp('*** SVM - Chi2 kernel ***');
    [precomp_chi2_svm_lab,conf]=svmpredict(labels_test,[(1:size(Ktest,1))' Ktest],model);
    
    method_name='SVM Chi2';
    % Compute classification accuracy
    compute_accuracy(data,labels_test,precomp_chi2_svm_lab,classes,method_name,desc_test,...
                      visualize_confmat & have_screen,... 
                      visualize_res & have_screen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   End of EXERCISE 4.3 and 4.4                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

