% Structural analysis of the whole net, and an upper bound on what the crew
% can inspect. Needs no simulation: the invariants come from the incidence
% matrix, the bound from params.m.
%
% Invariants say what the net itself keeps constant, whatever the guards in
% the processors decide: room on the hall floor, the credits in front of
% the hall, and the state of each wash lane. GPenSIM's pinvariant lists them
% all; below, the ones the model relies on are checked one by one.
% A coverability tree and mincyctime don't fit this net: the arrival and
% ticket clocks make it unbounded, and it isn't an event graph.

clear all; clc;
global global_info

P = params();
P.days = 1;                     % only the structure is needed
model_init(P);
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'repair_pdf', 'departure_pdf', ...
                'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', ...
                'imc_inspection_yard', 'imc_inspection_repair', 'imc_repair_yard', ...
                'imc_yard_departure'});
dyn = model_dyn(P, pns);

pinvariant(pns);

% C(t, p): tokens transition t adds to place p. y is an invariant if C*y = 0,
% and then y'*m stays at its value in m0.
np = pns.No_of_places;
C = pns.incidence_matrix(:, np+1:end) - pns.incidence_matrix(:, 1:np);
places = {pns.global_places.name};
m0 = zeros(np, 1);
[~, at] = ismember(dyn.m0(1:2:end), places);
m0(at) = [dyn.m0{2:2:end}];

S = global_info.S;
invariants = {
  'hall floor',   [{S.place}, {'pIDone', 'pISpace'}]
  'hall credits', {'pYRoom', 'pYW', 'pWRack', 'pWDone', 'pWI', 'pIRoom', 'pIYRoom'}
  'arrival clock', {'pAClock'}
  'ticket clock',  {'pDClock'}
};
for k = 1:P.wash_lanes
    invariants(end+1, :) = {sprintf('wash lane %d set-up', k), {sprintf('pWLong_%d', k), sprintf('pWShort_%d', k)}};
    invariants(end+1, :) = {sprintf('wash lane %d on/off', k), {'pWOff', sprintf('pWReady_%d', k)}};
end
disp(' '); disp('Invariants the model relies on:');
for k = 1:size(invariants, 1)
    y = double(ismember(places, invariants{k, 2}))';
    assert(all(C*y == 0), [invariants{k, 1}, ' is not an invariant']);
    fprintf('  %-20s %s = %d\n', invariants{k, 1}, strjoin(invariants{k, 2}, ' + '), y'*m0);
end

% Crew bound. Work that needs level L can only be done by people of level L
% or higher, so for each L: joints/week <= (their minutes a week) / (minutes
% of work per joint at level L or higher). The wash needs someone while it
% runs; it counts as L0 work. Changeovers, mobilizing and walking are left
% out, so the real number is lower.
week = 5 * diff(P.shift);                                   % shift minutes a week, per person
short = (1 - P.p_long)*P.mean_joints(2) / ((1 - P.p_long)*P.mean_joints(2) + P.p_long*P.mean_joints(1));
wash = (1 - short)*P.wash(1) + short*P.wash(2);             % minutes manned per joint
work = zeros(1, 4);
for k = 1:size(P.steps, 1)
    work(P.steps{k, 3} + 1) = work(P.steps{k, 3} + 1) + P.steps{k, 2}*P.pace/60;
end
work(1) = work(1) + wash;
disp(' '); disp('Crew bound (joints a week):');
fprintf('  %-6s %7s %16s %10s\n', 'level', 'people', 'min/joint >= L', 'bound');
bound = inf(1, 4);
for L = 0:3
    people = sum(P.crew(L+1:end));
    need = sum(work(L+1:end));
    bound(L+1) = people*week / need;
    fprintf('  L%-5d %7d %16.1f %10.0f\n', L, people, need, bound(L+1));
end
[b, L] = min(bound);
fprintf('  The crew can inspect at most %.0f joints a week (%.1f per man-hour); L%d is the limit.\n', ...
        b, b / (sum(P.crew)*week/60), L - 1);
fprintf('  The wash can wash at most %.0f a week (%d lanes, %.1f min a joint).\n', ...
        P.wash_lanes*week/wash, P.wash_lanes, wash);
