function timestamps = GridPresent(app,ParameterVector)
    [Glumi,inc,sF,gridType,Angle,dS,MaskFlag,GaussSize,Bt,PreG,GridT,...
        PostG,n,dark_bsl,PcoWhileStimFlag,OneScreenFlag,CalibrationFlag,...
        oculusFlag,ard_flag,optDtrTime] = ParameterVector{:};
    
    if OneScreenFlag
        OpenScreen(app, Glumi)
    end
    
% In case PCO camera is used to record while stimulating, the PreG baseline
% is set with the same duration as the GridT.
% PostG time is just the same.
    
% The parameter sF is the spatial frequency in cycles/degree.
% The spatial frequency of the stimulus in cycles/pixel is calculated.
    f = app.OnePxAngle*sF;
    
    %             The stimulus has to be prepared BEFORE the conversion to the
    %             calibrated look up table
    %             ENRICO 2018/05/02 Let's prepare the gratings and masks in
    %             advance
    GratingStruct = CreateGratings(app, Glumi, inc, f, gridType,...
        MaskFlag, GaussSize,CalibrationFlag,oculusFlag,ard_flag);

    %             This calibration shouldn't be performed before this point, because
    %             the luminance is needed as a non-corrected value for the
    %             CreateGratings function.
    Standby_lumi = app.StandbyL.Value;
    if CalibrationFlag
        [Glumi,~] = Lumi2Escher(Glumi,app.white,app.ScreenFunc);
        [Standby_lumi,~] = Lumi2Escher(Standby_lumi,app.white,app.ScreenFunc);
        
    end
    Glumi = Glumi*app.white;
    Standby_lumi = app.white*Standby_lumi;
    
    if ard_flag % prepare the additional rectangle for optical synch signal   
        if dark_bsl
            BaselineColor = cast([[Standby_lumi;Standby_lumi;Standby_lumi], [0;0;0]], app.ScreenBitDepth);
        else
            BaselineColor = cast([[Glumi;Glumi;Glumi], [0;0;0]], app.ScreenBitDepth);
        end
         BaselineScreen = [app.screenRect; app.HermesRect]';
         
% In case that PCO recording is used, the baseline also needs to trigger
% Hermes. So BaselineColor will contain the baseline with a Hermes
% rectangle that is ON (white), whereas BaselineColorOff will contain a
% Hermes rectangle that is OFF (black).
        if PcoWhileStimFlag
            BaselineColorOff = BaselineColor;
            if dark_bsl
                BaselineColor = cast([[Standby_lumi;Standby_lumi;Standby_lumi], ...    
                    [app.white;app.white;app.white]], app.ScreenBitDepth);
            else
                BaselineColor = cast([[Glumi;Glumi;Glumi], ...
                    [app.white;app.white;app.white]], app.ScreenBitDepth);
            end
        end
    else
        if dark_bsl
            BaselineColor = cast(Standby_lumi, app.ScreenBitDepth);
        else
            BaselineColor = cast(Glumi, app.ScreenBitDepth);
        end
        BaselineScreen = app.screenRect;
    end
    
%             Before starting we need to compute some parameters needed for
%             the animation of the grating.
%             First of all, the total duration of one period is computed.
    totPeriod = PreG+GridT+PostG;
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
%             Recompute p, this time without the ceil() operation from above.
%             Otherwise we will get wrong drift speed due to rounding errors!
    p = 1/f;  % pixels/cycle
%             Translate requested speed of the grating (in cycles per second) into
%             a shift value in "pixels per frame", for given waitduration: This is
%             the amount of pixels to shift our srcRect "aperture" in horizontal
%             directionat each redraw:
    shiftperframe = dS * p * waitduration;
%             Prepare the grating textures in advance.
    TexStruct = CreateTextures(app, GratingStruct);
%     After creating the textures, if the VR headset is being used, we have
%     to double the texture and the angle
    sR = app.screenRect;
