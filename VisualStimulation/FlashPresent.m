function [timestamps, interrupted] = FlashPresent(app,ParameterVector)
    % oculusFlag and optDtrTime are always the last 2 elements of part of
    % ParamterVector. Since they're not needed in this function, they are
    % discarded with ~.
    [Blumi,Slumi,Bt,St,p,n,bsl_check,PcoWhileStimFlag,OneScreenFlag,CalibrationFlag,ard_flag,...
        baseline_ttl,oculus,optDtrTime] = ParameterVector{:};

%             Starts the OpenGL session if in single screen mode
    if OneScreenFlag
        OpenScreen(app, Blumi)
    end

    %             If the calibration is selected, this converts the values of
    %             luminance (cd/m2) into "Escher values" (between 0 and 1).
    if CalibrationFlag
        [Blumi,~] = Lumi2Escher(Blumi,app.white,app.ScreenFunc);
        [Slumi,~] = Lumi2Escher(Slumi,app.white,app.ScreenFunc);
        StandbyLumi = Lumi2Escher(app.StandbyL.Value,app.white,app.ScreenFunc);
    else
        StandbyLumi = app.StandbyL.Value;
    end

    Blumi = app.white*Blumi;             % Luminance expressed as fractions of 'white'
    Slumi = app.white*Slumi;
    StandbyLumi = app.white*StandbyLumi;
    
    %             New part. Enrico 2019/05/24
    if ard_flag
        StandbyColor = cast([[StandbyLumi;StandbyLumi;StandbyLumi], [0;0;0]], ...
            app.ScreenBitDepth);
        BaselineColor = cast([[Blumi;Blumi;Blumi], [0;0;0]], app.ScreenBitDepth);
        BaselineColor_ttl = cast([[Blumi;Blumi;Blumi], [app.white;app.white;app.white]], app.ScreenBitDepth);
        StimColor = cast([[Slumi;Slumi;Slumi], [app.white;app.white;app.white]], app.ScreenBitDepth);
        cellRects = [app.screenRect; app.HermesRect]';
        %                 This is commented because in flashes, the optical DTR
        %                 duration is the same as the flash duration
    else
        BaselineColor = cast(Blumi, app.ScreenBitDepth);
        StimColor = cast(Slumi, app.ScreenBitDepth);
        cellRects = app.screenRect;
    end

% This vector contains timestamps:
% One for the initial baseline
% Two for each flash. (Flash turning on and flash turning off)
% One for the baseline (standby) when the stimulation is done.
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
    
    % Prepare relevant timepoints:
    time_flashON = timOffset + (0:n-1).*p;
    time_flashOFF = timOffset + (0:n-1).*p + St;
    time_finalBaseline = timOffset + n.*p;
    
    i = 1;
    % detectKeyboard is used to stop the visual stimulation by pressing the
    % keys "stop" on the keyboard for a while. If detectKeyboard returns a true
    % value, the loop stops and the function returns prematurely.
    interrupted = false;
    while i <= n && ~interrupted
        
        interrupted = detectKeyboard();

        % next lines flashes the screen with or without the Hermes rectangle. 6-12 ms on the Acer
        %for flashes we suppose that stim duration is 20-100ms, which is compatible with Hermes detection and idle time
        if bsl_check
            if mod(i,2)==1
                Screen('FillRect', app.w, BaselineColor_ttl, cellRects); % paint the rectangle (entire screen)
            else
                Screen('FillRect', app.w, StimColor, cellRects); % paint the rectangle (entire screen)
            end
        else
            Screen('FillRect', app.w, StimColor, cellRects); % paint the rectangle (entire screen)
        end
        timestamps(1+2*i-1) = Screen('Flip', app.w, time_flashON(i));

        % the flash is complete
        Screen('FillRect', app.w, BaselineColor, cellRects); % paint the rectangle (entire screen)
        timestamps(1+2*i) = Screen('Flip', app.w, time_flashOFF(i)); % wait for the end of stim
        
        i = i+1;
    end
    
    % Prepare baseline (standby) after stimulation
    Screen('FillRect', app.w, StandbyColor, cellRects)
    if interrupted
        disp('STOPPED BY KEYBOARD')
        timestamps(end) = Screen('Flip', app.w);
    else
        timestamps(end) = Screen('Flip', app.w, time_finalBaseline);
    end
    
    if OneScreenFlag
        CloseScreen
    end

    timestamps = timestamps - timZero;
end
