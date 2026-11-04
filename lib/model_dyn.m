function dyn = model_dyn(P, pns)
% Initial dynamics: marking, firing times and workers. Entries for places and
% transitions that pns doesn't have are left out, so a test can run a few
% modules on their own.

global global_info

b = global_info.backlog;                % the queue at the start, at Main or Coop
long = strcmp({b.len}, 'long');
coop = [b.coop];
stock_coop = round(P.stock * P.coop_ready);
m0 = {'pAClock',1, 'pDClock',1, ...
      'pYReady',P.stock - stock_coop, 'pCReady',stock_coop, 'pYFork',P.forklifts, ...
      'pYLong',sum(long & not(coop)), 'pYShort',sum(not(long) & not(coop)), 'pCHall',sum(coop), ...
      'pYRoom',P.hall_buffer, ...
      'pISpace',P.hall_space, 'pIStart',numel(global_info.floor), ...
      'pRMach',size(global_info.workshop{1}, 1), 'pRHb',size(global_info.workshop{2}, 1)};
W = yard_work(P);                       % forklift work, minutes per joint
yard = reshape([W.name; num2cell(W.minutes)], 1, []);
ft = yard;
for k = 1:P.wash_lanes
    ft = [ft, {sprintf('tWash_%d', k), P.wash_min}];
end
for s = global_info.S
    for t = s.ts
        ft = [ft, {t{1}, s.ft}];
    end
end

% GPenSIM ends a firing at the first time step at or after its end, so times
% between steps would all be rounded up; round them to the nearest step.
D = global_info.DELTA_TIME;
ft(2:2:end) = num2cell(max(D, round([ft{2:2:end}] / D) * D));
dyn.m0 = only(m0, {pns.global_places.name});
dyn.ft = [only(ft, {pns.global_transitions.name}), ...
          {'allothers', global_info.DELTA_TIME}];   % ports, hand-offs and skips: one step
% The pool: per level, the workers without a forklift certificate ('L1') and
% with one ('L1T').
assert(all(P.certified <= P.crew), 'P.certified: more certificates than people');
dyn.re = {};
for L = 0:3
    dyn.re = [dyn.re, {sprintf('L%d', L), P.crew(L+1) - P.certified(L+1), inf, ...
                       sprintf('L%dT', L), P.certified(L+1), inf}];
end


function pairs = only(pairs, names)
% Keep the name/value pairs whose name is in names.
keep = ismember(pairs(1:2:end), names);
pairs = pairs(reshape([keep; keep], 1, []));
