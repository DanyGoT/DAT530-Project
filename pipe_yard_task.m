function arcs = pipe_yard_task(name, inputs, outputs)
% Arcs for one transition. inputs/outputs: {place, weight, place, weight, ...}
% Zero-weight entries are skipped.
arcs = {};
for i = 1:2:numel(inputs)
    if inputs{i+1} > 0
        arcs = [arcs, {inputs{i}, name, inputs{i+1}}]; %#ok<AGROW>
    end
end
for i = 1:2:numel(outputs)
    if outputs{i+1} > 0
        arcs = [arcs, {name, outputs{i}, outputs{i+1}}]; %#ok<AGROW>
    end
end
end
