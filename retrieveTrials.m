%function [outMat, tstamps] = retrieveTrials(mat,info)
function outMat = retrieveTrials(mat,info)
% This function organizes a time series of images (x*y*time) into trials,
% producing a matrix in the form (x*y*trial*time). It also rearranges the
% timestamps vector in the form (trials*time).

% % check the total number of frames.
% len = size(mat,3);
% if len ~= info.nFr
%     error('The frame number does not match with the stimulus info')
% end

nTr = info.nTrials;
fpt = info.FramesPerTrial;

newSize = [size(mat,1), size(mat,2), fpt, nTr];
outMat = permute(reshape(mat, newSize),[1,2,4,3]);
% tstamps = reshape(info.timestamps,[nTr,fpt])';
end