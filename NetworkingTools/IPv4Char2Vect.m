function IpDecVector = IPv4Char2Vect(IpChar)
%     Returns a column vector containing the 4 numbers of an IPv4, in uint8
%     format (0-255).
    if ~ValidateIPv4(IpChar)
%         Check that the input is a valid IPv4
        error('The input IPv4 is not valid.')
    end
%     Match the IP, while taking a token for each of the 4 components.
    Tokens = regexp(IpChar,['(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'...
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'...
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'...
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'],'tokens');
%     Now the IP is converted from charactes to a numeric vector of type
%     uint8.
    IpDecVector = cast(cellfun(@str2double,Tokens{1},'un',1),'uint8');
%     Makes sure to have a column vector
    IpDecVector = IpDecVector(:);
end
