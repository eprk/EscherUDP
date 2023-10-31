function adaptorName=PCO_getAdaptorName()

if verLessThan('matlab','8.2')%R2013a or older
    error('This adaptor is supported in Matlab 2013b and later versions'); 
elseif verLessThan('matlab','9.0') %R2015b - R2013b
    if(strcmp(computer('arch'),'win32'))
        adaptorName = ['pcocameraadaptor_r' version('-release') '_win32'];
    elseif(strcmp(computer('arch'),'win64'))
        adaptorName = ['pcocameraadaptor_r' version('-release') '_x64'];
    else
        error('This platform is not supported.');
    end
else %R2016a and newer
    if(strcmp(computer('arch'),'win64'))
        adaptorName = ['pcocameraadaptor_r' version('-release')];
    else
        error('This platform is not supported.');
    end
end