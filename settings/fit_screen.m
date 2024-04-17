function [p,f] = fit_screen(x,y,fitFunction,varargin)

% if 'fitFunction' is the handle to a custom anonymous function, it must
% start as '@(param,x)', where x is the independent variable and p is a
% paramter or a vector of parameters.

% we want to output the text of a function of the input value only, where
% parameter values resulting from the fit are actually printed as floating 
% point numbers. 

% arguments parsing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ip = inputParser;
addRequired(ip, 'x', @(x) (isnumeric(x)&&(length(x)==numel(x))) )
addRequired(ip, 'y', @(x) (isnumeric(x)) )
addRequired(ip, 'fitFunction', @(x) (isstring(x)||ischar(x)||isa(x,'function_handle')) )
addParameter(ip, 'range', [], @(x) (isnumeric(x)&&(numel(x)==2)) )
addParameter(ip, 'StartValues', [], @(x) isnumeric(x) )
addParameter(ip, 'LowerValues', [], @(x) isnumeric(x) )
addParameter(ip, 'UpperValues', [], @(x) isnumeric(x) )

parse(ip,x,y,fitFunction,varargin{:})
fnames=fields(ip.Results);
for i=1:numel(fnames)
    eval(sprintf('%s=ip.Results.%s;',fnames{i},fnames{i}))
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% fitFunction = 'poly';
% fitFunction = 'gamma';
% fitFunction = 'gamma';
if isempty(range) %#ok<NODEF>
    range = x([1,end]);
end
range_i = x>=range(1) & x<=range(2);



newval = (0:1:255)./255;

if isa(fitFunction,'string')||isa(fitFunction,'char')
figLabel = fitFunction;
    switch fitFunction
        
        case 'gamma'
            fitFunction_fh = @(param,x)...
                (param(1) + param(2).* x.^ param(3) );
            
        case 'gamma2'
            fitFunction_fh = @(param,x)...
                (param(1) + param(2).* x.^ param(3) +  param(4).* x.^ param(5));
            
        case 'gamma+gauss'
            fitFunction_fh = @(param,x)...
                    (param(1) + param(2).* x.^param(3) + param(4).* exp( -(x-param(5)).^2 ./ (param(6).^2)));
            
%         otherwise
% 
%             if regexp(fitFunction,'poly')==1
%                 % fit with a polynomial
%                 n = str2double(fitFunction(5:end));
%                 [params,S]=polyfit(vals(range_i),lumi(range_i),n);
%                 fitted = polyval(params,newval,S);
%                 rel_err = ( lumi - polyval(params,vals,S) ) ./ lumi;
%                 expr = '';
%                 for i=1:numel(params)
%                     expr = sprintf('%s+%4G*x.^%i',expr,params(i),i-1);
%                 end
%                 expr(1)='';
%                 f = sprintf ("@(x)(%s)", expr );
%                 
%             else
%                 error('unrecognized function')
%             end
    end
else
    figLabel = 'Custom function';
    fitFunction_fh = fitFunction;
end


  
% Matlab fit() function can fit anonymous functions only if:
%  - the independent variable is the last input.
%  - the first inputs are SCALAR parameters.
% 
% However, our function is @(param,x)(function body...) where p is an array
% of parameters. Individual parameters are referrend as p elemtens: param(1),
% param(2), param(3)... To make it usable with fit(), we are goin to reformat
% our function as follows, so that each parameter is passed as input:
%   - The call @(param,x) will become @(param1,param2,param3...,x) where
%       param1 is param(1), param2 is param(2) and so on...
%   - Occurrences of param(1), param(2)... in the function body are replaced
%       with the names of individual parameters param1, param2...
%
% However, all of this is not needed if param is a scalar! So, first check
% if param is saclar. If not, make the changes needed to make it compatible
% with fit().



fitFunction_char = char(func2str(fitFunction_fh));
assert( strcmp( fitFunction_char(1:10),'@(param,x)') , sprintf(...
    "invalid definition for the anonimous function 'fitFunction'. \nIts input parametes" + ...
    "must be called 'param' and 'x', so that it begins as '@(param,x)...'"));
% find if p is a vector or not. if not, no change is needed
p_elements = regexp( fitFunction_char, 'param(\d*\)', 'match');

if ~isempty(p_elements)
    % p is a vector. Changes needed (read above).

    % replace p(1), p(2)... with p1, p2... in the function body.
    p_individuals = strrep( p_elements, '(','');
    p_individuals = strrep( p_individuals, ')','');
    for i=1:numel(p_elements)
        fitFunction_char = strrep( fitFunction_char, p_elements{i}, p_individuals{i});
    end
    % also substitute param with param1,param2,... in the function call. This
    % changes @(param,x) into @(param1,param2...,x).
    fitFunction_char = strrep(fitFunction_char,'@(param,',sprintf('@(%s,',strjoin(p_individuals,',')));

    % also, take care of the format of the output function, returned as
    % the text of an anonymous function with just one argument (values,
    % that has to be converted in luminance). So, create a format
    % string that will be used later by the command sprintf. Here we
    % replace parameter names with the format spec of floating point
    % numbers in scientific notation with 4 significant digits (i.e. '%4G')
    fmt = char(func2str(fitFunction_fh));
    for i=1:numel(p_elements)
        fmt = strrep( fmt, p_elements{i}, '%.4G');
    end
    % substitute the call leaving x as the only input
    fmt = strrep(fmt,'@(param,x)','@(x)');
else
    % Only take care about 'fmt'
    fmt = char(func2str(fitFunction_fh));
    fmt = strrep(fmt,'@(param,x)','@(x)');
    fmt = strrep(fmt,'param','%.4G');
end

% Convert back the array of char with the text of our function to an
% actual function handle.
fitFunction_fh2 = str2func(fitFunction_char);


% we can use fit() now
g = fittype(fitFunction_fh2,'independent','x','options',fitoptions('Method','NonlinearLeastSquares',...
    'Lower', LowerValues,...
    'Upper', UpperValues,...
    'StartPoint', StartValues));
fitobj = fit(x(range_i),y(range_i),g);


% Return the output
p = coeffvalues(fitobj);
f = sprintf(fmt,p);
func = eval(f); % function handle corresponding to "f"


% Denser values for plot
newval = (0:1:255)./255;
fitted = func(newval);


% To estimate the goodness of fit, use the "relative error" defined as
% (fit-data)/data
rel_err = ( y - func(x) ) ./ y;





figure('name',figLabel)
subplot(2,1,1)
plot(x,y,'ko')
xlabel('Normalized input')
ylabel('Luminance (cd m^-^1)')
hold on
plot(newval, fitted,'k-')
subplot(2,1,2)
plot(x,rel_err*100,'ko')
% ylim([-150 150])
xlabel('Normalized input')
ylabel('Relative error (%)')

