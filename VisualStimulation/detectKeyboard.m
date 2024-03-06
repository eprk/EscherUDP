function stop_flag = detectKeyboard()
% pause(2)
% i=0;
stop_flag = false;
% while ~stop_flag
%     i=i+1;
%     disp('i');
%     pause(0.5)
    [keyIsDown, ~, keyCode, ~] = KbCheck();
    if keyIsDown
        keys = [KbName(find(keyCode))];
        if strcmp(strcat(keys{:}),"opst")
            stop_flag = true;
        end
    end
% end

% disp('STOPPED BY KEYBOARD')