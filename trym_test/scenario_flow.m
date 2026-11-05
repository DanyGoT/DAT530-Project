function results = scenario_flow(selected, total)
% scenario_flow                        % starter: 50 waiting + 50 arriving
% scenario_flow('baseline', 800)       % 400 waiting + 400 arriving
% scenario_flow('all', 100)            % compare all experiments
% scenario_flow({'baseline','promote'}, 800)
root = trym_test_setup();
if nargin < 1, selected = {'baseline'}; end
if nargin < 2, total = 100; end
if ischar(selected) || isstring(selected), selected = cellstr(selected); end
names = {'baseline', 'more-workers', 'promote', 'extra-forklift', ...
    'extra-wash', 'extra-inspection', 'larger-hall'};
if isequal(selected, {'all'}), selected = names; end
assert(iscellstr(selected) && ~isempty(selected) && all(ismember(selected, names)), ...
    'flow:Scenarios', 'Choose baseline, more-workers, promote, extra-forklift, extra-wash, extra-inspection, larger-hall, or all.');
results = cell(1, numel(selected));
summary = [];
for i = 1:numel(selected)
    P = params();
    C = flow_config(P);
    C.total = total;
    C.initial = floor(total/2);
    switch selected{i}
        case 'more-workers'
            P.crew = [3 5 2 2];    % same certificate counts; additional people are not drivers
        case 'promote'
            P.crew = [2 2 1 2];    % promote one certified L1 to L3; headcount unchanged
            C.certified = [1 0 1 2];
        case 'extra-forklift'
            C.forklifts = 2;
        case 'extra-wash'
            P.wash_lanes = 4;
        case 'extra-inspection'
            C.step_machines = 2*C.step_machines;
        case 'larger-hall'
            P.hall_space = 60;
    end
    R = run_flow(P, C);
    T = print_flow(R, selected{i});
    if isempty(summary), summary = T; else, summary = [summary; T]; end
    results{i} = R;
end
disp(summary);
folder = fullfile(root, 'flow_results');
if ~exist(folder, 'dir'), mkdir(folder); end
save(fullfile(folder, 'latest.mat'), 'results', 'summary');
writetable(summary, fullfile(folder, 'summary.csv'));
for i = 1:numel(results)
    writetable(results{i}.history, fullfile(folder, [selected{i}, '_queues.csv']));
    % Keep variable-length pipe/worker ID arrays in latest.mat rather than
    % flattening them into ambiguous CSV columns.
    L = removevars(results{i}.log, {'pipe', 'workers'});
    writetable(L, fullfile(folder, [selected{i}, '_events.csv']));
end
figure('Name', 'Finite pipe flow comparison');
subplot(2, 1, 1);
hold on;
for i = 1:numel(results)
    H = results{i}.history;
    stairs((H.time - results{i}.C.start)/1440, H.shipped, 'DisplayName', selected{i});
end
xlabel('Calendar days after start'); ylabel('Pipes shipped'); legend('Location', 'best');
subplot(2, 1, 2);
hold on;
for i = 1:numel(results)
    H = results{i}.history;
    stairs((H.time - results{i}.C.start)/1440, H.hall, 'DisplayName', selected{i});
end
xlabel('Calendar days after start'); ylabel('Occupied inspection positions'); legend('Location', 'best');
fprintf('Results saved in %s (latest run overwrites matching files).\n', folder);
end
