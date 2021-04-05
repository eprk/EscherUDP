function [BroadcastAddress, StartAddress, EndAddress] = CalculateBroadcastAddress(IP,SubnetMask)
% The function returns the broadcast address, together with the first and
% last of the list of addresses needed to send a message manually to all
% addresses between the host address and the broadcast address (a sort of
% manual broadcast).
    if ~ValidateIPv4(IP) || ~ValidateIPv4(SubnetMask)
        error('Invalid address.')
    end
    BroadcastAddress = IPv4Vect2Char(bitor(IPv4Char2Vect(IP),bitcmp(IPv4Char2Vect(SubnetMask),'uint8'),'uint8'));
    
    HostAddress = IPv4Vect2Char(bitand(IPv4Char2Vect(IP),IPv4Char2Vect(SubnetMask),'uint8'));
    
    StartAddress = IPv4Dec2Char(IPv4Char2Dec(HostAddress)+1);
    EndAddress = IPv4Dec2Char(IPv4Char2Dec(BroadcastAddress)-1);
end
