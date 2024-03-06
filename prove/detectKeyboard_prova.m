function stop_flag = detectKeyboard_prova()
% ListenChar(2)

pause(2)
i=0;
stop_flag = false;
while ~stop_flag
    i=i+1;
    disp('i');
    pause(0.5)
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
    if keyIsDown
        keys = [KbName(find(keyCode))];
        if strcmp(strcat(keys{:}),"opst")
            stop_flag = true;
        end
    end
end

% ListenChar(0)

disp('STOPPED BY KEYBOARD')