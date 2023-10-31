%% Get adaptor name
if verLessThan('matlab','8.2')%R2013a or older
    error('This adaptor is supported in Matlab 2013b and later versions'); 
elseif verLessThan('matlab','9.0') %R2015b - R2013b
    if(strcmp(computer('arch'),'win32'))
        adaptorName = ['pcocameraadaptor_r' version('-release') '_win32'];
    elseif(strcmp(computer('arch'),'win64'))
        adaptorName = ['pcocameraadaptor_r' version('-release') '_x64'];
    else
        error('This platform is not supported.');
    end
else %R2016a and newer
    if(strcmp(computer('arch'),'win64'))
        adaptorName = ['pcocameraadaptor_r' version('-release')];
    else
        error('This platform is not supported.');
    end
end

%% Configure camera and record images
%Create video input object
vid = videoinput(adaptorName, 0);

%Create adaptor source
cam = getselectedsource(vid);

%Set horizontal binnig
cam.B1BinningHorizontal = '04';

%Set vertical binning
cam.B2BinningVertical = '04';

%Set Exposure time unit
cam.E1ExposureTime_unit = 'us';

%Set exposure time
cam.E2ExposureTime = 500000; 


% set trigger parameters
triggerconfig(vid, 'immediate', 'none', 'none');

cam.TMTimestampMode = 'BinaryAndAscii';

cam.NFNoiseFilter = 'off';

%%
vid.FramesPerTrigger=30;

%Set logging to memory
vid.LoggingMode = 'disk&memory';
vid.DiskLogger = VideoWriter('prova.mj2','Motion JPEG 2000');
open(vid.DiskLogger)


im=preview(vid);


start(vid)
frames=getdata(vid);
stoppreview(vid)

% implay(frames)

% decode ascii timestamps
frame=squeeze(frames(:,:,1,1));
bits=frame(1,1:14);

figure
imagesc(frame)
set(gca,'CLim',[0 11])

% retrieve binary timestamps
[n,t]=getPcoBinaryTimestamps(squeeze(frames));

% check actual frame period
t_rel = seconds(t-t(1));
figure
plot(diff(t_rel)*1000)
subtitle(sprintf('Exposure time = %.3f ms',cam.E2ExposureTime/1000))
title('Frame period jitter')
xlabel('Frame N')
ylabel('Actual frame period (ms)')



vr=VideoReader('prova.mj2');
all_frames = vr.read;
[n,t]=getPcoBinaryTimestamps(squeeze(all_frames));


figure
implay(squeeze(all_frames))


%% set trigger mode: external and trigger some frames with arduino
% 
triggermode = 'ExternExposureStart';
timeout_s = 5;
%Configure trigger type and mode
triggerconfig(vid, 'hardware', '', triggermode);
set(vid,'Timeout',timeout_s); 
cam.IO_2SignalEnableDisable='off';
% 
%Configure polarity of IO signal at trigger port
src.IO_1SignalPolarity = 'rising';
im=preview(vid);
% 
% serve questo? SI'!
nFrames=600;
vid.FramesPerTrigger=nFrames;

% 
%Set exposure time
cam.E2ExposureTime = 10000; 
% set Hermes
master.HermesMsgSend(sprintf('mod=camAc,trig=s,frameP=30000,nFrames=%i',nFrames))
% 

vid.DiskLogger = VideoWriter('prova.mj2','Motion JPEG 2000');
open(vid.DiskLogger)

img=imagesc(master.PcoHAxes,cast(zeros(512,512),'uint16'));
im=preview(vid,img);
start(vid)
% images = getdata(vid, 1);
master.HermesMsgSend('synch=1')

% stop(vid)
% 
% 
frames=getdata(vid);
size(frames)

figure
sliceViewer(squeeze(frames))
[n,t]=getPcoBinaryTimestamps(squeeze(frames));
tstamps=seconds(t-t(1))*1000;
figure
histogram(diff(tstamps))

stop(vid)
vr=VideoReader('prova.mj2');
all_frames = vr.read;
size(all_frames)
[n,t]=getPcoBinaryTimestamps(squeeze(all_frames));
figure
sliceViewer(squeeze(all_frames))






tstamps=seconds(t-t(1))*1000;
% implay(frames)

% decode ascii timestamps
frame=squeeze(frames(:,:,1,1));
bits=frame(1,1:14);

figure
imagesc(frame)
set(gca,'CLim',[0 11])

% retrieve binary timestamps
[n,t]=getPcoBinaryTimestamps(squeeze(frames));

% check actual frame period
t_rel = seconds(t-t(1));
figure
plot(diff(t_rel)*1000)
subtitle(sprintf('Exposure time = %.3f ms',cam.E2ExposureTime/1000))
title('Frame period jitter')
xlabel('Frame N')
ylabel('Actual frame period (ms)')
stoppreview(vid)