% Save the dimension of the grating mask:
    LargestDim = ceil(sqrt(sR(3)^2+sR(4)^2));
    
    if ~oculusFlag
%         dstRect = CenterRect([0, 0, ceil(sqrt(sR(3)^2+sR(4)^2)), ceil(sqrt(sR(3)^2+sR(4)^2))], sR);
        dstRect = [0,0,LargestDim,LargestDim];
    else
        Angle = [Angle, Angle];
        TexStruct.Grating = [TexStruct.Grating, TexStruct.Grating];
        
% Change the sR
        sR(3) = app.screenRect(3)/2;
        sR2 = sR;
        sR2([1 3]) = sR2([1 3]) + app.screenRect(3)/2;
        
%         dstRectTemp = [0, 0, ceil(sqrt(sR(3)^2+sR(4)^2)), ceil(sqrt(sR(3)^2+sR(4)^2))];
%         dstRect = [CenterRect(dstRectTemp, sR); CenterRect(dstRectTemp, sR2)];
        
        dstRect = [[0,0,LargestDim,LargestDim]; [0,0,LargestDim,LargestDim]];
    end
    
        
% This vector contains two timestamps for each period, one for the
% beginning of the grid and one for the end.
    timestamps = NaN(1,2*n);
% Load the WaitSecs function.
    WaitSecs(0);
    
% START OF THE ACTUAL STIMULATION
% ENRICO. 26/08/2019 Added an initial delay

    if PcoWhileStimFlag
% If PCO is used, we need to present BaselineColorOff here, otherwise an
% optical DTR will be shown.
        Screen('FillRect', app.w, BaselineColorOff, BaselineScreen);
    else
% If PCO is not used, we present BaselineColor here, which will have an OFF
% optical DTR.
        Screen('FillRect', app.w, BaselineColor, BaselineScreen);
    end
    Screen('Flip', app.w);  % bring the buffered screen to forefront
    timZero = WaitSecs(0);
    timOffset = timZero + Bt;
    
    TrialStartTime = timOffset+(0:n-1)*totPeriod;
    BaseDtrEndTime = timOffset+(0:n-1)*totPeriod+optDtrTime; % end of the optical DTR of the baseline
    timStart = timOffset+(0:n-1)*totPeriod+PreG; % start of the grid
    dtrendtime = timOffset+(0:n-1)*totPeriod+PreG+optDtrTime; % end of optical DTR for Hermes
    timEnd = timOffset+(0:n-1)*totPeriod+PreG+GridT; % end of the grid
        
    i = 1;
    while i<=n
% First off, fill the screen with uniform gray background for the 
% pre-stimulus baseline.
        Screen('FillRect', app.w, BaselineColor, BaselineScreen);
        Screen('Flip', app.w, TrialStartTime(i));
        
% Only if PCO is used, an optical DTR is sent to Hermes, so that also the
% baseline before stimulation can be recorded.
% The next code turns OFF this optical DTR.
        if PcoWhileStimFlag
            Screen('FillRect', app.w, BaselineColorOff, BaselineScreen);
            Screen('Flip', app.w, BaseDtrEndTime(i));
        end
        
% This flip is at the beginning of the Grid presentation, right after the
% pre-grid period. This could be substituted by just a WaitSecs function,
% since here we only need to take the time, not to actually present a
% screen. So I commented it and substituted it.
%         vbl = Screen('Flip', app.w, timStart(i));  % bring the buffered screen to forefront
        vbl =  WaitSecs('UntilTime', timStart(i));
        timestamps(2*i-1) = vbl;
        
        ii=0;
% Animationloop:
        while vbl < timEnd(i)
            
