function bestImageIndices = find_best_match(desc_train, desc_test, bof_chi2dist, k)
%COUNT_INLIERS Returns a list of matching training images' indices for each test image.

%   Given two descriptor lists for training and test images, for each test
%   image T we compare T with the k closest training images (where the distance
%   has been previously calculated using chi-square on the BoW
%   descriptors) by performing homography + RANSAC between T and each of
%   the k closest images; the training image having the most inliers in
%   common with the test image T becomes the new "best match".



[~,mi] = mink(bof_chi2dist, k, 2);

numTestImgs = size(mi,1);

    
bestImageIndices = zeros(numTestImgs, 1); % Inizializza l'array per salvare l'indice migliore

for i = 1:numTestImgs
    % Get the SIFT descriptors for the current test image and normalize them
    currTestImgSIFTs = desc_test(i).sift;
    currTestImgSIFTs = currTestImgSIFTs ./ vecnorm(currTestImgSIFTs);

    % Get the x/y coordinates for the current test image's SIFT points
    currTestImgSIFTsCoords = [desc_test(i).c, desc_test(i).r];


    % Seleziona le k immagini di training più vicine all'immagine di test corrente
    trainImgIndices = mi(i,:);
    
    % Esegui l'algoritmo RANSAC per trovare la migliore immagine
    bestInliersCount = 0;
    bestImageIndex = mi(i,1);   % By default, we take the closest image reported by BoW Chi-2
    
    for j = 1:k
        % Seleziona l'immagine corrente dalla lista delle k immagini più simili
        currTrainIdx = trainImgIndices(j);
        
        % Get the SIFT descriptors for the current training image and normalize them
        currTrainImgSIFTs = desc_train(currTrainIdx).sift;
        currTrainImgSIFTs = currTrainImgSIFTs ./ vecnorm(currTrainImgSIFTs);

        % Get the x/y coordinates for the current test image's SIFT points
        currTrainImgSIFTsCoords = [desc_train(currTrainIdx).c, desc_train(currTrainIdx).r];

        % Find the matching SIFT points between the current train and test
        % images
        matchingPts = match_sift_pts( ...
            currTestImgSIFTs, currTrainImgSIFTs, ...
            currTestImgSIFTsCoords, currTrainImgSIFTsCoords, 0.6);

        if(size(matchingPts,1) >= 4)

            trainMatchingPts =  matchingPts(:,1:2)';
            testMatchingPts =   matchingPts(:,3:4)';

            % Normalize x and y relatively to width and height
            
        
            [~, inliers] = ransacfithomography( ...
                matchingPts(:,1:2)', matchingPts(:,3:4)', 0.005);
    
            currInliersCnt = size(inliers,1);
        else
            currInliersCnt = 0;
        end


        
            
        % Aggiorna se necessario il numero di inliers e l'immagine migliore
        if currInliersCnt > bestInliersCount
            bestInliersCount = currInliersCnt;
            bestImageIndex = currTrainIdx;
        end
    end

    % Salva l'immagine migliore ottenuta da RANSAC
    bestImageIndices(i) = bestImageIndex;
end
     
end
