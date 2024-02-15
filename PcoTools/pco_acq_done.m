function pco_acq_done(obj,~)
stoppreview(obj)
ud = obj.UserData;
ud.app.PcoStartAcquisitionButton.Text = 'START ACQUISITION';
frames_to_get = obj.FramesAvailable;
ud.app.PcoStruct.Images = squeeze(getdata(obj,frames_to_get));
if frames_to_get < obj.FramesPerTrigger
    warning('\nACQUISITION STOPPED PREMATURELY. Only %i frames acquired out of %i.\n',...
        frames_to_get,obj.FramesPerTrigger)
else
    disp('Acquisition done. All frames acquired.')
end
end