% [names, arcs] = replicate(base, n, inputs, outputs)
%
% Make n copies of a transition, each with the same input and output arcs.
% inputs/outputs: {place, weight, place, weight, ...}, optional.
% Call with just (base, n) to get the names, e.g. for dyn.ft.
% names: {'<base>_1', ..., '<base>_n'}, arcs: ready for set_of_As.

function [names, arcs] = replicate(base, n, inputs, outputs)

if nargin < 3, inputs = {}; end
if nargin < 4, outputs = {}; end

names = arrayfun(@(i) sprintf('%s_%d', base, i), 1:n, 'UniformOutput', false);
arcs = {};
for k = 1:n
  for j = 1:2:numel(inputs)
    arcs = [arcs, {inputs{j}, names{k}, inputs{j+1}}];
  end
  for j = 1:2:numel(outputs)
    arcs = [arcs, {names{k}, outputs{j}, outputs{j+1}}];
  end
end
