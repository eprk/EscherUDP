function [timestamps,interrupted] = CheckPresent(app,ParameterVector)
    % The input variables are:
    % app, the handle for the app
    % ParameterVector, a vector containing all the needed parameters
    
    [Blumi,Slumi,sF,Bt,p,n,...
        PcoWhileStimFlag,OneScreenFlag,CalibrationFlag,...
        ard_flag,baseline_ttl,oculusFlag,optDtrTime] = ParameterVector{:};

    Glumi = (Slumi + Blumi)/2;
    
% The checkerboard is generated by filling the entire screenRect with 
% squares. Two different "color arrays" are prepared for the alternating 
% pattern. The size of the squares is prepared according to the spatial 
% frequency defined in the grid GUI.
% Synchronisation signals are on the DTR output are generated at the 
% beginning of the sequence.
% This is followed by a equiluminant grey of duration "Baseline".
% After that the alternating stims start with period (one full on-off
% transition) given by the term "Period".

    if OneScreenFlag
        OpenScreen(app, Blumi)
    end

    if CalibrationFlag
        [Blumi,~] = Lumi2Escher(Blumi,app.white,app.ScreenFunc);
        [Slumi,~] = Lumi2Escher(Slumi,app.white,app.ScreenFunc);
        [Glumi,~] = Lumi2Escher(Glumi,app.white,app.ScreenFunc);
    end
    
    % Next lines: insert the LUT correction
    Blumi = app.white*Blumi; % Luminance expressed as fractions of 'white'
    Slumi = app.white*Slumi;
    Glumi = app.white*Glumi;
    
% The parameter sF is the spatial frequency in cycles/degree.
% The spatial frequency of the stimulus in cycles/pixel is calculated.
    f = app.OnePxAngle*sF;
% Number of pixels for one spatial cycle of stimulation (rounded up to 
% integer). One spatial cycle means two squares (one black and one white).
    pixSize = ceil(1/f);
    
% Compute the checkerboard_ck and the associate "color" arrays.
% Side is the size in pixels of one square (which is half cycle).
    side = pixSize/2;
% screenRect contains the screen coordinates. x  y min (0 and 0, strangely)
% and then x max and y max.
% If the oculusMode flag is true than the stimulus is prepared to be
% displayed on the VR goggles. The screen width is divided in half and two 
% identical and aligned checkerboards are presented on each screen.
    if oculusFlag
        halfWidth = app.screenRect(3)/2;
        nSquareX = ceil((halfWidth/side));
    else
        nSquareX = ceil(app.screenRect(3)/side);
    end
    nSquareY = ceil(app.screenRect(4)/side);
    
% the square row must be odd in order to have a correct alternation of on 
% and off squares.
% Makes the number odd by adding 1 if it's even.
    nSquareX = nSquareX - mod(nSquareX,2) + 1;
% the square row must be odd in order to have a correct alternation of on 
% and off squares.
% The number of squares in y-dimension has to be even, instead. This is
% necessary for VR headset.
    nSquareY = nSquareY + mod(nSquareY,2);

% Total area (in pixels) occupied by the checkerboard_ck. If this is larger
% than the screen it is cropped on the right and bottom sides.
% If in "oculus mode" the crop is performed on the left side.
    %        if oculusFlag,
    % checkerW = side*nSquareX;
    % winRectAdapted= [0 0 halfWidth side*nSquareY];
    %        else
    winRectAdapted = [0 0 side*nSquareX side*nSquareY];
    %        end
    ntot = nSquareX*nSquareY;
% Create the tiling squares stored in the array cellRects.
% "ArrangeRects" is a function provided by the toolbox.
% cellRects contains the rectangle coordinates. Two screen buffer are
% created: one with the "white" stim and one with the "black".
% Then, at the correct timing the screens are flipped.
    
    cellRects = ArrangeRects(ntot,[0 0 2 2],winRectAdapted);
    
% If the Oculus Flag is on, cellRects will be changed so that the second 
% screen will have the same stimuli (necessary?).
    if oculusFlag
% Now double the cellRects array... to do that 2 words about its structure:
% it contains the list of the xmin ymin xmax ymax coodinates of the 
% checkers.
        
% Now we build the second half of the screen by copying the left half plus 
% the half width of the screen.
        cellRects2 = cellRects;
% halfWidth is added to the first and third column
        cellRects2(:,[1 3]) = cellRects(:,[1 3]) + halfWidth;
        
        cellRects = [cellRects; cellRects2];
        
