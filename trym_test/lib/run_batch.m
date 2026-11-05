function R = run_batch(P, B)
% One delivery of B.batch joints (pipes) on an empty yard: unloaded, washed,
% inspected step by step in the hall, and sent to stock, scrap or the repair
% workshops. Followed until every joint is done (B.until):
%   'hall'  - out of the hall (repairs still at the workshops)
%   'ready' - rig-ready in the yard (ok, or repaired and back) or scrap
% Nothing else arrives and nobody collects stock. Crew, wash and step times,
% shift and repair times come from P (params.m). Idle time (nights,
% weekends, weeks of waiting for repairs) is skipped (fast_forward.m), so
% long repairs cost little run time.
% Returns R with counts and timings; print_batch(R, title) reports them.
%
% B fields (all optional, defaults below):
%   batch, arrive_day (0 = Monday), arrive_at (minutes after midnight),
%   order_size, short_pct (% of orders), mach_pct, hb_pct, scrap_pct
%   (% of joints, exact counts on random joints), until, max_days

global global_info
trym_test_setup(true);             % original GPenSIM modules are shared, not copied
B = with_defaults(B);
assert(B.mach_pct + B.hb_pct + B.scrap_pct <= 100, 'mach + hb + scrap must be <= 100 %');

P.days = B.max_days;
P.backlog = 0;                      % empty yard, hall and workshops at the start
P.floor_start = 0;
P.stock = 0;
P.workshop_history = 0;
global_info = struct();             % nothing left over from an earlier run
model_init(P);                      % shared setup; arrivals replaced below

% The batch: orders of B.order_size joints, all unloaded from B.arrive_at.
t0 = B.arrive_day*1440 + B.arrive_at;
n_orders = ceil(B.batch/B.order_size);
n = round(B.batch*[B.mach_pct B.hb_pct B.scrap_pct]/100);
finds = [repmat({'mach'}, 1, n(1)), repmat({'hb'}, 1, n(2)), repmat({'scrap'}, 1, n(3)), ...
         repmat({'ok'}, 1, B.batch - sum(n))];
finds = finds(randperm(B.batch));
short = false(1, n_orders);
short(randperm(n_orders, round(n_orders*B.short_pct/100))) = true;
lens = {'long', 'short'};
pipes = struct('t', {}, 'route', {}, 'len', {}, 'find', {}, 'order', {});
for j = 1:B.batch
    o = ceil(j/B.order_size);
    pipes(j) = struct('t', t0, 'route', 'hall', 'len', lens{1 + short(o)}, 'find', finds{j}, 'order', o);
end

global_info.pipes = pipes;
global_info.hall = pipes;
global_info.repair = P.repair_median .* exp(P.repair_sigma .* randn(n_orders, 2));  % days per order
global_info.workshop = {zeros(0, 2), zeros(0, 2)};
global_info.demand = [];
global_info.batch_size = B.batch;   % COMMON_POST: timings and the stop
global_info.batch_until = B.until;
global_info.when = struct();
global_info.t_hall = [];
global_info.t_rehall = [];
global_info.t_ready = [];
global_info.ok_repaired = false;
global_info.FAST_FORWARD = true;

pns = pnstruct({'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'repair_pdf', 'departure_pdf', ...
                'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', ...
                'imc_inspection_yard', 'imc_inspection_repair', 'imc_repair_yard', ...
                'imc_yard_departure'});
pni = initialdynamics(pns, model_dyn(P, pns));
tic;
Sim_Results = gpensim(pni);

g = global_info;
R.P = P;
R.B = B;
R.t0 = t0;
R.finds = n;                        % [mach hb scrap] joints in the batch
R.repair = g.repair;
R.unloaded = sum(cellfun(@timesfired, {'tALong', 'tAShort'}));
R.washed = timesfired('tWOut');
R.when = g.when;
R.t_hall = sort(g.t_hall);          % first pass out of the hall
R.t_rehall = sort(g.t_rehall);      % out of the hall again after repair
R.t_ready = sort(g.t_ready);        % rig-ready or scrap in the yard
R.out = cellfun(@timesfired, {'tIOk', 'tIMach', 'tIHb', 'tIScrap'});
R.back = [timesfired('tRMachHall') + timesfired('tRHbHall'), ...
          timesfired('tRMachReady') + timesfired('tRHbReady')];   % [via the hall, straight to stock]
R.ready = ntokens('pYReady');
R.scrap = ntokens('pYScrap');
R.at_workshop = [ntokens('pRMach'), ntokens('pRHb')];
R.steps = struct('name', {g.S.name}, 'level', {g.S.level}, 'ft', {g.S.ft});
R.step_log = g.step_log;            % per step: [joints first_start last_end]
R.done = numel(g.t_ready) >= B.batch;
if strcmp(B.until, 'hall'), R.done = numel(R.t_hall) >= B.batch; end
R.end_time = current_time();
R.jumps = 0;
if isfield(g, 'ff'), R.jumps = g.ff.jumps; end
R.runtime = toc;
R.Sim_Results = Sim_Results;


function B = with_defaults(B)
d = struct('batch', 300, 'arrive_day', 0, 'arrive_at', 8*60, 'order_size', 30, ...
           'short_pct', 10, 'mach_pct', 35, 'hb_pct', 6, 'scrap_pct', 4, ...
           'until', 'ready', 'max_days', 1500);
for f = fieldnames(d)'
    if not(isfield(B, f{1})), B.(f{1}) = d.(f{1}); end
end