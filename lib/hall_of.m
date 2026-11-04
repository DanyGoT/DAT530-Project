function [h, name] = hall_of(name)
% The hall a place or transition belongs to and its name in hall 1
% (hall_name backwards): 'tH2_IOk' -> 2, 'tIOk'. Anything else is hall 1's
% or no hall's: 1 and the name as it is.
h = 1;
if numel(name) < 4 || name(2) ~= 'H', return, end
t = regexp(name, '^.H(\d+)_', 'tokens', 'once');
if isempty(t), return, end
h = str2double(t{1});
name = [name(1), name(numel(t{1}) + 4:end)];
