function s = add_binary(a, b)
    if all(size(a)~=size(b))||~isvector(a)||~isvector(b)
        error('Size of the two binary vectors is not matching.')
    end
    if isrow(a)
        a = [0, a];
        b = [0, b];
    else
        a = [0; a];
        b = [0; b];
    end
    c = a&b;
    while any(c)
        b = xor(a, b);
        a = circshift(c, -1);
        c = a&b;
    end
    s = a+b;
    if s(1) == 0
        s(1)=[];
    end
end
