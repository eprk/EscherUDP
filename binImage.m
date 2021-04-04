function [binnedImage] = binImage(inputI, bin)
%binImage
% September, 9, 2017 GMR
% This function takes the input image and bins it of the specified square
% amount
% Width ad Height of the input image must be integer multiple of the bin
% factor. If this is not true, the image is cropped to the closest
% acceptable couple of values.

[w h] = size(inputI);
total = w*h;

% check size against bin coefficent.
wb = w/bin;
hb = h/bin;

%tmp = reshape(inputI,bin,hb,wb*bin)

temp1 = sum(reshape(inputI,bin,[]),1 );
temp2 = reshape(temp1,wb,[]).';             %Note transpose

temp3 = sum(reshape(temp2,bin,[]),1);
binnedImage = reshape(temp3,hb,[]).';       %Note transpose

end

