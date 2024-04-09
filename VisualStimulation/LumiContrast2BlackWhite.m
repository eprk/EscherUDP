function [b, w] = LumiContrast2BlackWhite(l, k)

% Obtain low and high luminance values, respectively b and w (for "black"
% and "white"), given the % mean luminance l and a contrast value k.
% k is in the range 0-100 (%). % w and b are obtained solving the system
% made of the following equations:
% 1) Definition of Michelson contrast: k = (w-b)/(w+b) * 100%
% 2) Definition of mean luminance: l = (w+b)/2

b = l.*(1-k./100);
w = l.*(1+k./100);


