function IpDecNum = IPv4Char2Dec(IpChar)
% Converts a IP character vector into a scalar decimal number.
    IpDecVector = cast(IPv4Char2Vect(IpChar),'uint32');
    IpDecNum = IpDecVector(1)*256^3+IpDecVector(2)*256^2+...
        IpDecVector(3)*256+IpDecVector(4);
end
