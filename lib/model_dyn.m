function dyn = model_dyn(P, pns)
% Initial dynamics: marking, firing times and workers. Entries for places and
% transitions that pns doesn't have are left out, so a test can run a few
% modules on their own.

global global_info

m0 = {'pAClock',1, 'pDClock',1, 'pWIdle',1, 'pWShort',1, ...
      'pISpace',P.hall_space, 'pYReady',P.stock};
ft = {'tALong',P.unload, 'tAShort',P.unload, 'tABypass',P.unload, ...
      'tWMobilize',P.mobilize, 'tWDemobilize',P.demobilize, ...
      'tWToLong',P.change, 'tWToShort',P.change, 'tWLong',P.wash(1), 'tWShort',P.wash(2)};
for s = global_info.S
    for t = s.ts
        ft = [ft, {t{1}, s.ft}];
    end
end

dyn.m0 = only(m0, {pns.global_places.name});
dyn.ft = [only(ft, {pns.global_transitions.name}), ...
          {'allothers', global_info.DELTA_TIME}];   % hand-offs and skips: one step
dyn.re = {'L0',P.crew(1),inf, 'L1',P.crew(2),inf, 'L2',P.crew(3),inf, 'L3',P.crew(4),inf};


function pairs = only(pairs, names)
% Keep the name/value pairs whose name is in names.
keep = ismember(pairs(1:2:end), names);
pairs = pairs(reshape([keep; keep], 1, []));
