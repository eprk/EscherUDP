function description = inspect_obj(obj)

props = fieldnames(obj);

vals = cell(size(props));
for i=1:numel(vals)
    vals{i} = get(obj,props{i});
end

description = cat(2,props,vals);

end