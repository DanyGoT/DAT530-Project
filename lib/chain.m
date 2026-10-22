% net = chain(prefix, steps, n, out)
%
% A line of processing steps. Each step has an input buffer and n parallel
% workers (copies of the step transition, see replicate):
%   p<prefix><step1> -> t<prefix><step1>_1..n -> p<prefix><step2> -> ... -> out
%
% steps: step names, e.g. {'Clean','Inspect'} or readtable(...).step
% n:     workers per step, scalar or one per step
% out:   place the last step puts tokens in (declare it yourself)
%
% net.Ps, net.Ts, net.As: append to set_of_Ps/Ts/As
% net.p.<step>: buffer name, net.t.<step>: worker names (e.g. for each)

function net = chain(prefix, steps, n, out)

steps = reshape(cellstr(steps), 1, []);  % also takes strings / table columns
if isscalar(n), n = repmat(n, 1, numel(steps)); end

net.Ps = {}; net.Ts = {}; net.As = {};
for k = 1:numel(steps)
  p = ['p' prefix steps{k}];
  if k < numel(steps)
    next = ['p' prefix steps{k+1}];
  else
    next = char(out);
  end
  [ts, as] = replicate(['t' prefix steps{k}], n(k), {p, 1}, {next, 1});

  net.Ps = [net.Ps, {p}];
  net.Ts = [net.Ts, ts];
  net.As = [net.As, as];
  net.p.(steps{k}) = p;
  net.t.(steps{k}) = ts;
end
