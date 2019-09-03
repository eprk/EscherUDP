function IpBinVector = IPv4Char2Bin(IpChar)
    IpDecVector = IPv4Char2Vect(IpChar);
%     Finally the vector is converted into a binary matrix, with 4 rows and
%     8 columns.
    IpBinMatrix = de2bi(IpDecVector,8,'left-msb');
%     Rows and columns are swapped. And a column vector is obtained.
    IpBinVector = logical(reshape(IpBinMatrix',32,1));
    