% The screen has been doubled in this way and so, also ntot has to be 
% doubled.
        ntot = 2*ntot;
    end
    
    cellColor1On = ones(3,ntot, app.ScreenBitDepth) .* Slumi;
    cellColor2On = zeros(3,ntot, app.ScreenBitDepth) + Blumi;
    cellColor1On(1:3,1:2:ntot) = Blumi;
    cellColor2On(1:3,1:2:ntot) = Slumi;
    
    %             New part. Enrico 2019/05/24
    if ard_flag
        BaselineColor_ttl = cast([[Glumi;Glumi;Glumi], [app.white; app.white; app.white]], ...
            app.ScreenBitDepth);
        BaselineColor = cast([[Glumi;Glumi;Glumi], [0;0;0]], ...
            app.ScreenBitDepth);
        BaselineRect = [app.screenRect; app.HermesRect]';
        
        cellColor1Off = [cellColor1On, [0; 0; 0]];
        cellColor2Off = [cellColor2On, [0; 0; 0]];
        cellColor1On = [cellColor1On, [app.white; app.white; app.white]];
        cellColor2On = [cellColor2On, [app.white; app.white; app.white]];
        cellRects = [cellRects; app.HermesRect]';
    else
        BaselineColor = cast(Glumi, app.ScreenBitDepth);
        BaselineRect = app.screenRect;
        BaselineColor_ttl = [];
        cellRects = cellRects';
    end
    
% This vector contains:
% - The time of the initial baseline (time=0)
% - timestamps for each period, one for each checkerboard reversal.
% - The time when the screen goes back to standby (if not OneScreenMode).
    timestamps = NaN(1, 1 + 2*n + double(~OneScreenFlag));
% Load the WaitSecs function
    WaitSecs(0);
    
% ACTUAL START OF STIMULATION
% Fill screen with the baseline equiluminant gray.
% OK, let's start.
% First thing first: edge out and wait for end of baseline.
% This function presents the baseline
    timZero = BaselinePresent(app.w,BaselineRect,BaselineColor,...
        BaselineColor_ttl,ard_flag,baseline_ttl,optDtrTime); 
    timestamps(1)=timZero;
    
% --- Prepare first stimulus (from baseline to cellColor1)
    Screen('FillRect', app.w, cellColor1On, cellRects)
    i=1;
    
% detectKeyboard is used to stop the visual stimulation by pressing the
% keys "stop" on the keyboard for a while. If detectKeyboard returns a true
% value, the loop stops and the function returns prematurely.
    interrupted = false;
    while i <= n && ~interrupted
        interrupted = detectKeyboard();
% Remember: p is the half of the period!
        FirstTim = timZero+Bt+2*(i-1)*p;
        timestamps(1+2*i-1) = Screen('Flip', app.w, FirstTim);
% % Out an edge on the DTR line to synchronize the sweep beginning
%        if app.SerialSynch == 1     
% % Give out a rising edge at the beginning of the sweep to synchronize.
%            ComHandle.DataTerminalReady = 'on';
%            timA = WaitSecs (0.002);
%            ComHandle.DataTerminalReady = 'off';
%        end
    
% --- Screen flip to terminate optical DTR
        if ard_flag
            Screen('FillRect',app.w,cellColor1Off,cellRects)
% cellColor1On stays on for "optDtrTime" seconds.
% Arduino must wait more than that.
            Screen('Flip', app.w, FirstTim+optDtrTime);
        end

% --- Second stimulus (from cellColor1 to cellColor2)
% Remember: p is half of the period!
        SecondTim = timZero+Bt+(2*i-1)*p;
        Screen('FillRect',app.w,cellColor2On,cellRects);
        timestamps(1+2*i) = Screen('Flip', app.w, SecondTim);
%        if app.SerialSynch == 1
%            ComHandle.DataTerminalReady = 'on';
%            timA = WaitSecs (0.002);
%            ComHandle.DataTerminalReady = 'off';
%        end

% --- Screen flip to terminate optical DTR
        if ard_flag
            Screen('FillRect', app.w,cellColor2Off,cellRects)
% colOn1 stays on for "optDtrTime" s. Arduino must wait more than that.
            Screen('Flip', app.w, SecondTim+optDtrTime);
        end
% ---

% --- Prepare first stimulus (from cellColor2 to cellColor1)
        Screen('FillRect', app.w,cellColor1On,cellRects)
        i=i+1;
    end
    
    % Paints the rectangle (entire screen) with equiluminant gray.
    Screen('FillRect', app.w, BaselineColor, BaselineRect)
    t_end=Screen('Flip', app.w, timZero+Bt+2*n*p);
    timestamps(2*n+2)=t_end;
    
    if interrupted
        disp('STOPPED BY KEYBOARD')
    else
        WaitSecs(Bt);
    end
    
    if OneScreenFlag
        CloseScreen
    end

    timestamps = timestamps - timZero;
