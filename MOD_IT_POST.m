function MOD_IT_POST(transition)
% IT event log: every status change is stored with time and register counts.
global global_info

registers = global_info.itRegisters;
counts = zeros(1, numel(registers));
for i = 1:numel(registers)
    counts(i) = ntokens(registers{i});
end
global_info.itLog(end+1, :) = [{current_time(), transition.name}, num2cell(counts)];

if strcmp(transition.name, 'tIRegisterScrap')
    pipe_yard_check_done();
end
end
