function dyn = model_dyn(P, pns)
% Initial dynamics: marking, firing times and workers. Entries for places and
% transitions that pns doesn't have are left out, so a test can run a few
% modules on their own.

global global_info

long = strcmp({global_info.backlog.len}, 'long');
m0 = {'pAClock',1, 'pDClock',1, ...
      'pYReady',P.stock, 'pYLong',sum(long), 'pYShort',sum(not(long)), ...
      'pYRoom',P.hall_buffer, 'pWOff',1, ...
      'pISpace',P.hall_space, 'pIStart',numel(global_info.floor), ...
      'pRMach',size(global_info.workshop{1}, 1), 'pRHb',size(global_info.workshop{2}, 1)};
ft = {'tALong',P.unload, 'tAShort',P.unload, 'tABypass',P.unload, ...
      'tWMobilize',P.mobilize, 'tWDemobilize',P.demobilize};
for k = 1:P.wash_lanes                  % lanes start set up for long
    n = @(name) sprintf('%s_%d', name, k);
    m0 = [m0, {n('pWLong'),1}];
    ft = [ft, {n('tWToLong'),P.change, n('tWToShort'),P.change, ...
               n('tWLong'),P.wash(1), n('tWShort'),P.wash(2)}];
end
for s = global_info.S
    for t = s.ts
        ft = [ft, {t{1}, s.ft}];
    end
end

dyn.m0 = only(m0, {pns.global_places.name});
dyn.ft = [only(ft, {pns.global_transitions.name}), ...
          {'allothers', global_info.DELTA_TIME}];   % ports, hand-offs and skips: one step
dyn.re = {'L0',P.crew(1),inf, 'L1',P.crew(2),inf, 'L2',P.crew(3),inf, 'L3',P.crew(4),inf};


function pairs = only(pairs, names)
% Keep the name/value pairs whose name is in names.
keep = ismember(pairs(1:2:end), names);
pairs = pairs(reshape([keep; keep], 1, []));
