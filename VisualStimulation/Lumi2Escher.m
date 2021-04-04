function [escherValue,TrueLumiValue] = Lumi2Escher(lumiValue,whiteValue,formulaTxt)
% First of all, we need the gamma correction function of the screen
    screenFunc = str2func(formulaTxt);
% Let's generate a vector of all possible values of escher, considering 
% that psychtoolbox can only receive integer values that are in the range 
% 0-app.white. Usually the range is 0-255 but let's be cautious.
% AllEscherX is a vector whose values go from a minimum 0 to a maximum of
% 1. The number of values is determined by app.white.
    allEscherX = (((1:whiteValue+1)-1)/whiteValue)';
% Now we generate a vector of all possible luminances that can be generated
% by Escher through psychtoolbox, by using the screen calibration function.
    allLumiY = screenFunc(allEscherX);
% We look for the index of the value on the allLumiY vector that is close 
% to "lumivalue" (our input).
    tmpValue = abs(allLumiY-lumiValue);
    [~,Idx] = min(tmpValue,[],1);
% Now we use that index to find the value on allEscherX: that is the value 
% that we want as Escher input!
    escherValue = allEscherX(Idx);
% Also the true luminance value is returned.
    TrueLumiValue = allLumiY(Idx);
end
