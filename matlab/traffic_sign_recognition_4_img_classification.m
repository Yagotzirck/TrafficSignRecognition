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
    bof_l2dist=eucliddist(bof_test,bof_train);
    
    % Nearest neighbor classification (1-NN) using L2 distance
    [mv,mi] = min(bof_l2dist,[],2);
    bof_l2lab = labels_train(mi);
    
    method_name='NN L2';
    acc=sum(bof_l2lab==labels_test)/length(labels_test);
    fprintf('\n*** %s ***\nAccuracy = %1.4f%% (classification)\n',method_name,acc*100);
   
    % Compute classification accuracy
    compute_accuracy(data,labels_test,bof_l2lab,classes,method_name,desc_test,...
                      visualize_confmat & have_screen,... 
                      visualize_res & have_screen);
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
    for i = 1:size(bof_test,1)
        for j = 1:size(bof_train,1)
            bof_chi2dist(i,j) = chi2(bof_test(i,:),bof_train(j,:)); 
        end
    end

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RANSAC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if use_ransac
    % Nearest neighbor classification (k-NN) using
    % Chi2 distance + homography + RANSAC

    k = 20; % Numero di immagini più simili da considerare

    bestImageIndices = find_best_match(desc_train, desc_test, bof_chi2dist, k);

    bof_chi2lab = labels_train(bestImageIndices);



%%%%%%%%%%%%%%%%%%%%%%%%%% END OF RANSAC PART %%%%%%%%%%%%%%%%%%%%%%%%%%%

else
    % Nearest neighbor classification (1-NN) using Chi2 distance
    [mv,mi] = min(bof_chi2dist,[],2);
    bof_chi2lab = labels_train(mi);
end

    method_name='NN Chi-2';

    
    acc=sum(bof_chi2lab==labels_test)/length(labels_test);
    fprintf('*** %s ***\nAccuracy = %1.4f%% (classification)\n',method_name,acc*100);
 
    % Compute classification accuracy
    compute_accuracy(data,labels_test,bof_chi2lab,classes,method_name,desc_test,...
                      visualize_confmat & have_screen,... 
                      visualize_res & have_screen);
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
    % compute kernel matrix
    Ktrain = bof_train*bof_train';
    Ktest = bof_test*bof_train';

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
    Ktrain=zeros(size(bof_train,1),size(bof_train,1));
    for i=1:size(bof_train,1)
        for j=1:size(bof_train,1)
            hists = [bof_train(i,:);bof_train(j,:)];
            Ktrain(i,j)=sum(min(hists));
        end
    end

    Ktest=zeros(size(bof_test,1),size(bof_train,1));
    for i=1:size(bof_test,1)
        for j=1:size(bof_train,1)
            hists = [bof_test(i,:);bof_train(j,:)];
            Ktest(i,j)=sum(min(hists));
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
    % compute kernel matrix
    Ktrain = kernel_expchi2(bof_train,bof_train);
    Ktest = kernel_expchi2(bof_test,bof_train);
    
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
