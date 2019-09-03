function BroadcastAddress = CalculateBroadcastAddress(IP,SubnetMask)
    if ~ValidateIPv4(IP) || ~ValidateIPv4(SubnetMask)
        error('Invalid address.')
    end
    BroadcastAddress = IPv4Vect2Char(bitor(IPv4Char2Vect(IP),bitcmp(IPv4Char2Vect(SubnetMask),'uint8'),'uint8'));
    