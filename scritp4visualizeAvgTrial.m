out = master.OutPcoStruct;

mat = out.Images;
info = out.Info;


% mat4d = retrieveTrials(mat,info);
% nfr = info.FramesPerTrial;
% avg = squeeze(mean(mat4d,3));

avg = mat;
nfr = size(avg,3);


figure
imagesc(squeeze(mean(avg,3)))
colorbar
set(gca,'plotboxaspectratio',[1 1 1],'clim',[1650 2000])

str = struct('data',avg,'x',(0:nfr-1)./info.SamplingF);
set(gca,'UserData',str);

