function IpChar = IPv4Dec2Char(IpDecNum)
% Converts a IP scalar decimal number into a character vector.
    if IpDecNum<0 || IpDecNum>2^32-1
        error('Number is not in the 32-bit IP range.')
    end
    IpDecVector = uint8(zeros(4,1));
    i=1;
    while i<=4
        remainder = mod(IpDecNum,256^(4-i));
        IpDecVector(i) = (IpDecNum-remainder)/256^(4-i);
        IpDecNum = remainder;
        i = i + 1;
    end
    IpChar = strjoin(arrayfun(@num2str,IpDecVector, 'un', 0), '.');
end
