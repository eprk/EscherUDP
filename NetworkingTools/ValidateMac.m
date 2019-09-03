function ScalarLogicOut = ValidateMac(MacChar)
%     Check that the MAC address is valid and the StrIn contain only a
%     MAC address and nothing more.
    match = regexp(MacChar,'^[0-9a-fA-F]{12}$','once');
    if isempty(match)
        ScalarLogicOut = false;
    else
        ScalarLogicOut = true;
    end
