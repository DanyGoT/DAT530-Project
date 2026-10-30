% Repair on its own, 3 days, with only the joints at the workshops at the
% start. Every joint whose repair is done by the end has left, the rest are
% still there, and each went the way its row says (hall or stock).

clear all; clc;
global global_info

P = params();
P.seed = 4;
P.days = 3;
model_init(P);
start = global_info.workshop;
pns = pnstruct({'repair_pdf', 'stub_repair'});
assert_no_sources(pns);
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

ends = P.days*1440;
names = {'Mach', 'Hb'};
for w = 1:2
    q = start{w};
    due = q(:, 1) <= ends - 1;          % a minute's slack for the last firings
    hall = timesfired(['tR', names{w}, 'Hall']);
    ready = timesfired(['tR', names{w}, 'Ready']);
    assert(hall + ready >= sum(due) && hall + ready <= sum(q(:, 1) <= ends), ...
           [names{w}, ': joints left before or long after their repair was done']);
    assert(ntokens(['pR', names{w}]) == size(global_info.workshop{w}, 1) && ...
           ntokens(['pR', names{w}]) + hall + ready == size(q, 1), [names{w}, ': joints lost']);
    assert(hall <= sum(q(:, 2) == 1) && ready <= sum(q(:, 2) == 0), [names{w}, ': wrong way back']);
end
back = timesfired('tRMachHall') + timesfired('tRHbHall') + timesfired('tRMachReady') + timesfired('tRHbReady');
assert(back > 0, 'nothing came back');
assert(ntokens('pRI') + ntokens('pRYReady') == back, 'joints lost on the way back');
disp(['test_repair: ok (', int2str(back), ' back, ', int2str(ntokens('pRI')), ' to the hall)']);
