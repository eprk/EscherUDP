function [timestamps, interrupted] = SlowFlashPresent(app,ParameterVector)
    
    % Presentation of "Slow" flashes.
    %
    % Classification of flashes into "fast" and "slow" is
    % relative to Hermes idle time and only affect temporization (what is shown
    % on the visible part of the screen does not differ between fast and slow flashes):
    %  - If flahs duration < Hermes idle time, then the flash is "fast".
    %           This is the traditional way flashes are delivered. Only the
    %           flash presentation comes with an optical TTL (cue). Also,
    %           the duration of the optical TTL coincides with the duration
    %           of the flash, even if a different duration is set on the
    %           GUI.
    %  - If flash duration >= Hermes idle time, then the flash is "slow".
    %           Here, the approach used for fast flashes would make Hermes
    %           generate unwanted TTLs. E.g. Hermes idle time is 200 ms
    %           and flash duration is 5 s. If the optical TTL last 5 s like
    %           the flash, Hermes would bwould produces a TTL at flash onset,
    %           then idle for 200 ms, then it would produce another TTL
    %           -since the flash and optical TTL are still there -, then idle
    %           for 200 ms, then produce another TTL... and so on, for the
    %           whole length of the flash. For this reason, temporization
    %           of slow flashes is handled similar to all the other
    %           "non-transient" stimuli: the optical TTL is shown for the
    %           amount of time specified as "Duration of cue" on the GUI,
    %           then it disappears. The cue is also shown when the flash
    %           disappears.

    
    [Blumi,Slumi,Bt,St,p,n,bsl_check,...
        PcoWhileStimFlag,OneScreenFlag,CalibrationFlag,...
        ard_flag,baseline_ttl,oculusFlag,optDtrTime] = ParameterVector{:};

    
    
%             Starts the OpenGL session if in single screen mode
    if OneScreenFlag
        OpenScreen(app, Blumi)
    end

    %             If the calibration is selected, this converts the values of
    %             luminance (cd/m2) into "Escher values" (between 0 and 1).
    if CalibrationFlag
        [Blumi,~] = Lumi2Escher(Blumi,app.white,app.ScreenFunc);
        [Slumi,~] = Lumi2Escher(Slumi,app.white,app.ScreenFunc);
    end

    Blumi = app.white*Blumi;             % Luminance expressed as fractions of 'white'
    Slumi = app.white*Slumi;

    %             New part. Enrico 2019/05/24
    if ard_flag
        BaselineColor = cast([[Blumi;Blumi;Blumi], [0;0;0]], app.ScreenBitDepth);
        BaselineColor_ttl = cast([[Blumi;Blumi;Blumi], [app.white;app.white;app.white]], app.ScreenBitDepth);
        StimColor = cast([[Slumi;Slumi;Slumi], [0;0;0]], app.ScreenBitDepth);
        StimColor_ttl = cast([[Slumi;Slumi;Slumi], [app.white;app.white;app.white]], app.ScreenBitDepth);
        cellRects = [app.screenRect; app.HermesRect]';
        %                 This is commented because in flashes, the optical DTR
        %                 duration is the same as the flash duration
        %                 optDtrTime = app.optDtrTimeTxt.Value/1000; % optical DTR duration in s
    else
        BaselineColor = cast(Blumi, app.ScreenBitDepth);
        StimColor = cast(Slumi, app.ScreenBitDepth);
        cellRects = app.screenRect;
    end

%             This vector contains two timestamps for each flash. One is
%             for the flash turning on and one for the flash turning off.
    timestamps = NaN(1,1+2*n+1);
    % Load the WaitSecs function. The first load might take some
    % time.
    WaitSecs(0);

%             ACTUAL START OF STIMULATION
    % December 2018. The initial delay is outside of the stimulus loop
    % Paint the screen for the initial delay
    % the following two lines takes a variable time in the range of 7-19 ms.
%     Screen('FillRect', app.w, BaselineColor, cellRects); % paints the rectangle (entire screen)
%     Screen('Flip', app.w); % bring the buffered screen to forefront
% %             Let's acquire the starting time.
%     timZero = WaitSecs(0);

    % This function presents the baseline
    timZero = BaselinePresent(app.w,cellRects,BaselineColor,...
        BaselineColor_ttl,ard_flag,baseline_ttl,optDtrTime); 
    
    timOffset = timZero + Bt;
    timestamps(1) = timZero;
    
    % Compute relevant timepoints
    time_flashON   = timZero + Bt + (0:n-1) * p;
    time_flashOFF  = timZero + Bt + (0:n-1) * p + St;
    if ard_flag
        time_flashON_ttlOFF  = timZero + Bt + (0:n-1) * p + optDtrTime;
        time_flashOFF_ttlOFF = timZero + Bt + (0:n-1) * p + St + optDtrTime;
    end
    
    i = 1;
    % detectKeyboard is used to stop the visual stimulation by pressing the
    % keys "stop" on the keyboard for a while. If detectKeyboard returns a true
    % value, the loop stops and the function returns prematurely.
    interrupted = false;
    while i <= n && ~interrupted
        
        interrupted = detectKeyboard();
        
        % next lines flashes the screen with or without the Hermes rectangle.
        if ard_flag
            % prepare flash AND optical TTL
            if bsl_check && mod(i,2)==1
                Screen('FillRect', app.w, BaselineColor_ttl, cellRects); 
            else
                Screen('FillRect', app.w, StimColor_ttl, cellRects); 
            end 
        else
            % flash only
            if bsl_check && mod(i,2)==1
                % I see no purpose in alternating a flash and a basline if
                % Hermes is not used - just increase the flash period!.
                % Anyway, better being safe than sorry.
                Screen('FillRect', app.w, BaselineColor, cellRects); 
            else
                Screen('FillRect', app.w, StimColor, cellRects); 
            end
        end
        timestamps(1+2*i-1) = Screen('Flip', app.w, time_flashON(i) );

            
        % Next lines make the optical TTL disappear.
        if ard_flag
            if bsl_check && mod(i,2)==1
                Screen('FillRect', app.w, BaselineColor, cellRects);
            else
                Screen('FillRect', app.w, StimColor, cellRects);
            end
            Screen('Flip', app.w, time_flashON_ttlOFF(i) );
        end
        
        
        % when the flash is complete:
        if ard_flag
            Screen('FillRect', app.w, BaselineColor_ttl, cellRects);
        else
            Screen('FillRect', app.w, BaselineColor, cellRects);
        end
        timestamps(1+2*i) = Screen('Flip', app.w, time_flashOFF(i)); % wait for the end of the flash
        
         % Next lines make the optical TTL disappear.
        if ard_flag
            Screen('FillRect', app.w, BaselineColor, cellRects);
            Screen('Flip', app.w, time_flashOFF_ttlOFF(i) );
        end
        
        
        
        i = i+1;
    end
    
    if interrupted
        disp('STOPPED BY KEYBOARD')
%     else
%     WaitSecs(Bt);        
    end
    
    if OneScreenFlag
        CloseScreen
    end

    timestamps = timestamps - timZero;
end