function net_dot()
% Graphviz drawings of the nets, made from the PDFs themselves so they can't
% drift from the model: one per module, and the whole net (overview.dot)
% with each module by its ports and each connector by its places. Writes
% figures/nets/*.dot; figures/nets/render.sh makes the PDFs and SVGs.
% Circles: places, with their tokens at the start where the parameters set
% them (params.m). Bars: transitions; blue: ports, input ports on the left,
% output ports on the right. Transitions with the same inputs and outputs
% (a step's one-per-worker transitions, the wash lanes) are drawn as one bar,
% named first...last.

global global_info
P = params();
model_init(P);
names = model_pdfs(P);
nets = cellfun(@feval, names, 'UniformOutput', false);
pns = pnstruct(names);
dyn = model_dyn(P, pns);
m0 = dyn.m0;
A = {};                                     % every arc: from, to, weight
for k = 1:numel(nets), A = [A; reshape(nets{k}.set_of_As, 3, [])']; end
folder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'figures', 'nets');

modules = {'arrival', 'yard', 'wash', 'inspection', 'repair', 'departure'};
[ins, outs] = deal(cell(size(modules)));
for k = 1:numel(modules)
    n = nets{strcmp(names, [modules{k}, '_pdf'])};
    [ins{k}, outs{k}] = port_sides(n, A);
    write_module(fullfile(folder, [modules{k}, '.dot']), [modules{k}, '_pdf.m'], n, ins{k}, outs{k}, m0);
end
write_overview(fullfile(folder, 'overview.dot'), modules, nets(startsWith(names, 'imc_')), ins, outs);


function [in, out] = port_sides(n, A)
% Input ports take from a place outside the module, output ports give to one.
in = {}; out = {};
for t = n.set_of_Ports
    if any(strcmp(A(:, 2), t{1}) & not(ismember(A(:, 1), n.set_of_Ps))), in{end+1} = t{1}; end
    if any(strcmp(A(:, 1), t{1}) & not(ismember(A(:, 2), n.set_of_Ps))), out{end+1} = t{1}; end
end
out = setdiff(out, in, 'stable');


function write_module(file, source, n, in, out, m0)
As = reshape(n.set_of_As, 3, [])';
Ts = n.set_of_Ts;
% one bar for transitions with the same inputs and outputs (not ports)
key = cellfun(@(t) strjoin([{regexprep(t, '_\d+$', '')}; sort(As(strcmp(As(:, 2), t), 1)); {'>'}; ...
                            sort(As(strcmp(As(:, 1), t), 2))]', ' '), ...
              Ts, 'UniformOutput', false);
draw = containers.Map();                    % transition -> the bar it is drawn as
label = containers.Map();
for t = Ts
    same = Ts(strcmp(key, key{strcmp(Ts, t{1})}));
    if ismember(t{1}, n.set_of_Ports) || isscalar(same)
        draw(t{1}) = t{1}; label(t{1}) = t{1};
    else
        draw(t{1}) = same{1};
        label(same{1}) = sprintf('%s...%s', same{1}, regexprep(same{end}, '^.*_', ''));
    end
end
f = fopen(file, 'w');
fprintf(f, '// %s module, made by analysis/net_dot.m from %s.\n', n.PN_name, source);
fprintf(f, ['digraph %s {\n  rankdir=LR; nodesep=0.3; ranksep=0.8; forcelabels=true;\n', ...
            '  label="%s"; labelloc=t; fontname="Helvetica"; fontsize=14;\n', ...
            '  node [fontname="Helvetica", fontsize=10, label=""];\n  edge [arrowsize=0.6, penwidth=0.8];\n'], ...
        n.PN_name, n.PN_name);
bars = unique(values(draw), 'stable');
for t = bars
    port = ismember(t{1}, n.set_of_Ports);
    col = '#1f5fa8'; if not(port), col = '#222222'; end
    fprintf(f, '  "%s" [shape=box, style=filled, fixedsize=true, width=0.08, height=0.42, color="%s", fillcolor="%s", xlabel="%s"];\n', ...
            t{1}, col, col, label(t{1}));
end
if not(isempty(in)), fprintf(f, '  { rank=min; %s }\n', sprintf('"%s"; ', in{:})); end
if not(isempty(out)), fprintf(f, '  { rank=max; %s }\n', sprintf('"%s"; ', out{:})); end
for p = n.set_of_Ps
    k = find(strcmp(m0(1:2:end), p{1}), 1);
    tok = ''; if not(isempty(k)), tok = num2str(m0{2*k}); end
    fprintf(f, '  "%s" [shape=circle, fixedsize=true, width=0.36, xlabel="%s", label="%s"];\n', p{1}, p{1}, tok);
end
seen = {};
side = {'pYFork', 'pCFork'};                % taken and given back by every yard job: not drawn
for k = 1:size(As, 1)
    a = As(k, :);
    if any(ismember(a(1:2), side)) && not(any(ismember(a(1:2), {'tYForkToCoop', 'tYForkToMain'}))), continue, end
    if isKey(draw, a{1}), a{1} = draw(a{1}); end
    if isKey(draw, a{2}), a{2} = draw(a{2}); end
    e = sprintf('"%s" -> "%s"', a{1}, a{2});
    if ismember(e, seen), continue, end
    seen{end+1} = e;
    if a{3} > 1, e = sprintf('%s [label="%d", fontsize=9]', e, a{3}); end
    fprintf(f, '  %s;\n', e);
end
fprintf(f, '}\n');
fclose(f);


function write_overview(file, modules, imcs, ins, outs)
% Each module as one box, each connector place as a circle on the arcs
% between the modules whose ports it joins.
titles = {'Arrival', 'Yard', 'Washing', 'Inspection', 'Repair', 'Departure'};
owner = containers.Map();
for k = 1:numel(modules)
    for t = [ins{k}, outs{k}], owner(t{1}) = titles{k}; end
end
f = fopen(file, 'w');
fprintf(f, ['// The whole net (model_pdfs.m), made by analysis/net_dot.m from the PDFs:\n', ...
            '// each module as a box, each connector place (imc/) as a circle.\n', ...
            'digraph Overview {\n  rankdir=LR; nodesep=0.35; ranksep=0.55; forcelabels=true;\n', ...
            '  fontname="Helvetica";\n  node [fontname="Helvetica", fontsize=10];\n', ...
            '  edge [arrowsize=0.6, penwidth=0.8];\n']);
for k = 1:numel(titles)
    fprintf(f, '  "%s" [shape=box, style="rounded,filled", fillcolor="#dbe7f5", color="#1f5fa8", fontsize=12, width=1.2, height=0.5];\n', titles{k});
end
fprintf(f, '  { rank=same; "Repair"; "Departure"; }\n');
for k = 1:numel(imcs)
    As = reshape(imcs{k}.set_of_As, 3, [])';
    for p = imcs{k}.set_of_Ps
        fprintf(f, '  "%s" [shape=circle, fixedsize=true, width=0.22, label="", xlabel="%s", fontsize=8];\n', p{1}, p{1});
        from = unique(cellfun(@(t) owner(t), As(strcmp(As(:, 2), p{1}), 1), 'UniformOutput', false));
        to   = unique(cellfun(@(t) owner(t), As(strcmp(As(:, 1), p{1}), 2), 'UniformOutput', false));
        back = any(strcmp(to, 'Yard')) && not(any(strcmp(from, 'Arrival')));   % arcs back to the yard
        for m = from, fprintf(f, '  "%s" -> "%s"%s;\n', m{1}, p{1}, ifelse(back, ' [constraint=false]', '')); end
        for m = to,   fprintf(f, '  "%s" -> "%s";\n', p{1}, m{1}); end
    end
end
fprintf(f, '}\n');
fclose(f);


function v = ifelse(c, a, b)
if c, v = a; else, v = b; end
