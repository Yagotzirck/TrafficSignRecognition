
% This function takes the SIFT features and their x/y coordinates belonging
%   to two images, and returns the list of matching points.
%   A match is accepted only if its distance is less than distRatio
%   times the distance to the second closest match.


% function [puntosMatch,im1,im2] = match(umbral,representaImagen, image1, image2)
function matchingPts = match_sift_pts(des1, des2, loc1, loc2, distRatio)

%   des1 =          SIFT descriptors for image 1
%   des2 =          SIFT descriptors for image 2
%   loc1 =          x/y coordinates for image 1's SIFT descriptors
%   loc2 =          x/y coordinates for image 2's SIFT descriptors
%   distRatio =     threshold (see the code below for details)


% For efficiency in Matlab, it is cheaper to compute dot products between
%  unit vectors rather than Euclidean distances.  Note that the ratio of 
%  angles (acos of dot products of unit vectors) is a close approximation
%  to the ratio of Euclidean distances for small angles.
%
% distRatio: Only keep matches in which the ratio of vector angles from the
%   nearest to second nearest neighbor is less than distRatio.
%distRatio = umbral;   

% For each descriptor in the first image, select its match to second image.
match = zeros(size(des1,1), 1);     % match array pre-allocation

des2t = des2';                          % Precompute matrix transpose
for i = 1 : size(des1,1)
   dotprods = des1(i,:) * des2t;        % Computes vector of dot products
   [vals,indx] = sort(acos(dotprods));  % Take inverse cosine and sort results

   % Check if nearest neighbor has angle less than distRatio times 2nd.
   if size(vals,2) >= 2 && vals(1) < distRatio * vals(2)
      match(i) = indx(1);
%    else
%       match(i) = 0;
   end
end


%GENERA LA MATRIZ DE RESULTADOS
%Por filas los puntos casados
%Por columnas (x,y) primera imagen, (x,y) segunda imagen

%Numero de puntos casados
num = sum(match > 0);
matchingPts=zeros(num,4);
indice=1;

%Bucle para cada caracteristica encontrada
for i = 1: size(des1,1)
    %Caracteristica casada
    if (match(i) > 0)
        matchingPts(indice,1)=loc1(i,1);
        matchingPts(indice,2)=loc1(i,2);
        matchingPts(indice,3)=loc2(match(i),1);
        matchingPts(indice,4)=loc2(match(i),2);
        indice=indice+1;
    end
end