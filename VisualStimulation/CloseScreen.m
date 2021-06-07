function CloseScreen
    % function CloseScreen
    % ___________________________________________________________________
    %
    % Closes the OpenGL session and the buffered screen. Restores the prioriity level

    % HISTORY
    %  08/05/2011 gmr

    try
        % This script calls Psychtoolbox commands available only in OpenGL-based
        % versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
        % only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
        % an error message if someone tries to execute this script on a computer without
        % an OpenGL Psychtoolbox
        % AssertOpenGL;


        % following stuff to close the OpenGL session. To be transferred to
        % CloseScreen function
        % Restore normal priority scheduling in case something else was set
        % before:
        Priority(0);

        %The same commands wich close onscreen and offscreen windows also close
        %textures.
        Screen('CloseAll');

    catch
        %this "catch" section executes in case of an error in the "try" section
        %above.  Importantly, it closes the onscreen window if its open.
        Screen('CloseAll');
        Priority(0);
        psychrethrow(psychlasterror);
    end %try..catch..

    % We're done!
