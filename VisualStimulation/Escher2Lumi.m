function [LumiValues,fixedEscherValues] = Escher2Lumi(escherValues,whiteValue,formulaTxt)

% obtain 0-1 floating values that correspond to integer values divided by
% whiteValue
fixedEscherValues = (round(escherValues.*whiteValue)./whiteValue)';

screenFunc = str2func(formulaTxt);

LumiValues = screenFunc(fixedEscherValues);

end