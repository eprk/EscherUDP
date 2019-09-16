function CloseAllUdp
    AllUdpObj = instrfindall('Type','udp');
    if ~isempty(AllUdpObj)
        stopasync(AllUdpObj)
        fclose(AllUdpObj);
        delete(AllUdpObj)
    end
end
