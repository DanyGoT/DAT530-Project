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
for w = 1:2
    name = {'Mach', 'Hb'};
    name = name{w};
    q = start{w};                         % [repair done, back through the hall]
    hall  = timesfired(['tR', name, 'Hall']);
    ready = timesfired(['tR', name, 'Ready']);
    left  = hall + ready;
    still = ntokens(['pR', name]);

    % Left when the repair was done (a minute's slack for the last firings).
    assert(left >= sum(q(:, 1) <= ends - 1) && left <= sum(q(:, 1) <= ends), ...
           [name, ': joints left before or long after their repair was done']);
    % None lost, and each went the way its row says.
    assert(still == size(global_info.workshop{w}, 1) && still + left == size(q, 1), ...
           [name, ': joints lost']);
    assert(hall <= sum(q(:, 2) == 1) && ready <= sum(q(:, 2) == 0), [name, ': wrong way back']);
end

back = sum(cellfun(@timesfired, {'tRMachHall', 'tRHbHall', 'tRMachReady', 'tRHbReady'}));
assert(back > 0, 'nothing came back');
assert(ntokens('pRI') + ntokens('pRYReady') == back, 'joints lost on the way back');

disp(['test_repair: ok (', int2str(back), ' back, ', int2str(ntokens('pRI')), ' to the hall)']);
