%% SPHERICAL TRANSFORMATION
xCm = 59.5303;
yCm = 33.6312;
xPx = 1920;
yPx = 1080;
CmPerPixel = (xCm/xPx + yCm/yPx)/2;
rCm = 15;
% rPx = 22/CmPerPixel; % radius in pixels
PixAngleRad = 2*atan(CmPerPixel/2/rCm); % This is the angle of a pixel in degrees (calculated at the center of the screen)

VertexNY = 100; % The number of points in y dimension
% the number of points in x dimension is rescaled so that when the square
% is  adapted to the screen resolution, the grid is formed by squares.
VertexNX = round(VertexNY*xPx/yPx);
r = rCm/CmPerPixel; % r MUST be in pixels

x=linspace(0, xPx, VertexNX); % x dimension
y=linspace(0, yPx, VertexNY); % y dimension

% Create a matrix of X and Y coordinates for the 2D mesh
[X,Y] = meshgrid(x,y);

% X and Y are the initial coordinate matrices that are in pixel dimension.
% They are spherically transformed into Xtrans and Ytrans matrices
% according to the distance from the screen (r). Xtrans and Ytrans are also
% expressed in pixel dimension (e.g. they can have a [0, 1920] range for
% the x.

% Since the DisplayUndistortionCSV function requires a [0, 1] range for its
% input for both the initial coordinates and final coordinates, two sets
% matrices are produced: Xinitial, Yinintial, Xfinal, Yfinal. All of them
% are inside the [0, 1] range.

% Trim the matrix by removing the rows that have values that make the
% tangent function go outside its domain (-pi, pi).
% First remove all the columns outside the domain.
Y = Y(:, any((PixAngleRad*(X-xPx/2)) > -pi/2, 1) &...
    any((PixAngleRad*(X-xPx/2)) < pi/2, 1));
X = X(:, any((PixAngleRad*(X-xPx/2)) > -pi/2, 1) &...
    any((PixAngleRad*(X-xPx/2)) < pi/2, 1));

% Now remove the rows.
X = X(any((PixAngleRad*(Y-yPx/2)) > -pi/2, 2) &...
    any((PixAngleRad*(Y-yPx/2)) < pi/2, 2), :);
Y = Y(any((PixAngleRad*(Y-yPx/2)) > -pi/2, 2) &...
    any((PixAngleRad*(Y-yPx/2)) < pi/2, 2), :);

Xinitial = X/xPx;
Yinitial = Y/yPx;

% We will also need the column and row indices for each point of the mesh.
[XIdx, YIdx] = meshgrid(1:size(X,2),1:size(Y,1));

% Transform the mesh with a spherical correction. Then translate so that
% the top-left point is (0,0) and the bottom-right point is (1,1)
Xtrans = r.*tan(PixAngleRad*(X-xPx/2))./cos(PixAngleRad*(Y-yPx/2)) + xPx/2;
Ytrans = r.*tan(PixAngleRad*(Y-yPx/2))./cos(PixAngleRad*(X-xPx/2)) + yPx/2;

Xfinal = Xtrans/xPx;
Yfinal = Ytrans/yPx;

% Create a table with 6 columns.
% vx and vy are the output positions of the points.
% tx and ty are the input positions.
% c and r are the indices of the column and row of each point forming the
% mesh.
T = table('Size',[numel(X),6],'VariableTypes',{'double','double','double','double','uint64','uint64'},...
    'VariableNames',{'vx','vy','tx','ty','c','r'});
T.tx = Xinitial(:);
T.ty = Yinitial(:);
T.vx = Xfinal(:);
T.vy = Yfinal(:);
% Indices must start from 0.
T.c = XIdx(:)-1;
T.r = YIdx(:)-1;
%% PLOTS
% Values that are fed to the DisplayUndistortionCSV function
figure; plot(Xinitial,Yinitial,'.k'); hold on; plot(Xinitial',Yinitial','.k')
set(gca,'Ydir','reverse')
set(gca,'XLim',[0,1]); set(gca,'YLim',[0,1])
set(gca,'PlotBoxAspectRatio',[1,yPx/xPx,1])
figure; plot(Xfinal,Yfinal,'.k'); hold on; plot(Xfinal',Yfinal','.k')
set(gca,'Ydir','reverse')
set(gca,'XLim',[0,1]); set(gca,'YLim',[0,1])
set(gca,'PlotBoxAspectRatio',[1,yPx/xPx,1])

% Values that are displayed on the screen.
% Basically, the DisplayUndistortionCSV function will take a [0, 1] range
% and transform it to the pixel size of the screen ([0, 1920] for the x, 
% and [0, 1080] for the y).
figure; plot(X,Y,'.k'); hold on; plot(X',Y','.k')
set(gca,'Ydir','reverse')
set(gca,'XLim',[0,xPx]); set(gca,'YLim',[0,yPx])
set(gca,'PlotBoxAspectRatio',[1,yPx/xPx,1])
figure; plot(Xtrans,Ytrans,'.k'); hold on; plot(Xtrans',Ytrans','.k')
set(gca,'Ydir','reverse')
set(gca,'XLim',[0,xPx]); set(gca,'YLim',[0,yPx])
set(gca,'PlotBoxAspectRatio',[1,yPx/xPx,1])

%% SAVE A FILE
% Also a header will be added and this is ok.
writetable(T,'SphericalDistortionIn.csv','Delimiter',';')  

%% prova su schermo
screenlist = Screen('Screens');
scal = DisplayUndistortionCSV('SphericalDistortionIn.csv', 'SphericalDistortionOut.mat',screenlist(end));
% The .mat file created contains two variables: scaI (structure) and warptype (character vector).

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