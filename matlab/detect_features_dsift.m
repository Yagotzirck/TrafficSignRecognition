% function [] = detect_features_dsift(im_dir);
%
% Detect and describe features for all images in a directory 
%
% IN:   im_dir    ... directory of images
%       file_ext  ... a string (e.g. 'sift')       
%
% OUT:  for each image, a matlab file *.file_ext is created in directory 
%       im_dir, SIFT descriptors.
%
% The output Matlab file contains structure "desc" with fileds:
%
%  desc.r    ... row index of each feature
%  desc.c    ... column index of each feature
%  desc.rad  ... radius (scale) of each feature
%  desc.sift ... SIFT descriptor for each feature
%
%

function detect_features_dsift(im_dir,file_ext,img_ext,varargin)
    
    stride = 6;
    do_resizeimage = 0;
    
    dd = dir(fullfile(im_dir, strcat('*.', img_ext)));
    if nargin < 4 
        scales = [32];
    else
        scales = cell2mat(varargin(1));
    end

    tmp_img_filename = strcat('_tmp.', img_ext);

    parfor i = 1:length(dd)
    %for i = 1:length(dd)
    
        fname = fullfile(im_dir,dd(i).name);
        
        fname_out = [fname(1:end-3),file_ext];
        
        if exist(fname_out,'file')
            fprintf('File exists! Skipping %s \n',fname_out);
            continue;
        end;

        I=imread(fname);

%         try
%             I=imread(fname);
%         catch
%             i = 0; % DEBUG FOR SETTING A BREAKPOINT HERE; REMOVE LATER
%         end

        %resize the max dimension down to 300
        if do_resizeimage
            I = rescale_max_size(I, 300, 1);
            tmp_img = fullfile(im_dir,dd(i).name);
            tmp_img = [tmp_img(1:end-4), tmp_img_filename];
            %tmp_img = [tmp_img(1:end-4),'.jpg'];
            %imwrite(I, tmp_img, 'jpg', 'quality', 90);
        end
        
        fprintf('Detecting and describing features: %s \n',fname_out);

        fname_txt = [fname(1:end-3) 'txt' ];
       
        % scale
        %scales = [16 24 32 48];

        sift_cell = cell(1,length(scales));
        curr_rad = cell(1,length(scales));

        if strcmp(file_ext, 'dsift')

            I = double(I);
            I = mean(I,3);
            I = I /max(I(:));
    
            
            for psize=1:length(scales)
                [sift_tmp,gx{psize},gy{psize}]=sp_dense_sift(I,stride,scales(psize));
                sift_cell{psize}=reshape(sift_tmp,[size(sift_tmp,1)*size(sift_tmp,2) size(sift_tmp,3)]);
                curr_rad{psize} = scales(psize)*ones(1,size(sift_cell{psize},1))';
            end
            sift = cell2mat(sift_cell');
    
            rad = cell2mat(curr_rad');
            [gx] = cellfun(@(C)(C(:)),gx,'UniformOutput',false); %make each grid  of coordinates in the cell a vector
            c = cell2mat(gx'); % generate vector of coordinates
            
            [gy] = cellfun(@(C)(C(:)),gy,'UniformOutput',false); %make each grid of coordinates in the cell a vector
            r = cell2mat(gy');  % generate vector of coordinates
        
        elseif strcmp(file_ext, 'cdsift')

            sift =      [];     % SIFT descriptors
            r =         [];     % Rows
            c =         [];     % Columns
            rad =       [];     % Radiuses
    
            for currColorChannel = 1:ndims(I)  % ndims(Im) should normally be 3: red, green, blue
                imgCurrChannel = im2double( I(:,:,currColorChannel) );

                for psize=1:length(scales)
                    [sift_tmp,gx{psize},gy{psize}]=sp_dense_sift(imgCurrChannel,stride,scales(psize));
                    sift_cell{psize}=reshape(sift_tmp,[size(sift_tmp,1)*size(sift_tmp,2) size(sift_tmp,3)]);
                    curr_rad{psize} = scales(psize)*ones(1,size(sift_cell{psize},1))';
                end
                sift = [sift; cell2mat(sift_cell')];
        
                rad = [rad; cell2mat(curr_rad')];
                [gx] = cellfun(@(C)(C(:)),gx,'UniformOutput',false); %make each grid  of coordinates in the cell a vector
                c = [c; cell2mat(gx')]; % generate vector of coordinates
                
                [gy] = cellfun(@(C)(C(:)),gy,'UniformOutput',false); %make each grid of coordinates in the cell a vector
                r = [r; cell2mat(gy')];  % generate vector of coordinates
            end

        end

        
        desc = struct('sift',uint8(512*sift),'r',r,'c',c,'rad',rad);

        iSave(desc,fname_out);

        %clear rad; % Otherwise it stays for the next loop iteration, if we use "for" instead of "parfor"
    end

end


function iSave(desc,fName)
    save(fName,'desc');
end

