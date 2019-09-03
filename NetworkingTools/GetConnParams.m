function ConnParams = GetConnParams
    if ispc
        %                 This is the solution for a Windows-running computer
        [sysStatus,sysReply] = system('ipconfig /all');
        if sysStatus == 0
            %                     If sysStatus is 0, the command was executed
            %                     correctly.

            %                     First, let's divide the message returned by the DOS
            %                     command into blocks, that are separated by two
            %                     consecutive line feeds (\n\n) and NOT followed by a
            %                     whitespace (\s). I used regex inside strsplit:
            blocks=strsplit(sysReply,'\n\n(?!\s)','DelimiterType','RegularExpression');
            %                     Now, usually the first block is for general
            %                     information, but I prefer not to skip it.
            %                     We run a search in all blocks for an IP:
            IpMatch=regexp(blocks,'(?<=IP.*)(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])','match','dotexceptnewline');
%             Match the Subnet Mask in a similar way:
            MaskMatch=regexp(blocks,'(?<=[mM]ask.*)(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])','match','dotexceptnewline');
            if sum(~cellfun('isempty',MaskMatch))==0
%                 Alternative way: take the address in the line after the
%                 IP.
                MaskMatch=regexp(blocks,['(?<=IP.*(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9]).*\n.*)'...
                    '(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'],'once','match','dotexceptnewline');
            end
            %                     Now we look for the MAC address (physical address).
            %                     The default format should be XX-XX-XX-XX-XX-XX. It's
            %                     composed by 12 total hexadecimal digits (= 6 bytes =
            %                     48 bits).
            MacMatch=regexp(blocks,'(?<![:-])(?:[A-Fa-f0-9]{2}[:-]){5}[A-Fa-f0-9]{2}(?![:-])','match');
            %                 Find which cells are non-empty in the IpMatch.
            LogicIpArray = ~cellfun('isempty',IpMatch);
        else
            error('System command was not correctly executed.')
        end
    else
        %                 This is the solution for a Unix-running computer
        [sysStatus,sysReply] = system('ifconfig -a');
        if sysStatus == 0
            %                     If sysStatus is 0, the command was executed
            %                     correctly.
            blocks=strsplit(sysReply,'\n\n','DelimiterType','RegularExpression');
            IpMatch = regexp(blocks,'(?<=net.*)(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])','once','match','dotexceptnewline');
            MaskMatch = regexp(blocks,'(?<=[Mm]ask.*)(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])','once','match','dotexceptnewline');
            MacMatch=regexp(blocks,'(?<![:-])(?:[A-Fa-f0-9]{2}[:-]){5}[A-Fa-f0-9]{2}(?![:-])','match');
            %                 Find which cells are non-empty in the IpMatch.
            LogicIpArray = and(~cellfun('isempty',IpMatch), ~cellfun('isempty',MacMatch));
        else
            error('System command was not correctly executed.')
        end
    end
    if sum(LogicIpArray)==1
        %                     Finally, we get the IP!
        myIp = IpMatch{LogicIpArray}{:};
        myMask = MaskMatch{LogicIpArray}{:};
        myMac = MacMatch{LogicIpArray}{:};
        %                         Let's remove the ":" or "-" separator from the
        %                         MAC address, to make it more general.
        myMac = regexprep(myMac,'[:-]','');
    elseif sum(LogicIpArray)>1
        IpCellArray = [IpMatch{LogicIpArray}];
        MaskCellArray = [MaskMatch{LogicIpArray}];
        MacCellArray = [MacMatch{LogicIpArray}];
        MacCellArray = regexprep(MacCellArray,'[:-]','');
        [indx,tf] = listdlg('PromptString','More than one IP was found. Please choose one:',...
            'SelectionMode','single','ListString',IpCellArray);
        if tf == 0
            return
        end
        %                     Finally, we get the IP!
        myIp = IpCellArray{indx};
        myMask = MaskCellArray{indx};
        myMac = MacCellArray{indx};
    else
        error('IP search did not get any result.')
    end
    ConnParams.IP = myIp;
    ConnParams.SubMask = myMask;
    ConnParams.MAC = myMac;