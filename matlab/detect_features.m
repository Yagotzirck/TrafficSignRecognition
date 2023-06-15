% function [] = detect_features(im_dir);
%
% Detect and describe features for all images in a directory 
%
% IN: im_dir ... directory of images
% OUT: for each image, a matlab file *.desc is created in directory im_dir, 
%      containing detected LoG features described with SIFT descriptors.
%
% The output Matlab file contains structure "desc" with fileds:
%
%  desc.r    ... row index of each feature
%  desc.c    ... column index of each feature
%  desc.rad  ... radius (scale) of each feature
%  desc.sift ... 128d SIFT descriptor for each feature (if file_ext == 'sift')
%  desc.csift ... 384d COLOR SIFT descriptor for each feature (if file_ext == 'csift')
%
% Josef.Sivic@ens.fr
% 7/11/2009
%
% Modified by Lamberto Ballan - 2/9/2013
%
% Further modified by Yagotzirck (color SIFT) - 15/6/2023

function [] = detect_features(im_dir,file_ext,img_ext,show_img)
        
    dd = dir(fullfile(im_dir, strcat('*.', img_ext)));
    if ~exist('show_img','var')
        show_img = false;
    end    

    % detector paramteres
    sigma       = 2;              % initial scale
    k           = sqrt(sqrt(2));  % scale step
    sigma_final = 16;             % final scale
    threshold   = 0.005;          % squared response threshold

    % descriptor parameters
    enlarge_factor = 2; % enlarge the size of the features to make them more distinctive

    parfor i = 1:length(dd)
        %fname = [im_dir,'/',dd(i).name];
        fname = fullfile(im_dir,dd(i).name);

        fname_out = [fname(1:end-3),file_ext];
        if exist(fname_out,'file')
            fprintf('File exists! Skipping %s \n',fname_out);
            continue;
        end;


        fprintf('Detecting and describing features: %s \n',fname_out);
        Im = imread(fname);
        
        if strcmp(file_ext, 'sift')
            Im = mean(double(Im),3)./max(double(Im(:)));

            % compute features (LoG)
            [r, c, rad] = BlobDetector(Im, sigma, k, sigma_final, threshold);
    
            % describe features
            circles = [c r rad];
            sift_arr = find_sift(Im, circles, enlarge_factor);

        elseif strcmp(file_ext, 'csift')
            sift_arr =  [];     % SIFT descriptors
            r =         [];     % Rows
            c =         [];     % Columns
            rad =       [];     % Radiuses

            for currColorChannel = 1:ndims(Im)  % ndims(Im) should normally be 3: red, green, blue
                 % compute features (LoG)
                [curr_r, curr_c, curr_rad] = BlobDetector(Im(:,:,currColorChannel), sigma, k, sigma_final, threshold);
    
                % describe features
                curr_circles = [curr_c curr_r curr_rad];
                curr_sift_arr = find_sift(Im(:,:,currColorChannel), curr_circles, enlarge_factor);

                % Concatenate the current color channel attributes to
                % attributes from previous channels
                sift_arr = [sift_arr; curr_sift_arr];
                r = [r; curr_r];
                c = [c; curr_c];
                rad = [rad; curr_rad];
            end
        end

        % convert to single to save disk space
        desc = struct('sift',uint8(512*sift_arr),'r',r,'c',c,'rad',rad);

        iSave(desc,fname_out);

        if show_img
            d=desc;
            Im = imread(fname);
            figure; clf, showimage(Im);
            x=d.c;
            y=d.r;
            rad=d.rad;
            showcirclefeaturesrad([x,y,rad]);
            pause
        end
    end

end

function iSave(desc,fName)
    save(fName,'desc');
end