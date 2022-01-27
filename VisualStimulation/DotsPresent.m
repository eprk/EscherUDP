function timestamps = DotsPresent(app,ParameterVector)

    % GAB 2021/12/02. shows dots moving in the same direction. Dot size and
    % speed can be fixed or randomized around a specific value. Dots can
    % disappear and appear in random positions with a rate set by halflife.
    % At the moment this stimulus does not work with oculusFlag.

    [back_lumi,dots_lumi,Angle,dS,Bt,Pre,StimT,Post,halflife,...
        dotsSize,dens_dots,randSize,randSpeed,darkBack,equiluminantBaseline,n,...
        PcoWhileStimFlag,OneScreenFlag,CalibrationFlag,...
        oculusFlag,ard_flag,optDtrTime] = ParameterVector{:};
    
    if OneScreenFlag
        OpenScreen(app, back_lumi)
    end
    
    % In case PCO camera is used to record while stimulating, the PreG baseline
    % is set with the same duration as the GridT.
    % PostG time is just the same.
    
    % Enable alpha blending with proper blend-function. We need it
    % for drawing of smoothed points:
    Screen('BlendFunction', app.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % Set priority to max
    Priority(MaxPriority(app.w));
    
    if equiluminantBaseline
        equilumi = (dots_lumi+back_lumi)/2;
    else
        equilumi = back_lumi;
    end
    if CalibrationFlag
        [back_lumi,~] = Lumi2Escher(back_lumi,app.white,app.ScreenFunc);
        [dots_lumi,~] = Lumi2Escher(dots_lumi,app.white,app.ScreenFunc);
        [equilumi,~] = Lumi2Escher(equilumi,app.white,app.ScreenFunc);
    end
    back_lumi = back_lumi*app.white;
    dots_lumi = dots_lumi*app.white;
    equilumi = equilumi*app.white;
    
    if ~darkBack
        % swap luminance between bacground and dots
        tmp = back_lumi;
        back_lumi = dots_lumi;
        dots_lumi = tmp;
    end
    
    BackgroundColor = cast(back_lumi, app.ScreenBitDepth);
    BaselineColor = cast(equilumi, app.ScreenBitDepth);
    BaselineScreen = app.screenRect;
%     if ard_flag % prepare the additional rectangle for optical synch signal
%         BaselineColor = cast([[back_lumi;back_lumi;back_lumi], [0;0;0]], app.ScreenBitDepth);
%         BaselineScreen = [app.screenRect; app.HermesRect]';
%         optDtr_On = ;
%         % In case that PCO recording is used, the baseline also needs to trigger
%         % Hermes. So BaselineColor will contain the baseline with a Hermes
%         % rectangle that is ON (white), whereas BaselineColorOff will contain a
%         % Hermes rectangle that is OFF (black).
%         if PcoWhileStimFlag
%             BaselineColorOff = BaselineColor;
%             BaselineColor = cast([[back_lumi;back_lumi;back_lumi], ...
%                 [app.white;app.white;app.white]], app.ScreenBitDepth);
%         end       
%     end
    
    %	Before starting we need to compute some parameters needed for
    %   the animation of the grating.
    %	First of all, the total duration of one period is computed.
    totPeriod = Pre+StimT+Post;
    %             Definition of the drawn rectangle on the screen:
    %             Compute it to  be the visible size of the grating, centered on the
    %             screen:
    %             ENRICO 20190504 Removed the destination rect of variable
    %             size. Now the destination rect is the whole screen.
    %             dstRect = [0 0 visiblesize visiblesize];
    %             dstRect = CenterRect(dstRect, app.screenRect);
    %             Translate that into the amount of seconds to wait between screen
    %             redraws/updates:
    %             waitframes = 1 means: Redraw every monitor refresh. If your GPU is
    %             not fast enough to do this, you can increment this to only redraw
    %             every n'th refresh. All animation paramters will adapt to still
    %             provide the proper grating. However, if you have a fine grating
    %             drifting at a high speed, the refresh rate must exceed that
    %             "effective" grating speed to avoid aliasing artifacts in time, i.e.,
    %             to make sure to satisfy the constraints of the sampling theorem
    %             (See Wikipedia: "Nyquist?Shannon sampling theorem" for a starter, if
    %             you don't know what this means):
    waitframes = 1;
    %             Translate frames into seconds for screen update interval:
    waitduration = waitframes * app.ifi;

    
    % Generate the dots:::::::::::::::::::::::::::::::::::::::::::::::::::    
    ppf = dS * waitduration /app.OnePxAngle;         % dot speed (pixels/refresh)
    
    % dotsSize is measured in degrees.
    % dotsSize_pxl is converted in pixels
    dotsSize_pxl = dotsSize/app.OnePxAngle;                 % dot size (pixels)
    
    % screen borders
    x0 = app.screenRect(1);
    xmax = app.screenRect(3);
    y0 = app.screenRect(2);
    ymax = app.screenRect(4);
    [center(1), center(2)] = RectCenter(app.screenRect);
    
    % Let's create a square screen whose edge is as long as the screen
    % diagonal (i.e. the biggest possible dimension)
	dia = sqrt( (xmax-x0).^2 + (ymax-y0).^2); % diagonal in pixels
    dia_deg = atand(dia/2/app.ScreenDistance.Value)*2; % diagonal in degrees of visual field
    
    % compute the actual number of dots based on the selected density and
    % the surface of the new square screen. This number is different than
    % the number of dots on the User Interface, which is the average number
    % of dots that are visible on the screen
    ndots = round(dens_dots * dia_deg.^2);
    
    
    % dot positions
    x = dia*(rand(ndots,1)-0.5);
    y = dia*(rand(ndots,1)-0.5);
    xy = [x,y];   % dot positions in Cartesian coordinates (the origin is the center of the screen)
    
    % dot steps (they only move horizontally now. Later we'll rotate)
    dxdy = ones(ndots,2).*ppf.*[1,0];
    if randSpeed
        dxdy = dxdy .* gamrnd(10,0.1,ndots,1);
    end
    
    % rotation matrix
    rotmat = [  cosd(-Angle), -sind(-Angle);...
                sind(-Angle), cosd(-Angle)];
    
    % Clamp point sizes to range supported by graphics hardware:
    [minsmooth,maxsmooth] = Screen('DrawDots', app.w);
    dotsSize_pxl_new = min(max(dotsSize_pxl, minsmooth), maxsmooth);
    if dotsSize_pxl_new~=dotsSize_pxl
        warning('Actual dot size differs from the selected size')
    end
    dotsSize_pxl = dotsSize_pxl_new;
    
    % Create a vector with different point sizes for each single dot, if
    % requested:
    if randSize
        dotsSize_pxl = dotsSize_pxl .* gamrnd(10,0.1,ndots,1);
    end

    % Clamp point sizes to range supported by graphics hardware:
    [minsmooth,maxsmooth] = Screen('DrawDots', app.w);
    dotsSize_pxl = min(max(dotsSize_pxl, minsmooth), maxsmooth);
    
    % dots halflife. Halflife is the expected time a dot stays on the
    % screen (if it doesn't reach a border before). At every refresh, a
    % fraction f_kill of dots is killed. If X is a random variable that
    % counts the number of frames a point stays on the screen before being
    % killed, then X has a geometric distribution with p = f_kill. The
    % expected value for X (refreshes) is 1/p = 1/f_kill. So, we can find the
    % appropriate value f_kill to obtain the desired halflife with:
    f_kill = 1/(halflife./waitduration);
    
    timestamps = NaN(1,2*n);
    % Load the WaitSecs function.
    WaitSecs(0);
    
% START OF THE ACTUAL STIMULATION :::::::::::::::::::::::::::::::::::::::::

    Screen('FillRect', app.w, BaselineColor, BaselineScreen);
    if ard_flag
        Screen('FillRect', app.w, 0, app.HermesRect);
    end
    Screen('Flip', app.w);  % bring the buffered screen to forefront
    timZero = WaitSecs(0);
    timOffset = timZero + Bt;
    
    TrialStartTime = timOffset+(0:n-1)*totPeriod;
    BaseDtrEndTime = timOffset+(0:n-1)*totPeriod+optDtrTime; % end of the optical DTR of the baseline
    timStart = timOffset+(0:n-1)*totPeriod+Pre; % start of the grid
    dtrendtime = timOffset+(0:n-1)*totPeriod+Pre+optDtrTime; % end of optical DTR for Hermes
    timEnd = timOffset+(0:n-1)*totPeriod+Pre+StimT; % end of the grid
        
    i = 1;
    while i<=n
        % PRE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if Pre>0
            % First off, fill the screen with uniform gray background for the
            % pre-stimulus baseline.
            Screen('FillRect', app.w, BaselineColor, BaselineScreen);
            if PcoWhileStimFlag
                % also trigger on baseline
                Screen('FillRect', app.w, app.white, app.HermesRect);
            elseif ard_flag
                Screen('FillRect', app.w, 0, app.HermesRect);
            end
            Screen('Flip', app.w, TrialStartTime(i));
            
            % Only if PCO is used, an optical DTR is sent to Hermes, so that also the
            % baseline before stimulation can be recorded.
            % The next code turns OFF this optical DTR.
            if PcoWhileStimFlag
                Screen('FillRect', app.w, BaselineColor, BaselineScreen);
                Screen('FillRect', app.w, 0, app.HermesRect);
                Screen('Flip', app.w, BaseDtrEndTime(i));
            end
        end
        vbl =  WaitSecs('UntilTime', timStart(i));
        timestamps(2*i-1) = vbl;
        
        ii=0;
        % ANIMATION LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        while vbl < timEnd(i)
            
            % update dots position
            xy = xy + dxdy; % move dots
            % check to see which dots have gone beyond the borders of the
            % screen
            i_out = find(  xy(:,1) > dia/2 ); % out of horiz borders
            i_killed = find(rand(ndots,1)<f_kill);	% dots to reposition
            nout = length(i_out);
            nkilled = length(i_killed);
            if nout>0
                % make it appear the other side
                xy(i_out,1) = -dia/2;
            end
            if nkilled>0
                % choose new coordinates
                xy(i_killed,:) = [dia*(rand(nkilled,1)-0.5), dia*(rand(nkilled,1)-0.5)];
            end
            % rotate the dots by the desired angle
            xymatrix = rotmat*xy';
    
            % prepare the background
            Screen('FillRect', app.w, BackgroundColor, BaselineScreen);
            
            % draw the dots
            Screen('DrawDots', app.w, xymatrix, dotsSize_pxl, dots_lumi, center, 1);
            
            % add the optical dtr on top of the dots
            if ard_flag
                if vbl<dtrendtime(i)
                    % This is the beginning of the stimulus, when the
                    % optical DTR has to be white.
                    Screen('FillRect', app.w, app.white, app.HermesRect);
                else
                    % This is the grating when the optical DTR has to be
                    % black.
                    Screen('FillRect', app.w, 0, app.HermesRect);
                end
            end
            
%                 Flip 'waitframes' monitor refresh intervals after last redraw.
%                 Providing this 'when' timestamp allows for optimal timing
%                 precision in stimulus onset, a stable animation framerate and at
%                 the same time allows the built-in "skipped frames" detector to
%                 work optimally and report skipped frames due to hardware
%                 overload:
            vbl = Screen('Flip', app.w, vbl + waitframes * app.ifi);

%                 ENRICO. Removed.
%                 % Abort function if any key is pressed:
%                 if KbCheck
%                     break
%                 end
            ii=ii+1;
        end
        timestamps(2*i) = vbl; % The last vbl acquired.
        
        % POST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if Post>0
            Screen('FillRect', app.w, BaselineColor, BaselineScreen);
            if ard_flag
                Screen('FillRect', app.w, 0, app.HermesRect);
            end
            Screen('Flip', app.w);
        end
        
        % initialize dots again
        % dot positions
        x = dia*(rand(ndots,1)-0.5);
        y = dia*(rand(ndots,1)-0.5);
        xy = [x,y];   % dot positions in Cartesian coordinates (the origin is the center of the screen)
    
        i=i+1;
    end
    WaitSecs(Bt);
    
    if OneScreenFlag
        CloseScreen
    end

%             Log writing.
    timestamps = timestamps - timZero;
end
