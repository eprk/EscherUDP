function [timestamps,interrupted] = RetinotopyPresent(app,ParameterVector)
    [Blumi,Slumi,Glumi,sF,Bt,p,Angle,RectangleSizeDeg,dS,PostG,n,...
        TrialDeadTime,OneScreenFlag,CalibrationFlag,ard_flag,...
        baseline_ttl,oculusFlag,optDtrTime] = ParameterVector{:};
    
    if OneScreenFlag
        OpenScreen(app, Glumi)
    end

%     Let's convert the spatial frequency of the checkerboard from
%     cycles/degree to cycles/pixels
    f = app.OnePxAngle*sF;
    
%     Let's also convert the rectangle size from degrees to pixels.
% It is approximated to the closest greater even number.
    RectangleSizePx = 2*ceil(RectangleSizeDeg/app.OnePxAngle/2);
    
    if CalibrationFlag
        [Blumi,~] = Lumi2Escher(Blumi,app.white,app.ScreenFunc);
        [Slumi,~] = Lumi2Escher(Slumi,app.white,app.ScreenFunc);
        [Glumi,~] = Lumi2Escher(Glumi,app.white,app.ScreenFunc);
    end
    % Next lines: insert the LUT correction
    Blumi = app.white*Blumi; % Luminance expressed as fractions of 'white'
    Slumi = app.white*Slumi;
    Glumi = app.white*Glumi;

    
    %             The stimulus has to be prepared BEFORE the conversion to the
    %             calibrated look up table
    %             ENRICO 2018/05/02 Let's prepare the gratings and masks in
    %             advance
    GratingStruct = CreateGratings(app, Blumi, Slumi, Glumi, f,...
        RectangleSizePx, Angle, oculusFlag, ard_flag);

    %             This calibration shouldn't be performed before this point, because
    %             the luminance is needed as a non-corrected value for the
    %             CreateGratings function.
    
    
    
    if ard_flag % prepare the additional rectangle for optical synch signal
        BaselineColorDtrOff = cast([[Glumi;Glumi;Glumi], [0;0;0]], app.ScreenBitDepth);
        BaselineColorDtrOn = cast([[Glumi;Glumi;Glumi], [app.white;app.white;app.white]], app.ScreenBitDepth);
        BaselineScreen = [app.screenRect; app.HermesRect]';
    else
        BaselineColorDtrOff = cast(Glumi, app.ScreenBitDepth);
        BaselineColorDtrOn = BaselineColorDtrOff;
        BaselineScreen = app.screenRect;
    end
    
    
%             Prepare the grating textures in advance.
    TexStruct = CreateTextures(app, GratingStruct);
    
%     After creating the textures, if the VR headset is being used, we have
%     to double the texture and the angle
    sR = app.screenRect;
    if ~oculusFlag
%         dstRect = CenterRect([0, 0, ceil(sqrt(sR(3)^2+sR(4)^2)), ceil(sqrt(sR(3)^2+sR(4)^2))], sR);
        dstRect = sR;
    else
% %         NOW IT'S NOT WORKING, SO IT HAS TO BE MODIFIED BEFORE USING THIS.
%         Angle = [Angle, Angle];
%         TexStruct.GratingOne = [TexStruct.GratingOne, TexStruct.GratingOne];
%         
% %         Change the sR
%         sR(3) = app.screenRect(3)/2;
%         sR2 = sR;
%         sR2([1 3]) = sR2([1 3]) + app.screenRect(3)/2;
%         
% %         dstRectTemp = [0, 0, ceil(sqrt(sR(3)^2+sR(4)^2)), ceil(sqrt(sR(3)^2+sR(4)^2))];
% %         dstRect = [CenterRect(dstRectTemp, sR); CenterRect(dstRectTemp, sR2)];
%         
%         dstRect = [sR; sR2];
    end
    
%     Let's convert the drifting speed from degrees/second to
%     pixels/second using app.OnePxAngle, which is degrees/pixel.
    dSPx = dS/app.OnePxAngle; % Important! This can be fractional.
    
%     Let's also decide how far the rectangle should travel across the
%     screen. Probably we want it to go all the way until it
%     disappears completely.

    if Angle==0 || Angle==180
