function SelTab2Clip(mytable,selectedIndices)
    %         selectedIndices is a vector [a b c d], in which a and b are the
    %         row and column number of the top-left element of the selection. c
    %         and d are the row and column number of the bottom-right element.

    %         To copy the data from the table of zebrasays to the clipboard
    str = '';
    for i = selectedIndices(1):selectedIndices(3)
        for j = selectedIndices(2):selectedIndices(4)
            if j == selectedIndices(4)
                if isa(mytable.Data{i,j}, 'char')
                    str = sprintf('%s', str, mytable.Data{i,j});
                else
                    str = sprintf('%s%f',str,mytable.Data{i,j});
                end
            else
                if isa(mytable.Data{i,j}, 'char')
                    str = sprintf('%s\t', str, mytable.Data{i,j});
                else
                    str = sprintf('%s%f\t',str, mytable.Data{i,j});
                end
            end
        end
        str = sprintf('%s\n',str);
    end
    clipboard('copy',str);
end
