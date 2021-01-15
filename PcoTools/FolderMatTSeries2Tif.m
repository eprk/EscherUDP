function FolderMatTSeries2Tif(varargin)
%FOLDERMATTSERIES2TIF Convert all .mat files in a folder into .tif files.
%   FOLDERMATTSERIES2TIF Allows to choose the folder interactively and then
%   converts all .mat files inside to tif files.
%   FOLDERMATTSERIES2TIF(PATH) Converts all .mat files in specified "PATH"
%   to tif files.
%   FOLDERMATTSERIES2TIF(...,PARAM1,VAL1,PARAM2,VAL2,...) Specifies
%   parameters that control various characteristics of the conversion
%   process.
%   There can be two optional 'Name','Value' pairs:
%   'Parallelize' can be either 0 or 1 (default)
%   'Overwrite' can be either 0 (default) or 1
    

    if nargin > 0
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    [selpath, paramPairs] = parse_inputs(varargin{:});
    
    if isempty(selpath)
        selpath = uigetdir;
        if selpath == 0
            return
        end
    end

    % Check if Parallelize is 1 or 0
    index = find(ismember(lower(paramPairs(:)),lower('parallelize')) == 1);
    if ~isempty(index) %'Parallelize' name is used with imwrite
        for i = 1 : numel(index)
            if  paramPairs{index(i)+1} == 1
                Parallelize = 1;
            elseif paramPairs{index(i)+1} == 0
                Parallelize = 0;
            else
                error('Parallelize can only be either 1 or 0.')
            end
        end
    end
    
% Check if Parallelize is 1 or 0
    index = find(ismember(lower(paramPairs(:)),lower('parallelize')) == 1);
    if ~isempty(index) %'Parallelize' name is used
        for i = 1 : numel(index)
            if  paramPairs{index(i)+1} == 1
                Parallelize = 1;
            elseif paramPairs{index(i)+1} == 0
                Parallelize = 0;
            else
                error('Parallelize can only be either 1 or 0.')
            end
        end
    else
% The default value for Parallelize is 1.
        Parallelize = 1;
    end
    
% Check if Overwrite is 1 or 0
    index = find(ismember(lower(paramPairs(:)),lower('overwrite')) == 1);
    if ~isempty(index) %'Overwrite' name is used
        for i = 1 : numel(index)
            if  paramPairs{index(i)+1} == 1
                Overwrite = 1;
            elseif paramPairs{index(i)+1} == 0
                Overwrite = 0;
            else
                error('Overwrite can only be either 1 or 0.')
            end
        end
    else
% The default value for Overwrite is 0.
        Overwrite = 0;
    end
    
    
    listing = dir(selpath);
    MatImageList = {listing(~[listing.isdir]).name}';
    matches = regexpi(MatImageList,'.*[.]mat','match');
    matches = matches(~cellfun(@isempty,matches));
    
    CompleteInFileList = cellfun(@(x) strjoin([{selpath}, x], filesep), matches,'un',0);
    CompleteOutFileList = cellfun(@(x) [x(1:end-3), 'tif'], CompleteInFileList, 'un',0);
    
    if Overwrite == 0
% If it is the Overwrite option is not selected, then pre-existing files
% will not be considered in the conversion.
% Therefore they will be removed from the input file list.
        CompleteInFileList = CompleteInFileList(~isfile(CompleteOutFileList));
% And they will be removed from the output file list.
        CompleteOutFileList = CompleteOutFileList(~isfile(CompleteOutFileList));
    end
    FileNum = length(CompleteOutFileList);
    
    if Parallelize==1 && FileNum>2
        parfor i = 1:FileNum
            TmpLoadStruct = load(CompleteInFileList{i});
            
            for j = 1:size(TmpLoadStruct.OutPcoStruct.Images, 3)
                if j == 1
                    imwrite(TmpLoadStruct.OutPcoStruct.Images(:,:,j), CompleteOutFileList{i}, 'tif','WriteMode','overwrite')
                else
                    imwrite(TmpLoadStruct.OutPcoStruct.Images(:,:,j), CompleteOutFileList{i}, 'tif','WriteMode','append')
                end
            end
        end
    else
        for i = 1:FileNum
            TmpLoadStruct = load(CompleteInFileList{i});
            
            for j = 1:size(TmpLoadStruct.OutPcoStruct.Images, 3)
                if j == 1
                    imwrite(TmpLoadStruct.OutPcoStruct.Images(:,:,j), CompleteOutFileList{i}, 'tif','WriteMode','overwrite')
                else
                    imwrite(TmpLoadStruct.OutPcoStruct.Images(:,:,j), CompleteOutFileList{i}, 'tif','WriteMode','append')
                end
            end
        end
    end
    disp('Done!')
end


%%%
%%% Function parse_inputs
%%%
function [selpath, paramPairs] = parse_inputs(varargin)
    
    selpath = '';
    paramPairs = {};
    
    if nargin==0
        return
    end
    
% If the number of input arguments is odd, the first one must be the
% folder.
    if rem(nargin,2) ~= 0
        selpath=varargin{1};
        if ~isfolder(selpath)
            error('Invalid folder name.')
        end
        pathidx = 1;
    else
        pathidx = 0;
    end
    
    if length(varargin) > pathidx
        paramPairs = varargin((pathidx + 1):end);
        
        % Do some validity checking on param-value pairs
        if rem(length(paramPairs), 2) ~= 0
            error(message('MATLAB:imagesci:imwrite:invalidSyntaxOrFormat',varargin{firstString + 1}));
        end

    end

    % Validate the 'Name' part in 'Name','Value' pairs.
    for k = 1:2:length(paramPairs)
% Parameter names have to be character arrays or strings and must be
% non-empty and scalar.
        validateattributes(paramPairs{k},{'char', 'string'},{'nonempty', 'scalartext'},'','PARAMETER NAME');
% They also have to be part of the parameter name list.
        if ~ismember(lower(paramPairs{k}),[{'parallelize'},{'overwrite'}])
            error([paramPairs{k},' is an invalid parameter name.'])
        end
    end
    
end
