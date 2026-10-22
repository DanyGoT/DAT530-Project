% pairs = each(names, value)
%
% Pair every name with the same value, e.g. for dyn.ft:
%   each({'t_1','t_2'}, 5)  ->  {'t_1',5, 't_2',5}

function [pairs] = each(names, value)

pairs = reshape([names; repmat({value}, 1, numel(names))], 1, []);
