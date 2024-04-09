function [b,w,l,k,b_escher,w_escher,l_escher] = FixLumiValues(b,w,depth,transferFunction)

% Fix the values of low and high luminance values, respectively b and w
% (for "black" and "white"), and update contrast k and mean luminance l.
% Luminance values are in the 0-1 range used by Escher,
% Depth is the maximum pixel value of the current screen (e.g for 8-bit
% screens it is 255). 

% transferFunction (optional) is the screen calibration function, from
% Escher input values (0-1 range) to luminance values (cd/m2). If it's
% empty or if the function is called without that argument, this function
% only checks that b and w are withing [0,1]. Otherwise, 'transferFunction'
% must be a string specifying for an anonymous function. 

if nargin <4
    transferFunction = [];    
end

if isempty(transferFunction)
    % non-calibrated mode.
    
    % First, contrain b and w between 0 and 1
    b = max(b,0);
    w = min(w,1);
    
    % Then, compute mean and contrast
    l = (w+b)/2;
    k = (w-b)/(w+b)*100;
    
    % in this mode return the same values for each parameter and the
    % respective uncalibrated one.
    b_escher=b;
    w_escher=w;
    l_escher=l;
else
    % calibrated mode.
    
    % Fix luminance values to the closest available value.
    [b_escher,b] = Lumi2Escher(b,depth,transferFunction);
    [w_escher,w] = Lumi2Escher(w,depth,transferFunction);
    
    % Recompute mean luminance and contrast accordingly.
    l_optimal = (w+b)/2;
    [l_escher, l] = Lumi2Escher(l_optimal,depth,transferFunction);
    k = (w-b)/(w+b)*100;
    
    % if the actual mean luminance differs from the theoretical value more
    % than 10%, display a warning message
    if abs(l-l_optimal)/l_optimal > 0.1
        warning('off','backtrace')
        warning("The difference between actual and theoretical mean luminance "+...
            "is >10%%. \n\t-Mean of black and white luminance: %.3f cd/m2."+...
            "\n\t-Actual mean luminance: %.3f cd/m2.\n", l_optimal, l)
        warning('on','backtrace')
    end
end
disp("Luminance values updated!")   
