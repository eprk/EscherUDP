function IpChar = IPv4Vect2Char(IpDecVector)
%     Converts a 4-element decimal vector into a character vector of IP.
if ~isvector(IpDecVector)
    error('Input is not a vector.')
end
IpChar = strjoin(arrayfun(@num2str,IpDecVector, 'un', 0), '.');
if ~ValidateIPv4(IpChar)
    error('The IP is not valid.')
end