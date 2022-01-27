

%             OPTICAL DTR PREPARATION
    %             The mask for the optical DTR is prepared anyway, but it stays
    %             transparent (alpha=0) if the optical DTR is not checked on
    %             the GUI.
    mask_on = zeros(sR(4), sR(3), 2);
    mask_on(:, :, 1) = master.white; % white everywhere
    mask_off = zeros(sR(4), sR(3), 2); %black everywhere
    %             Only if the optical DTR is checked, the alpha channel is made
    %             opaque only where the optical DTR should appear.
    if ard_flag
        mask_on(master.HermesRect(2)+1:master.HermesRect(4), master.HermesRect(1)+1:master.HermesRect(3), 2) = 255; %255 is opaque
        mask_off(master.HermesRect(2)+1:master.HermesRect(4), master.HermesRect(1)+1:master.HermesRect(3), 2) = 255; %255 is opaque
    end

    %             Cast grating, gaussmask and mask_on mask_off to the correct
    %             screen bit depth (usually 8 bit).
    grating = cast(grating, master.ScreenBitDepth);
    gaussmask = cast(gaussmask, master.ScreenBitDepth);
    mask_on = cast(mask_on, master.ScreenBitDepth);
    mask_off = cast(mask_off, master.ScreenBitDepth);

% Init framecounter to zero and take initial timestamp:
    count = 0;    
    tstart = GetSecs;
    n=100;
    
    % Run noise image drawing loop for 1000 frames:
    while count < n
        % Generate and draw 'numRects' noise images:
            % Compute noiseimg noise image matrix with Matlab:
            % Normally distributed noise with mean 128 and stddev. 50, each
            % pixel computed independently:
            noiseimg=(50*randn(master.screenRect(4),master.screenRect(3)) + 128);

            % Convert it to a texture 'tex':
            tex=Screen('MakeTexture',  master.w, noiseimg);

            % Draw the texture into the screen location defined by the
            % destination rectangle 'dstRect(i,:)'. If dstRect is bigger
            % than our noise image 'noiseimg', PTB will automatically
            % up-scale the noise image. We set the 'filterMode' flag for
            % drawing of the noise image to zero: This way the bilinear
            % filter gets disabled and replaced by standard nearest
            % neighbour filtering. This is important to preserve the
            % statistical independence of the noise pixels in the noise
            % texture! The default bilinear filtering would introduce local
            % correlations when scaling is applied:
            Screen('DrawTexture',  master.w, tex, master.screenRect, master.screenRect, [], 0);

            % After drawing, we can discard the noise texture.
            Screen('Close', tex);
        
        % Done with drawing the noise patches to the backbuffer: Initiate
        % buffer-swap. If 'asyncflag' is zero, buffer swap will be
        % synchronized to vertical retrace. If 'asyncflag' is 2, bufferswap
        % will happen immediately -- Only useful for benchmarking!
        asyncflag = 0;
        Screen('Flip', master.w, 0, 1, asyncflag);

        % Increase our frame counter:
        count = count + 1;
    end

    % We're done: Output average framerate:
    telapsed = GetSecs - tstart
    updaterate = count / telapsed