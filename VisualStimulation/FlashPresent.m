function timestamps = FlashPresent(app,ParameterVector)
    [Blumi,Slumi,Bt,St,p,n,bsl_check,OneScreenFlag,CalibrationFlag,ard_flag] = ParameterVector{:};

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
        BaselineColor_on = cast([[Blumi;Blumi;Blumi], [app.white;app.white;app.white]], app.ScreenBitDepth);
        StimColor = cast([[Slumi;Slumi;Slumi], [app.white;app.white;app.white]], app.ScreenBitDepth);
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
    timestamps = NaN(1,2*n);
    % Load the WaitSecs function. The first load might take some
    % time.
    WaitSecs(0);

%             ACTUAL START OF STIMULATION
    % December 2018. The initial delay is outside of the stimulus loop
    % Paint the screen for the initial delay
    % the following two lines takes a variable time in the range of 7-19 ms.
    Screen('FillRect', app.w, BaselineColor, cellRects); % paints the rectangle (entire screen)
    Screen('Flip', app.w); % bring the buffered screen to forefront
%             Let's acquire the starting time.
    timZero = WaitSecs(0);

    timOffset = timZero + Bt;

    i = 1;
    while i <= n
        % Wait for the end of the period. For the first period,
        % it just waits for the end of the baseline.
        timStart = timOffset + (i-1) * p;
        timEnd = timStart+St;

        % next lines flashes the screen with or without the Hermes rectangle. 6-12 ms on the Acer
        %for flashes we suppose that stim duration is 20-100ms, which is compatible with Hermes detection and idle time
        if bsl_check
            if mod(i,2)==1
                Screen('FillRect', app.w, BaselineColor_on, cellRects); % paint the rectangle (entire screen)
            else
                Screen('FillRect', app.w, StimColor, cellRects); % paint the rectangle (entire screen)
            end
        else
            Screen('FillRect', app.w, StimColor, cellRects); % paint the rectangle (entire screen)
        end
        timestamps(2*i-1) = Screen('Flip', app.w, timStart);

        % the flash is complete
        Screen('FillRect', app.w, BaselineColor, cellRects); % paint the rectangle (entire screen)
        timestamps(2*i) = Screen('Flip', app.w, timEnd); % wait for the end of stim
        
        i = i+1;
    end
    WaitSecs(Bt);
    
    if OneScreenFlag
        CloseScreen
    end

    timestamps = timestamps - timZero;
end
