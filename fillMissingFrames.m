function [complete, varargout] = fillMissingFrames(movie, frameCounter, varargin)

%FILLMISSINGFRAMES add missing frames to a movie
%
% complete = FILLMISSINGFRAMES(movie, frameCounter)
%
%     arguments
%         movie {mustBeNumeric}
%         frameCounter {mustBeInteger}
%         varargin
%     end


% arguments parsing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p = inputParser;
addRequired(p,'movie',@(x)(isnumeric(x)&&length(size(x))==3))
addRequired(p,'frameCounter',@(x)(mustBeInteger(x)))
addOptional(p,'timestamps',[])
parse(p,movie,frameCounter,varargin{:})
parsed = p.Results;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 

% check if there are missing frames
frameIncr = diff(frameCounter);
missingI = find(frameIncr>1); % indici degli incrementi >1, cioè dopo questi indici manca uno o più frame
missingN = frameIncr(missingI)-1; % quanti frame+1 mancano all'indice missingI
missingFrames = sum(missingN); % quanti frame mancano in totale nella serie

if missingFrames % rimettiamoli
    % array di celle.
    tmp = cell(2,numel(missingI));
    if ~isempty(parsed.timestamps)
        tmptstamps = cell(2,numel(missingI));
    end
    % loop over the missing frames
    starti=1;

    for iMissing = 1:length(missingI)
        stopi=missingI(iMissing); % fine del primo "blocco" di frame che sono ok
        tmp{1,iMissing} = movie(:,:,starti:stopi); % mettiamo questo blocco nella cella della prima riga
        filler = mean(cat(3,movie(:,:,stopi),movie(:,:,stopi+1)),3);
        %                             tmp{2,iMissing} = nan(ny,nx,missingN(iMissing)-1);
        % abbiamo ottenuto il frame "tappabuco" mediando i due
        % frame adiacenti a quello (o quelli) mancanti.
        % rimpiazziamoli ripetendo questo tappabuco tante volte
        % quanti sono i frame mancanti
        tmp{2,iMissing} = repmat(filler,1,1,missingN(iMissing));

        % the same for timestamps
        if ~isempty(parsed.timestamps)
            tmptstamps{1,iMissing} = parsed.timestamps(starti:stopi);
%             tmptstamps{2,iMissing} = linspace(parsed.timestamps(stopi),parsed.timestamps(stopi+1),missingN(iMissing))';
            gap = parsed.timestamps(stopi+1) - parsed.timestamps(stopi);
            tmptstamps{2,iMissing} = ((1:missingN(iMissing))*gap/(missingN(iMissing)+1) + parsed.timestamps(stopi))';
        end
        starti=missingI(iMissing)+1;
    end

    % concatenate the movie blocks
    tobeconc = [tmp{:},{movie(:,:,starti:end-missingFrames)}];
    complete = cat(3,tobeconc{:});
    % concatenate the timestamps blocks too
    if ~isempty(parsed.timestamps)
        tobeconctstamps = [tmptstamps{:},{parsed.timestamps(starti:end-missingFrames)}];
        completetstamps = cat(1,tobeconctstamps{:});
%         %%% for to debug
%         tmp = cat(1,tobeconctstamps{1},tobeconctstamps{2});
%         for i = 3:length(tobeconctstamps)-2
%         tmp = cat(1,tmp, tobeconctstamps{i});
%         end 
    end

   

else
    % no missing frames! Leave the movie and the timestamps as they are
    complete = movie;
    if ~isempty(parsed.timestamps)
        completetstamps = parsed.timestamps;
    end
end

% assign optional outputs
if nargout>1
    varargout{1} = missingFrames;
end

if nargout>2
    varargout{2} = completetstamps;
end

end