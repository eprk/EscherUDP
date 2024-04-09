function [l, k] = BlackWhite2LumiContrast( b, w)

% Obtain mean luminance l and a contrast value k given the low and high
% luminance values, respectively b and w. k is in the range 0-100 (%).

% 1) Definition of Michelson contrast:
k = (w-b)./(w+b) * 100;

% 2) Definition of mean luminance:
l = (w+b)./2;