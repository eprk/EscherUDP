function [fr,frames]=PCO_estimateFrameRate(vid)
    % This function starts an acquisition of some frames
    % with our PCO Edge4.2 controlled by the VideoInput object 'vid'
    % and returns the average acquisition rate and the acquired frames.
    % Try to acuire 10 frames, but don't let this measure last longer than
    % 5 seconds.
    
    % INPUT:
    %   -vid: valid VideoInput object.
    
    % OUTPUT:
    %   -fr: average frame rate (Hz).
    %   -frames: acquired frames. 4D matrix of uit16.
    
    % get the status of 'LoggingMode'
    logging_mode = vid.LoggingMode;
    % set 'LoggingMode' to 'memory'
    vid.LoggingMode = 'memory';
    
    % Get the exposure time.
    cam = getselectedsource(vid);
    expos_unit = cam.E1ExposureTime_unit;
    expos_val = cam.E2ExposureTime;
    switch expos_unit
        case 'ns'
            k=1e9;
        case 'us'
            k=1e6;
        case 'ms'
            k=1e3;
    end
    expos = expos_val/k; % exposure time in seconds
    
    % Max frames in 5s
    max_frames = round(5/expos);
    
    % How many frames?
    n_frames = min(max_frames,10); % no more than 5 seconds
    n_frames = max(n_frames,2); % at least 2 frames
    vid.FramesPerTrigger = n_frames;
    
    % start acquisition
    start(vid)
    
    % get data
    frames=getdata(vid);
    
    % get timestamps
    [n,t]=getPcoBinaryTimestamps(squeeze(frames));
    
    % check that no frame has been skipped
    assert(isequal(n,1:n_frames), 'Skipped frames. Try initializing the camera again.')
    
    % get the average frame period
    frame_period = diff(t);
    fr = 1/mean(seconds(frame_period));
    
    % set 'LoggingMode' back to the previous value
    vid.LoggingMode = logging_mode;
    
end