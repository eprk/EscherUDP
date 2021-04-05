
try
    ciao = ones(1,5);
    ciao(9) = [2,4];
catch me
    warning(me.stack)
end