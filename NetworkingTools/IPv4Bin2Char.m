function IpChar = IPv4Bin2Char(IpBinVector)
    if length(IpBinVector)~=32&&(isrow(IpBinVector)||iscolumn(IpBinVector))
        error('Invalid IP input!')
    end
%     Makes sure that the input is in the column format.
    IpBinVector = IpBinVector(:);
%     Put the vector back into a 8-by-4 matrix.
    IpBinMatrix = reshape(IpBinVector,8,4);
%     Get a 4-element column vector of the IPv4.
    IpDecVector = bi2de(IpBinMatrix','left-msb');
%     Converts the IP numeric vector into a cell array of characters and
%     then joins them with a separator point.
    IpChar = IPv4Vect2Char(IpDecVector);