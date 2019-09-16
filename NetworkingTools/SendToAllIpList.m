function IpList = SendToAllIpList(StartAddress,EndAddress)
    if ~ValidateIPv4(StartAddress) || ~ValidateIPv4(EndAddress)
        error('Invalid IP(s).')
    end
    StartNum = IPv4Char2Dec(StartAddress);
    EndNum = IPv4Char2Dec(EndAddress);
    if StartNum>=EndNum
        error('The starting and ending addresses are not in the correct order.')
    end
    IpVector = StartNum:EndNum;
    IpList = arrayfun(@IPv4Dec2Char, IpVector,'un',0);
end