function [frameN,t]=getPcoBinaryTimestamps(images)

N = size(images,3);
frameN = zeros(1,N);
t(1,N) = datetime();

for i=1:N
    bits=squeeze(images(1,1:14,i));
    [frameN(i),t(i)]=getPcoTimestamp(bits);
end

end