folder = 'C:\Data\2024 02 26 isoi\';

basel_file = 'red new position basel-006.mj2';

vr = VideoReader([folder basel_file]);
bas = squeeze(vr.read());
bas = cast(mean(bas,3),'uint16');
% [ny,nx]=size(bas);

figure
imagesc(bas)

files = uigetfile('.mj2','MultiSelect','on');

n = length(files);
offset = 10000;
for i=1:n
    fprintf('processing movie %i of %i...\n',i,n)
    vr = VideoReader(strcat(folder,files{i}));
    tmp = vr.read();
    tmp_sub_bas = tmp+offset-bas;
    
    newname = strrep(files{i},'.mj2','_subBasel.mj2');
    vw = VideoWriter(strcat(folder,newname),'Motion JPEG 2000');
    vw.LosslessCompression=true;
    open(vw)
    vw.writeVideo(tmp_sub_bas);
    close(vw)
    
    load(strrep(strcat(folder,files{i}),'.mj2','.mat')) % variable called 'metafile'
    save(strrep(strcat(folder,files{i}),'.mj2','_subBasel.mat'),'metafile')
    
end
disp('done')






