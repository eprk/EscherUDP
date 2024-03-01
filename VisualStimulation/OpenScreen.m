function OpenScreen(app,background)
    %[w, ScreenRect, white, black, gray, ifi] function OpenScreen
    % function OpenScreen
    % ___________________________________________________________________
    %
    % Open and initialize the stimulus screen, This should run only once as the
    % program starts up

    % HISTORY
    %  08/01/2011 gmr    adapted for Esher

    %             This should be 1 for general use. Synchronization is less
    %             reliable but the execution is more robust
%     Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'SkipSyncTests', 0);
    
    try
        % This script calls Psychtoolbox commands available only in OpenGL-based
        % versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
        % only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
        % an error message if someone tries to execute this script on a computer without
        % an OpenGL Psychtoolbox
        AssertOpenGL;

        % Get the list of screens and choose the one with the highest screen number.
        % Screen 0 is, by definition, the display with the menu bar. Often when
        % two monitors are connected the one without the menu bar is used as
        % the stimulus display.  Chosing the display with the highest dislay number is
        % a best guess about where you want the stimulus displayed.
        screens = Screen('Screens');
        if length(screens)==1 && ~app.OneScreenMode_ck.Value
%                     If there is only one screen and OneScreenMode is not
%                     checked, then no screen is opened.
            warning('Only one screen present!')
            return
        end
        if app.OneScreenMode_ck.Value
            if numel(screens) == 1
                screenNumber = screens;
            else
                screenNumber = min(screens)+1;
            end
        else
            screenNumber = max(screens);
        end

        % Find the color values which correspond to white and black: Usually
        % black is always 0 and white 255, but this rule is not true if one of
        % the high precision framebuffer modes is enabled via the
        % PsychImaging() commmand, so we query the true values via the
        % functions WhiteIndex and BlackIndex:
        app.white = WhiteIndex(screenNumber);
        app.black = BlackIndex(screenNumber);


%                 ENRICO. What is the purpose of this part? I commented it
%                 out and removed app.gray property.
%                 % Round gray to integral number, to avoid roundoff artifacts with some
%                 % graphics cards:
%                	app.gray = round((app.white+app.black)/2);
%                 % This makes sure that on floating point framebuffers we still get a
%                 % well defined gray. It isn't strictly necessary in this demo:
%                 if app.gray == app.white
%                   		app.gray = app.white / 2;
%                 end
%                 
%                 % Contrast 'inc'rement range for given white and gray values:
%                	inc = app.white-app.gray;
        if app.ApplydistortionCheckBox.Value
            [xPx, yPx] = Screen('WindowSize', screenNumber);
            app.screenRect = [0, 0, xPx, yPx];
% The .mat file created contains two variables: scaI (structure) and warptype (character vector).
            scal = FastDisplayUndistortionCSV(app, 'SphericalDistortionTmp.mat',screenNumber);
            
% Loaded calibration data from ASCII file distortion.csv.
% Name of calibration result file: distortionout.mat
% 
% You can apply the calibration in your experiment script by replacing your 
% win = Screen('OpenWindow', ...); command by the following sequence of 
% commands:
% 
% PsychImaging('PrepareConfiguration');
% PsychImaging('AddTask', 'LeftView', 'GeometryCorrection', 'distortionout.mat');
% win = PsychImaging('OpenWindow', ...);
% 
% This would apply the calibration to the left-eye display of a stereo setup.
% Additional options would be 'RightView' for the right-eye display of a stereo setup,
% or 'AllViews' for both views of a stereo setup or the single display of a mono
% setup.
% 
% The 'GeometryCorrection' call has a 'debug' flag as an additional optional parameter.
% Set it to a non-zero value for diagnostic output at runtime.
% E.g., PsychImaging('AddTask', 'LeftView', 'GeometryCorrection', 'distortionout.mat', 1);
% would provide some debug output when actually using the calibration at runtime.  

% If it is selected, use a distortion to take into account the spherical 
% distortion from the point of view of the mouse eye.
            PsychImaging('PrepareConfiguration');
%             PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', 'C:\Users\Enrico\AppData\Roaming\Psychtoolbox\GeometryCalibration\SphereCalibdata_0_1920_1080.mat');
            PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', 'SphericalDistortionTmp.mat');
            
            [app.w, app.screenRect] = PsychImaging('OpenWindow',screenNumber, background*app.white);
        else
            % Open a double buffered fullscreen window and set default background
            % color to gray:
            [app.w, app.screenRect] = Screen('OpenWindow',screenNumber, background*app.white);
        end
        
        % if drawmask
        % Enable alpha blending for proper combination of the gaussian aperture
        % with the drifting sine grating:
        Screen('BlendFunction', app.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        % end

        % Query maximum useable priorityLevel on this system:
        priorityLevel = MaxPriority(app.w); %#ok<NASGU>

        % We don't use Priority() in order to not accidentally overload older
        % machines that can't handle a redraw every 40 ms. If your machine is
        % fast enough, uncomment this to get more accurate timing.
%         Priority(priorityLevel);


        %                NEW Enrico 20190524
        %                According to the value in app.white, the ScreenBitDepth is set to
        %                either 8-bit unsigned integer or 16-bit unsigned integer.
        switch app.white
            case 255
                app.ScreenBitDepth = 'uint8';
            case 65535
                app.ScreenBitDepth = 'uint16';
            otherwise
                error(['Data type was not reckognized please check the code ' ...
                    'to include this data. White value is' str2double(app.white)])
        end

        % Query duration of one monitor refresh interval:
        app.ifi=Screen('GetFlipInterval', app.w);

        % Translate that into the amount of seconds to wait between screen
        % redraws/updates:

        % waitframes = 1 means: Redraw every monitor refresh. If your GPU is
        % not fast enough to do this, you can increment this to only redraw
        % every n'th refresh. All animation paramters will adapt to still
        % provide the proper grating. However, if you have a fine grating
        % drifting at a high speed, the refresh rate must exceed that
        % "effective" grating speed to avoid aliasing artifacts in time, i.e.,
        % to make sure to satisfy the constraints of the sampling theorem
        % (See Wikipedia: "Nyquist?Shannon sampling theorem" for a starter, if
        % you don't know what this means):
        waitframes = 1;

        % Translate frames into seconds for screen update interval:
        waitduration = waitframes * app.ifi;

        % Perform initial Flip to sync us to the VBL and for getting an initial
        % VBL-Timestamp as timing baseline for our redraw loop:
        vbl=Screen('Flip', app.w);
        
        if app.ApplydistortionCheckBox.Value
% Delete  temporary file.
            delete 'SphericalDistortionTmp.mat'
        end

    catch
        %this "catch" section executes in case of an error in the "try" section
        %above.  Importantly, it closes the onscreen window if its open.
        Screen('CloseAll');
        Priority(0);
        psychrethrow(psychlasterror);
    end %try..catch..
    
%     Let the app calculate the dimensions of Hermes cue.
    app.HermesRectCalc
%     And also the angular dimension of the angle subtended by a single
%     pixel.
    app.PixelAngleCalc
    
    % We're done!