%         If the rectangle is vertical, the distance travelled is the
%         x-dimension
        TravelDistance = sR(3);
% If the bar is vertical, the drifting speed in Y-direction will be zero.
        dSPxY = 0;
        DriftingStartCoorY = 0;

%     We have to decide from what index to start. The rectangle starts from
%     the index max(sR(3:4))+1.
% For the moment the code makes the rectangle start as fully visible at the
% beginning of the screen. Then it drifts until it is fully disappeared
% on the other side of the screen.
        if Angle==0
% The vertical bar moves from left to right.
            DriftingStartCoorX = sR(3)+1;
            dSPxX = dSPx;
        else
% The vertical bar moves from right to left.
            DriftingStartCoorX = 0;
            dSPxX = -dSPx;
        end
        
    else
% If the rectangle is horizontal, the distance travelled is the
% y-dimension
        TravelDistance = sR(4);
% If the bar is horizontal, the drifting speed in X-direction will be zero.
        dSPxX = 0;
        DriftingStartCoorX = 0;
        
        if Angle==90
% The horizontal bar moves from bottom to top.
            DriftingStartCoorY = 0;
            dSPxY = -dSPx;
        else
% The horizontal bar moves from top to bottom.
            DriftingStartCoorY = sR(4)+1;
            dSPxY = dSPx;
        end
    end
    
    
    
    TravelTime = abs(TravelDistance/dSPx); % This is in seconds.
    
%     Now I want a function that goes from the time (0 to TravelTime) to a
%     distance in pixels (0 to TravelDistance).
%     This function is: s(t) = dSPx*t; In which s(t) is the distance from
%     the relative 0 position. If an offset is there in 
    
% One full period of the rectangle will be as long as:
    totPeriod = TravelTime+2*PostG-TrialDeadTime;
    
    fullp = 2*p; % this is a full period of the checkerboard
    
%             This vector contains two timestamps for each period, one for
%             the beginning of the grid and one for the end.
    timestamps = NaN(1,2*n);
%             Load the WaitSecs function.
    WaitSecs(0);
    
% START OF THE ACTUAL STIMULATION
% ENRICO. 26/08/2019 Added an initial delay
% GAB. 14/02/2024 Added an optional opticalTTL at the beginning
    if baseline_ttl
        Screen('FillRect', app.w, BaselineColorDtrOn, BaselineScreen);     % paints the rectangle (entire screen)
        Screen('Flip', app.w);  % bring the buffered screen to forefront
        timZero = WaitSecs(0);
        Screen('FillRect', app.w, BaselineColorDtrOff, BaselineScreen);     % paints the rectangle (entire screen)
        Screen('Flip', app.w, timZero + optDtrTime);  % bring the buffered screen to forefront
    else
        Screen('FillRect', app.w, BaselineColorDtrOff, BaselineScreen);     % paints the rectangle (entire screen)
        Screen('Flip', app.w);  % bring the buffered screen to forefront
        timZero = WaitSecs(0);
    end
    timOffset = timZero + Bt; %timOffset is the actual zero for the stimulation train.

% At the beginning , three time points specific for all trials are
% calculated:
% timStart: the starting time of the trial
% dtrendtime: the end time of the optic dtr
% timEnd: the end time of the drifting of the rectangle, after this there 
% is a baseline time and then a new trial starts.
% First off, fill the screen with uniform gray background for the 
% pre-stimulus baseline.
    TrialStartTime = timOffset+(0:n-1)*totPeriod; % start of the grid
    DtrEndTime = TrialStartTime+optDtrTime;
    TravelStartTime = TrialStartTime + PostG - TrialDeadTime;
    TravelEndTime = TravelStartTime + TravelTime; % end of the drift, then comes the baseline
    
% External loop on stimulus repetitions (trials)
    i = 1;
    interrupted = false;
    while i <= n && ~interrupted
        interrupted = detectKeyboard();
        
        Screen('FillRect', app.w, BaselineColorDtrOn, BaselineScreen);     % paints the rectangle (entire screen)
        Screen('Flip', app.w, TrialStartTime(i));  % bring the buffered screen to forefront
        
        Screen('FillRect', app.w, BaselineColorDtrOff, BaselineScreen);     % paints the rectangle (entire screen)
        Screen('Flip', app.w, DtrEndTime(i));  % bring the buffered screen to forefront
        
        vbl = WaitSecs('UntilTime', TravelStartTime(i));
        
        timestamps(2*i-1) = vbl;
        