%                 Shift the grating by "shiftperframe" pixels per frame:
%                 the modulo operation makes sure that our "aperture" will snap
%                 back to the beginning of the grating, once the border is reached.
%                 Fractional values of 'xoffset' are fine here. The GPU will
%                 perform proper interpolation of color values in the grating
%                 texture image to draw a grating that corresponds as closely as
%                 technical possible to that fractional 'xoffset'. GPU's use
%                 bilinear interpolation whose accuracy depends on the GPU at hand.
%                 Consumer ATI hardware usually resolves 1/64 of a pixel, whereas
%                 consumer NVidia hardware usually resolves 1/256 of a pixel. You
%                 can run the script "DriftTexturePrecisionTest" to test your
%                 hardware...
            xoffset = mod(ii*shiftperframe, p);
            
%                 Define shifted srcRect that cuts out the properly shifted rectangular
%                 area from the texture: We cut out the range 0 to visiblesize in
%                 the vertical direction although the texture is only 1 pixel in
%                 height! This works because the hardware will automatically
%                 replicate pixels in one dimension if we exceed the real borders
%                 of the stored texture. This allows us to save storage space here,
%                 as our 2-D grating is essentially only defined in 1-D:
            srcRectTemp = [xoffset, 0, LargestDim+xoffset, LargestDim];
            if ~oculusFlag
                srcRect = srcRectTemp;
            else
                srcRect = [srcRectTemp; srcRectTemp];
            end
    
            if vbl<dtrendtime(i)
%                     This is the beginning of the stimulus, when the
%                     optical DTR has to be white.

