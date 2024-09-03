

Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');
sn = max(screens);
[w, sr] = Screen('OpenWindow',sn, 0);


val = (0:0.05:1)';
mask = [0; 0; 1];
for i=1:numel(val)
    fprintf('Showing val %.3f\n',val(i))
    Screen('FillRect',w,[255; 255; 255].* mask.*val(i),sr);
    Screen('Flip',w);
    
    input('Press any key to go on','s');    
end
disp('the end')

Screen('CloseAll');