% Animation loop:
        while vbl < TravelEndTime(i)
            RelVbl = vbl-TravelStartTime(i);
            xoffset = round(DriftingStartCoorX - dSPxX * RelVbl);
            yoffset = round(DriftingStartCoorY - dSPxY * RelVbl);
            
            srcRectTemp = [xoffset, yoffset, sR(3)+xoffset, sR(4)+yoffset];
            if ~oculusFlag
                srcRect = srcRectTemp;
            else
                srcRect = [srcRectTemp; srcRectTemp];
            end
    
%             if vbl<dtrendtime
% % This is the beginning of the stimulus, when the optical DTR has to be 
% % white.
% 
% % Draw grating texture, rotated by "angle".
% % Then it draws the gaussian mask.
% % Finally, it draws the optical DTR for Arduino.
%                 DtrTexture = TexStruct.DtrOnMask;
%             else
% % This is the grating when the optical DTR has to be black.
%                 DtrTexture = TexStruct.DtrOffMask;
%             end
            
            if mod(RelVbl,fullp)<p
% This means we are in the first half of a full period, which is the 
% checkerboard number one.
                GratingTexture = TexStruct.GratingOne;
            else
% Otherwise, we are in checkerboard number two.
                GratingTexture = TexStruct.GratingTwo;
            end

            
