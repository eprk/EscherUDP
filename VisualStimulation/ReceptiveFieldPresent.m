function [order,timestamps] = ReceptiveFieldPresent(app,ParameterVector)
    [Blumi,Slumi,Bt,St,p,n,nrows,ncols,OneScreenFlag,CalibrationFlag,ard_flag] = ParameterVector{:};
    % Blumi: baseline luminance
    % Slumi: stimulus luminance
    % Bt: baseline time (s)
    % St: stimulus  ltime (s)
    % p: period (s)
    % n: number of stimulations
    % nrows: number of rows
    % ncols: number of columns
    % OneScreenFlag: logical. If true, the stimulus appears on a new window
    %       on the main screen
    % CalibrationFlag: logical. If true, use calibration values for
    %       luminance
    % ard_flag: logical. If true, add the optical TTL for Hermes.
    
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
    
    % prepare the stimuli:
    spotW = app.screenRect(3)./ncols;
    spotH = app.screenRect(4)./nrows;
    ycoord = reshape(repmat((0:nrows-1)'.*spotH,1,ncols),[],1);
    xcoord = reshape(repmat((0:ncols-1).*spotW,nrows,1),[],1);
    spots = [xcoord,ycoord,xcoord+spotW,ycoord+spotH]; % each row is a square. Squares are arranged following maltab linear indexing:
    n_spots = ncols*nrows;
    if app.randomizeorderCheckBox.Value
        indices = randperm(n_spots);
    else
        indices = 1:n_spots;
    end
    order = repmat(indices,1,n);

    % the 1st square (1st row) is in screen row=1,col=1 (top left).
    % the 2nd square (2nd row) is in screen row=2, col=1...
    
    if ard_flag
        BaselineColor = cast([[Blumi;Blumi;Blumi], [0;0;0]], app.ScreenBitDepth);
        StimColor = cast([[Blumi;Blumi;Blumi], [app.white;app.white;app.white],[Slumi;Slumi;Slumi]], app.ScreenBitDepth);
        cellRects = [app.screenRect; app.HermesRect]';
        %                 This is commented because in flashes, the optical DTR
        %                 duration is the same as the flash duration
        %                 optDtrTime = app.optDtrTimeTxt.Value/1000; % optical DTR duration in s
    else
        BaselineColor = cast(Blumi, app.ScreenBitDepth);
        StimColor = cast([[Blumi;Blumi;Blumi],[Slumi;Slumi;Slumi]], app.ScreenBitDepth);
        cellRects = [app.screenRect];
    end 

    
    
    
    
%             This vector contains two timestamps for each flash. One is
%             for the flash turning on and one for the flash turning off.
    timestamps = NaN(n*n_spots,2);
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

    for i=1:n
        for j=1:n_spots
            % Wait for the end of the period. For the first period,
            % it just waits for the end of the baseline.
            timStart = timOffset + (i-1)*n_spots*p + (j-1) * p;
            timEnd = timStart+St;

            % next lines flashes the screen with or without the Hermes rectangle. 6-12 ms on the Acer
            %for flashes we suppose that stim duration is 20-100ms, which is compatible with Hermes detection and idle time
            Screen('FillRect', app.w, StimColor, [cellRects,spots(indices(j),:)']); % paint the rectangle (entire screen)
            timestamps((i-1)*n_spots+j,1) = Screen('Flip', app.w, timStart);

            % the flash is complete
            Screen('FillRect', app.w, BaselineColor, cellRects); % paint the rectangle (entire screen)
            timestamps((i-1)*n_spots+j,2) = Screen('Flip', app.w, timEnd); % wait for the end of stim
        end
    end
    WaitSecs(Bt);
    
    if OneScreenFlag
        CloseScreen
    end

    timestamps = timestamps - timZero;
end