%                     Draw grating texture, rotated by "angle".
%                     Then it draws the gaussian mask.
%                     Finally, it draws the optical DTR for Arduino.
%                 Screen('DrawTextures', app.w,...
%                     [TexStruct.Grating, TexStruct.GaussMask, TexStruct.DtrOnMask],...
%                     [srcRect', sR', sR'],...
%                     [dstRect', sR', sR'], [Angle, 0, 0],[],[],[],[],kPsychUseTextureMatrixForRotation);
                Screen('DrawTextures', app.w,...
                    [TexStruct.Grating, TexStruct.GaussMask, TexStruct.DtrOnMask],...
                    [srcRect', sR', sR'],...
                    [dstRect', sR', sR'], [Angle, 0, 0],[],[],[],[],0);
                
            else
%                     This is the grating when the optical DTR has to be
%                     black.
                
%                 Screen('DrawTextures', app.w,...
%                     [TexStruct.Grating, TexStruct.GaussMask, TexStruct.DtrOffMask],...
%                     [srcRect', sR', sR'],...
%                     [dstRect', sR', sR'], [Angle, 0, 0],[],[],[],[],kPsychUseTextureMatrixForRotation);
                Screen('DrawTextures', app.w,...
                    [TexStruct.Grating, TexStruct.GaussMask, TexStruct.DtrOffMask],...
                    [srcRect', sR', sR'],...
                    [dstRect', sR', sR'], [Angle, 0, 0],[],[],[],[],0);

            end

%                 Flip 'waitframes' monitor refresh intervals after last redraw.
%                 Providing this 'when' timestamp allows for optimal timing
%                 precision in stimulus onset, a stable animation framerate and at
%                 the same time allows the built-in "skipped frames" detector to
%                 work optimally and report skipped frames due to hardware
%                 overload:
            vbl = Screen('Flip', app.w, vbl + (waitframes - 0.5) * app.ifi);

%                 ENRICO. Removed.
%                 % Abort function if any key is pressed:
%                 if KbCheck
%                     break
%                 end
            ii=ii+1;
        end
        timestamps(2*i) = vbl; % The last vbl acquired.
        
        if PcoWhileStimFlag
% If PCO is used, we need to present BaselineColorOff here, otherwise an
% optical DTR will be shown.
            Screen('FillRect', app.w, BaselineColorOff, BaselineScreen);
        else
% If PCO is not used, we present BaselineColor here, which will have an OFF
% optical DTR.
            Screen('FillRect', app.w, BaselineColor, BaselineScreen);
        end
        Screen('Flip', app.w);
        i=i+1;
    end
    WaitSecs(Bt);
%                 Is closing the textures really necessary?
    Screen('Close',TexStruct.Grating)
    Screen('Close',TexStruct.GaussMask)
    Screen('Close',TexStruct.DtrOnMask)
    Screen('Close',TexStruct.DtrOffMask)
%--------------------------------------------------------------------------
    
    if OneScreenFlag
        CloseScreen
    else
        % Set back stadby luminance
        if ard_flag
            BaselineColor = cast([[Standby_lumi;Standby_lumi;Standby_lumi], [0;0;0]], app.ScreenBitDepth);
            cellRects = [app.screenRect; app.HermesRect]';
        else
            BaselineColor = cast(Standby_lumi, app.ScreenBitDepth);
            cellRects = app.screenRect;
        end
        Screen('FillRect', app.w, BaselineColor, cellRects); % paints the rectangle (entire screen)
        Screen('Flip', app.w);
    end
    
    
    

    
    
    
%             Log writing.
    timestamps = timestamps - timZero;
end

function GratingStruct = CreateGratings(app, Glumi, inc, f, gridType, MaskFlag, GaussSize,CalibrationFlag,oculusFlag,ard_flag)
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
    if oculusFlag
%         The X dimension is halved.
        sR(3) = app.screenRect(3)/2;
    end

    % Calculate parameters of the grating:

    % First we compute pixels per cycle, rounded up to full pixels, as we
    % need this to create a grating of proper size below:
    p = ceil(1/f);
    
    %             ENRICO 20190504 I removed this
    %             % This is the visible size of the grating. It is twice the half-width
    %             % of the texture plus one pixel to make sure it has an odd number of
    %             % pixels and is therefore symmetric around the center of the texture:
    %             visiblesize = 2*texsize+1;

    % Create one single static grating image:
    %
    % We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
    % define the whole grating! If the 'srcRect' in the 'Drawtexture' call
    % below is "higher" than that (i.e. visibleSize >> 1), the GPU will
    % automatically replicate pixel rows. This 1 pixel height saves memory
    % and memory bandwith, ie. it is potentially faster on some GPUs.
    %
    % However it does need 2 * texsize + p columns, i.e. the visible size
    % of the grating extended by the length of 1 period (repetition) of the
    % sine-wave in pixels 'p':

    %             ENRICO 20190504 Why meshgrid here? A vector is enough
    %             x = meshgrid(-texsize:texsize + p, 1);
    %             The dimension is the length of the diagonal of the screen
    %             (calculated by Pythagorean theorem. Plus one period, to cover
    %             all the screen during the drifting.
    x = 0:ceil(sqrt(sR(3)^2+sR(4)^2))+p;

% Compute actual cosine grating:
    if gridType == 1
% cosine function of frequency f: y = cos(2*pi*f*x)
% Luminance is spatially determined by a cosine function of period f and
% amplitude inc, with an offset of Glumi:
        grating = Glumi + inc*cos(6.2832*f*x);
    else
% Square-wave stimulus
        GridUp = Glumi + inc;
        GridDown = Glumi - inc;
        grating = zeros(size(x))+GridDown;
        grating(cos(6.2832*f*x)>0) = GridUp;
    end

    if CalibrationFlag
        grating = arrayfun(@(x) Lumi2Escher(x,app.white,app.ScreenFunc), grating, 'un',1);

        %                 You cannot convert the Glumi value before this point
        %                 because you need the uncalibrated value for the
        %                 generation of the stimulus.
        [Glumi,~] = Lumi2Escher(Glumi,app.white,app.ScreenFunc);
    end
    Glumi = app.white * Glumi;
    %             Convert grating to values from 0 to app.white (usually 255)
    grating = grating*app.white;

%             Here it could be possible not to execute this block and let the graphic card repeat the grating.
%             Instead, we create a full 2-D grating.
        %                 Vertically stacks the row vector "grating" a number of
        %                 times equal to its length. "grating" becomes a square
        %                 matrix.
    grating = repmat(grating, length(grating), 1);

    % Create a single gaussian transparency mask and store it to a texture:
    % The mask must have the same size as the visible size of the grating
    % to fully cover it. Here we must define it in 2 dimensions and can't
    % get easily away with one single row of pixels.
    %
    % We create a  two-layer texture: One unused luminance channel which we
    % just fill with the same color as the background color of the screen
    % 'gray'. The transparency (aka alpha) channel is filled with a
    % gaussian (exp()) aperture mask.

    % from here to ...

    %             ENRICO 20190504 Let's try to change the gauss mask size.
    %             gaussmask = ones(2*texsize+1, 2*texsize+1, 2) * Glumi;
    %             [x,y] = meshgrid(-1*texsize:1*texsize,-1*texsize:1*texsize);
    gaussmask = Glumi * ones(sR(4), sR(3), 2);
    [x,y] = meshgrid(-(sR(3)-1)/2 : (sR(3)-1)/2,...
        -(sR(4)-1)/2 : (sR(4)-1)/2);
    %             Now the gaussian mask has the same dimension as the screen.

    if MaskFlag
        %                 ENRICO 20190504 Here, a 2-D Gaussian function is used, to
        %                 fill the alpha channel of gaussmask. The function is 0 at
        %                 the center of the screen (transparent) and goes up to 255
        %                 as it goes further away from the center (opaque).
        %                 The sigma (standard deviation) of the Gaussian function
        %                 is sqrt(2)*GaussSize. This means that at the distance
        %                 GaussSize, the function is 63% of the maximum (160/255).
        gaussmask(:, :, 2) = 255 * (1 - exp(-((x/GaussSize).^2)-((y/GaussSize).^2)));

    else
        gaussmask(:, :, 2) = 0;
    end
    %             Now:
    %             gaussmask(:,:,1) is gray everywhere.
    %             gaussmask(:,:,2) has value of 255 where the mask is opaque. While
    %             it's 0 where the mask is transparent.


    %             OPTICAL DTR PREPARATION
    %             The mask for the optical DTR is prepared anyway, but it stays
    %             transparent (alpha=0) if the optical DTR is not checked on
    %             the GUI.
    mask_on = zeros(sR(4), sR(3), 2);
    mask_on(:, :, 1) = app.white; % white everywhere
    mask_off = zeros(sR(4), sR(3), 2); %black everywhere
    %             Only if the optical DTR is checked, the alpha channel is made
    %             opaque only where the optical DTR should appear.
    if ard_flag
        mask_on(app.HermesRect(2)+1:app.HermesRect(4), app.HermesRect(1)+1:app.HermesRect(3), 2) = 255; %255 is opaque
        mask_off(app.HermesRect(2)+1:app.HermesRect(4), app.HermesRect(1)+1:app.HermesRect(3), 2) = 255; %255 is opaque
    end

    %             Cast grating, gaussmask and mask_on mask_off to the correct
    %             screen bit depth (usually 8 bit).
    grating = cast(grating, app.ScreenBitDepth);
    gaussmask = cast(gaussmask, app.ScreenBitDepth);
    mask_on = cast(mask_on, app.ScreenBitDepth);
    mask_off = cast(mask_off, app.ScreenBitDepth);
    
    %             Now all the gratings (including the masks) are passed to a
    %             structure called GratingStruct, which is the function output.
    GratingStruct.Grating = grating;
    GratingStruct.GaussMask = gaussmask;
    GratingStruct.DtrOnMask = mask_on;
    GratingStruct.DtrOffMask = mask_off;
end

function TexStruct = CreateTextures(app, GratingStruct)
    TexStruct.Grating = Screen('MakeTexture', app.w, GratingStruct.Grating);   % about 2.5 ms
    TexStruct.GaussMask = Screen('MakeTexture', app.w, GratingStruct.GaussMask);
    TexStruct.DtrOnMask = Screen('MakeTexture', app.w, GratingStruct.DtrOnMask);
    TexStruct.DtrOffMask = Screen('MakeTexture', app.w, GratingStruct.DtrOffMask);
end