%             Screen('DrawTextures', app.w,...
%                 [GratingTexture, TexStruct.RectangleMask, DtrTexture],...
%                 [sR', srcRect', sR'],...
%                 [sR', dstRect', sR']);
            Screen('DrawTextures', app.w,...
                [GratingTexture, TexStruct.RectangleMask, TexStruct.DtrOffMask],...
                [sR', srcRect', sR'],...
                [sR', dstRect', sR']);

            vbl = Screen('Flip', app.w);
        end        
        
        timestamps(2*i) = vbl; % The last vbl acquired.
        Screen('FillRect', app.w, BaselineColorDtrOff, BaselineScreen);
        Screen('Flip', app.w);
        i=i+1;
    end
    WaitSecs(Bt);
%                 Is closing the textures really necessary?
    Screen('Close',TexStruct.GratingOne)
    Screen('Close',TexStruct.GratingTwo)
    Screen('Close',TexStruct.RectangleMask)
    Screen('Close',TexStruct.DtrOnMask)
    Screen('Close',TexStruct.DtrOffMask)
%--------------------------------------------------------------------------
    
    if OneScreenFlag
        CloseScreen
    end

%             Log writing.
    timestamps = timestamps - timZero;
end

function GratingStruct = CreateGratings(app, Blumi, Slumi, Glumi, f,...
    RectangleSizePx, Angle, oculusFlag, ard_flag)
%             this function creates the grid texture (either square of sinusoidal grid)
%             of frequency f and the Gaus mask of size GaussSize
%             The original outputs were [gratingsize, visiblesize, gratingtex,
%             masktex].
%             Right now:
%             Glumi is the average luminance of the stimulus: (Slumi+Blumi)/2
%             Contrast 'inc'rement range for given white and gray values: (Slumi-Blumi)/2
%             f is the spatial frequency (in terms of cycles/pixel)
%             gridType is 1 is 1 if the grid is sinusoidal. 0 for square-wave grid.
%             MaskFlag 1 means that gaussian mask is applied to the stimulus.
%             GaussSize is the size of gaussian mask in pixels.
    sR = app.screenRect;
    
%     FOR THE TIME BEING, THIS IS DISABLED. TO BE ENABLED AGAIN AFTER
%     CORRECTION
%     if oculusFlag
% %         The X dimension is halved.
%         sR(3) = app.screenRect(3)/2;
%     end

    % Calculate parameters of the grating:

    % First we compute the number of pixels for each side of a square,
    % which is the half of the size of a cycle in pixels (1/f).
    side = ceil(1/(2*f));
    
%     Remember: the x-dimension of the screen is sR(3), the y-dimension is
%     sR(4).
    
% Create a single cycle, composed of a black (zeros) square and a white
% (ones) square in x-dimension and a white square and a black square in
% y-dimension.
    SingleCycle = [false(side),true(side);true(side),false(side)];
    LogicCheck = repmat(SingleCycle, ceil(sR(4)/(2*side)), ceil(sR(3)/(2*side)));
    LogicCheck = LogicCheck(1:sR(4),1:sR(3));
    
    GratingOne = ones(sR(4), sR(3)) .* Blumi;
    GratingTwo = GratingOne;
    
    GratingOne(LogicCheck) = Slumi;
    GratingTwo(~LogicCheck) = Slumi;
        
%     Now the masks
%                         The function is 0 at
%                 the center of the screen (transparent) and goes up to 255
%                 (opaque).

%     rectmask is an opaque mask with a transparent rectangle at the
%     center. At each sides of the transparent rectangle are two opaque
%     regions as large as the largest dimension of the screen.

    if Angle == 0 || Angle == 180
        rectmask = zeros(sR(4), 2*sR(3), 2);
        rectmask(:,:,1) = Glumi; % everything is set to gray.
        rectmask(:,:,2) = 255; % everything is set to opaque.
% Then, only the vertical rectangle is set to transparent (alpha = 0).
        rectmask(:, sR(3)+1-RectangleSizePx/2 : sR(3)+RectangleSizePx/2, 2) = 0;
    else
        rectmask = zeros(2*sR(4) + RectangleSizePx, sR(3), 2);
        rectmask(:,:,1) = Glumi; % everything is set to gray.
        rectmask(:,:,2) = 255; % everything is set to opaque.
% Then, only the horizontal rectangle is set to transparent (alpha = 0).
        rectmask(sR(4)+1-RectangleSizePx/2 : sR(4)+RectangleSizePx/2, :, 2) = 0;
    end

        
    %             OPTICAL DTR PREPARATION
    %             The mask for the optical DTR is prepared anyway, but it stays
    %             transparent (alpha=0) if the optical DTR is not checked on
    %             the GUI.
    mask_on = zeros(sR(4), sR(3), 2);
    mask_on(:, :, 1) = app.white; % white everywhere
    mask_off = zeros(sR(4), sR(3), 2); %black everywhere
    %             Only if the optical DTR is checked, the alpha channel is made
    %             opaque only where the optical DTR should appear.
    if ard_flag && app.HermesSerialFlag
        mask_on(app.HermesRect(2)+1:app.HermesRect(4), app.HermesRect(1)+1:app.HermesRect(3), 2) = 255; %255 is opaque
        mask_off(app.HermesRect(2)+1:app.HermesRect(4), app.HermesRect(1)+1:app.HermesRect(3), 2) = 255; %255 is opaque
    end

    %             Cast grating, gaussmask and mask_on mask_off to the correct
    %             screen bit depth (usually 8 bit).
    GratingOne = cast(GratingOne, app.ScreenBitDepth);
    GratingTwo = cast(GratingTwo, app.ScreenBitDepth);
    rectmask = cast(rectmask, app.ScreenBitDepth);
    mask_on = cast(mask_on, app.ScreenBitDepth);
    mask_off = cast(mask_off, app.ScreenBitDepth);
    
    %             Now all the gratings (including the masks) are passed to a
    %             structure called GratingStruct, which is the function output.
    GratingStruct.GratingOne = GratingOne;
    GratingStruct.GratingTwo = GratingTwo;
    GratingStruct.RectangleMask = rectmask;
    GratingStruct.DtrOnMask = mask_on;
    GratingStruct.DtrOffMask = mask_off;
end

function TexStruct = CreateTextures(app, GratingStruct)
    TexStruct.GratingOne = Screen('MakeTexture', app.w, GratingStruct.GratingOne);
    TexStruct.GratingTwo = Screen('MakeTexture', app.w, GratingStruct.GratingTwo);
    TexStruct.RectangleMask = Screen('MakeTexture', app.w, GratingStruct.RectangleMask);
    TexStruct.DtrOnMask = Screen('MakeTexture', app.w, GratingStruct.DtrOnMask);
    TexStruct.DtrOffMask = Screen('MakeTexture', app.w, GratingStruct.DtrOffMask);
end
