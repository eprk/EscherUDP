function time_zero = BaselinePresent(w,BaselineRect,BaselineColor,...
    BaselineColor_ttl,ard_flag,baseline_ttl,optDtrTime)
                                    %app.w 

if ard_flag && baseline_ttl
    % Baseline with TTL ON
    Screen('FillRect', w, BaselineColor_ttl, BaselineRect)
    Screen('Flip', w);  % with equiluminant gray.
    % Let's acquire the starting time.
    time_zero = WaitSecs(0);

    % Baseline with TTL OFF
    Screen('FillRect', w, BaselineColor, BaselineRect)
    Screen('Flip', w,time_zero+optDtrTime);  % with equiluminant gray.        
else
    % Baseline (either with TTL OFF or without ttl)
    Screen('FillRect', w, BaselineColor, BaselineRect)
    Screen('Flip', w);  % with equiluminant gray.
    % Let's acquire the starting time.
    time_zero = WaitSecs(0);
end