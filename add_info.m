%% load a file
[fname,fpath] = uigetfile('*.mat');
load([fpath fname]);
%% add info field
%               % nTrials
%               % framesPerTrial
%               % orientation, stim orientation expressed in degrees
%               % direction, stim direction, either '+' or '-'
%               % pxlSize, as a two-elements vector
%               % samplingF, the frame frequency expressed in Hz
%               % stimF, the stimulus frequency
% OutPcoStruct.Images = OutPcoStruct.Images(213:end,213:end,1:840); % passo da 512x512 a 300x300
OutPcoStruct.Images = OutPcoStruct.Images;
% OutPcoStruct.ImgCounter = OutPcoStruct.ImgCounter(1:840);
OutPcoStruct.ImgCounter = OutPcoStruct.ImgCounter;
% OutPcoStruct.Timestamps = OutPcoStruct.Timestamps(1:840);
OutPcoStruct.Timestamps = OutPcoStruct.Timestamps;
% OutPcoStruct.TimestampsTxt = OutPcoStruct.TimestampsTxt(1:840);
OutPcoStruct.TimestampsTxt = OutPcoStruct.TimestampsTxt;


OutPcoStruct.Info.nTrials = 75; % passo da 80 trial a 30
OutPcoStruct.Info.FramesPerTrial = 28;
OutPcoStruct.Info.Orientation = 'oriz';
OutPcoStruct.Info.Direction = '-';
OutPcoStruct.Info.PxlSize = [0.3 0.3];
OutPcoStruct.Info.SamplingF = 30;
OutPcoStruct.Info.StimF = (OutPcoStruct.Info.FramesPerTrial / OutPcoStruct.Info.SamplingF)^-1;

save([fpath fname(1:end-4) '_mod.mat'],'OutPcoStruct');

