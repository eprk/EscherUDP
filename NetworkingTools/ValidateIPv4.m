function ScalarLogicOut = ValidateIPv4(IpChar)
%         Check that the IP address is valid and the StrIn contain only a
%         IP address and nothing more.
    match = regexp(IpChar,'^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$','once');
    if isempty(match)
        ScalarLogicOut = false;
    else
        ScalarLogicOut = true;
    end
end
