function [S, step_of] = step_list(P)
% One struct per hall step, from the table in params.m. Step k has a queue
% place pI<name> and one transition tI<name>_<i> for each person qualified
% to do it, so that many joints can be worked on at once. Steps that scrap
% joints skip also get tI<name>Skip. The last step hands over to pIDone.
% step_of maps a transition name to its step number.

levels = {'L0', 'L1', 'L2', 'L3'};
n = size(P.steps, 1);
step_of = containers.Map();
for k = 1:n
    [name, sec, level, finds, skip] = P.steps{k, :};
    S(k).name  = name;
    S(k).place = ['pI', name];
    S(k).ts    = arrayfun(@(i) sprintf('tI%s_%d', name, i), 1:sum(P.crew(level+1:end)), ...
                          'UniformOutput', false);
    S(k).tskip = '';
    if skip, S(k).tskip = ['tI', name, 'Skip']; end
    S(k).ft    = sec*P.pace/60;
    S(k).pool  = levels(level+1:end);      % this level or higher
    S(k).finds = finds;
    S(k).skip  = skip;
    % finding scrap here with 1/finds_left makes every finding step equally likely
    S(k).finds_left = sum([P.steps{k:end, 4}]);
    for t = [S(k).ts, {S(k).tskip}]
        if not(isempty(t{1})), step_of(t{1}) = k; end
    end
end
for k = 1:n-1, S(k).next = S(k+1).place; end
S(n).next = 'pIDone';
