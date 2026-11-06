function Y = mod_run(tag, seed, days, module, varargin)
% One module on its own, the test stubs (tests/stub_*.m) in place of the
% others, so its capacity shows without the rest of the system:
%   'yard'    Arrival + Yard: unloading and Coop work. The hall takes only
%             the joints P.hall_buffer credits allow (no credit comes back).
%   'wash'    Yard + Washing, fed from the backlog; set P.hall_buffer high so
%             the credits never run out.
%   'hall'    Yard + Washing + Inspection: the backlog only (no arrivals, no
%             shipping, no joints back from repair). The crew's capacity.
%   'repair'  Repair: only the joints at the workshops at the start, what
%             comes back a day against the flow that put them there.
% Changes as name/value pairs, as exp_run. Saves results/modules/
% <tag>_s<seed>.mat and .csv.

global global_info
P = params();
P.seed = seed;
P.days = days;
for k = 1:2:numel(varargin)
    assert(isfield(P, varargin{k}), ['no parameter ', varargin{k}]);
    P.(varargin{k}) = varargin{k+1};
end
pdfs = struct('yard',   {{'arrival_pdf', 'yard_pdf', 'imc_arrival_yard', 'stub_yard'}}, ...
              'wash',   {{'yard_pdf', 'wash_pdf', 'imc_yard_wash', 'stub_wash'}}, ...
              'hall',   {{'yard_pdf', 'wash_pdf', 'inspection_pdf', 'imc_yard_wash', ...
                          'imc_wash_inspection', 'imc_inspection_yard', 'stub_hall'}}, ...
              'repair', {{'repair_pdf', 'stub_repair'}});

model_init(P);
pns = pnstruct(pdfs.(module));
pni = initialdynamics(pns, model_dyn(P, pns));
tic;
sim = gpensim(pni);
Y.minutes = toc / 60;

weekdays = sum(mod(0:P.days-1, 7) < 5);
hours = weekdays * diff(P.shift) / 60;            % shift hours in the run
fired = @(names) sum(cellfun(@timesfired, names));
if not(strcmp(module, 'repair'))
    [~, ~, RU] = evalc('prnschedule(sim)');
    levels = {sim.system_resources.name};
    Y.busy = sum(RU(:, 2)) / (sum(P.crew) * hours * 60);
    Y.busy_cert = sum(RU(endsWith(levels, 'T'), 2)) / max(1, sum(P.certified) * hours * 60);
end
switch module
    case 'yard'                                   % joints a shift hour
        Y.arrived  = fired({'tALong', 'tAShort', 'tABypass', 'tACHall', 'tACBypass'}) / hours;
        Y.unloaded = fired({'tYInLong', 'tYInShort', 'tYInBypass', 'tYInCHall', 'tYInCBypass'}) / hours;
        Y.gate     = av_tokens(sim, {'pAYLong', 'pAYShort', 'pAYBypass', 'pAYCHall', 'pAYCBypass'});
        Y.gate_end = sum(cellfun(@ntokens, {'pAYLong', 'pAYShort', 'pAYBypass', 'pAYCHall', 'pAYCBypass'}));
        W = yard_work(P);
        jobs = cellfun(@timesfired, W.name);
        Y.fork_busy = sum(jobs .* W.minutes) / (P.forklifts * hours * 60);
    case 'wash'                                   % joints a shift hour, per lane
        Y.washed = fired(arrayfun(@(k) sprintf('tWash_%d', k), 1:P.wash_lanes, 'UniformOutput', false)) / hours;
        Y.per_lane = Y.washed / P.wash_lanes;
        Y.bound = 60 / (round(P.wash_min / P.delta) * P.delta);   % a lane, at the rounded time
    case 'hall'                                   % joints a week (5 shifts)
        Y.inspected = fired({'tIOk', 'tIMach', 'tIHb', 'tIScrap'}) * 5 / weekdays;
        Y.per_hour = Y.inspected * weekdays / 5 / (sum(P.crew) * hours);
        B = crew_bound(P);
        Y.bound = B.bound;
        Y.of_bound = Y.inspected / B.bound;
        for L = 0:3
            i = ismember(levels, {sprintf('L%d', L), sprintf('L%dT', L)});
            Y.(sprintf('busy_L%d', L)) = sum(RU(i, 2)) / max(1, P.crew(L+1) * hours * 60);
        end
        Y.waiting = av_tokens(sim, {'pWI'});      % washed, waiting for room on the floor
        Y.free_floor = av_tokens(sim, {'pISpace'});
    case 'repair'                                 % joints a calendar day [machining hardbanding]
        Y.back_mach = fired({'tRMachHall', 'tRMachReady'}) / P.days;
        Y.back_hb   = fired({'tRHbHall', 'tRHbReady'}) / P.days;
        flow = P.inspected_per_day * 5/7 * P.p_order(1:2) .* P.share(1:2);   % sent a day, on average
        Y.flow_mach = flow(1);
        Y.flow_hb   = flow(2);
end

root = fileparts(fileparts(mfilename('fullpath')));
[~, commit] = system(['git -C "', root, '" rev-parse --short HEAD']);
[~, dirty] = system(['git -C "', root, '" status --porcelain --untracked-files=no']);
commit = strtrim(commit);
if not(isempty(strtrim(dirty))), commit = [commit, '+dirty']; end
folder = fullfile(root, 'results', 'modules');
if not(isfolder(folder)), mkdir(folder); end
name = fullfile(folder, sprintf('%s_s%d', tag, seed));
changes = varargin;
save([name, '.mat'], 'Y', 'P', 'tag', 'seed', 'module', 'changes', 'commit');
row = [table(string(tag), seed, days, string(module), string(commit), ...
             'VariableNames', {'tag', 'seed', 'days', 'module', 'commit'}), struct2table(Y)];
writetable(row, [name, '.csv']);
disp(Y);
