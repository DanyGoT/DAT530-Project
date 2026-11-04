function out = hall_name(names, halls)
% The names of a hall's (or its wash's) places and transitions in hall h.
% Hall 1 keeps the plain names (pISpace, tWash_1); hall h > 1 gets 'H<h>_'
% after the first letter (pH2_ISpace, tH2_Wash_1). Several halls give one
% cell, hall by hall. hall_of goes back.
one = ischar(names);
if one, names = {names}; end
out = {};
for h = halls
    if h == 1
        out = [out, reshape(names, 1, [])];
    else
        out = [out, reshape(regexprep(names, '^(.)', sprintf('$1H%d_', h)), 1, [])];
    end
end
if one && isscalar(halls), out = out{1}; end
