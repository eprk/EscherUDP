function [timestamps,interrupted] = MyFunction(app,ParameterVector)
    % The input variables are:
    % app, the handle for the app
    % ParameterVector, a cell array containing all the parameters
    [var1,var2,varN] = ParameterVector{:};
    
    
    % Prepare what you need here
    
    % If you need to convert luminance values to 0-255 values, use the
    % function Lumi2Escer.m
    
    % app is the handle to Escher (either Master or Slave). You can get any
    % of their property with get(app,'propertyName') or app.propertyName .
    
    
    % If your stimulus is compatible with "One Screen Mode", open the
    % screen first
    if OneScreenFlag
        OpenScreen(app, StandbyColor)
    end
    
    % allocate the vector of timestamps
    timestamps = nan(1,n_timestamps);
    
    % present initial baseline and save its timestamp.
    time_zero = BaselinePresent(w,BaselineRect,BaselineColor,...
            BaselineColor_ttl,ard_flag,baseline_ttl,optDtrTime);
    timestamps(1) = time_zero;
    
    % Stimulation loop
    i=1;
    interrupted = false;
    while i <= n_rounds && ~interrupted
        % check for pressed keys using the function "detectKeyboard"
        interrupted = detectKeyboard();
        
        % Prepare your stimulation here....
        
        % Every time you show a relevant stimulus, save its timestamp
        timestamps(1+f(i)) = Screen('Flip',app.w,time_of_stimulus(f(i)));
        
        i=i+1;
    end
    
    % Paints the rectangle (entire screen) with equiluminant gray.
    Screen('FillRect', app.w, StandbyColor, StandbyRect) % 
    t_end=Screen('Flip', app.w, timZero+Bt+2*n*p);
    timestamps(end)=t_end;
    
    if interrupted
        disp('STOPPED BY KEYBOARD')
    else
        % If you want to wait some time after the stimuls, do it here
    end
    
    if OneScreenFlag
        CloseScreen
    end

    % We always refer to timestamps relative to the presentation of the
    % first baseline. 
    timestamps = timestamps - time_zero;
