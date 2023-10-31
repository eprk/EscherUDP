function [frameN,t]=getPcoTimestamp(bits)

tmp = pixel2digits(bits);
frameN = sum(tmp(1:8).*(10.^(7:-1:0)));

t = datetime(sum(tmp(9:12).*(10.^(3:-1:0))),... %year
            sum(tmp(13:14).*(10.^([1,0]))),... % month
            sum(tmp(15:16).*(10.^([1,0]))),... % day
            sum(tmp(17:18).*(10.^([1,0]))),... % hour
            sum(tmp(19:20).*(10.^([1,0]))),... % minute
            sum(tmp(21:22).*(10.^([1,0]))),... % second
            sum(double(tmp(23:28)).*(10.^(2:-1:-3)))... % second
            );
end

function d=pixel2digits(pxl)

l=length(pxl);
d=zeros(1,2*l);
for i=1:l
%     d(2*(i-1)+1) = floor(double(pxl(i))/16); % higher digit (4 highest bits)
    d(2*(i-1)+1) = bitshift(pxl(i),-4); % higher digit (4 highest bits)
    d(2*(i-1)+2) = rem(pxl(i),16); % lower digit (4 lowest bits)
end

end