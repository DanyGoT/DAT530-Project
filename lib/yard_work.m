function W = yard_work(P)
% The yard's forklift work: one row per transition, with its minutes per joint
% (times per bundle of P.bundle joints) and whether a lorry is loaded or
% unloaded (then P.lorry_helpers more people). model_dyn takes the firing
% times from here, run_model the forklift and driver hours.

[u, l, s, us, f] = deal(P.t_unload/P.bundle, P.t_load/P.bundle, P.t_store/P.bundle, ...
                        P.t_unstore/P.bundle, P.t_feed/P.bundle);
%       transition          min/joint     lorry   what
rows = {'tYInLong',         u,            true    % unload a receipt at Main
        'tYInShort',        u,            true
        'tYInBypass',       u + s,        true    % ... and rack it (storage only)
        'tYInCHall',        u,            true    % unload a receipt at Coop
        'tYInCBypass',      u + s,        true
        'tYLong',           f,            false   % yard -> wash
        'tYShort',          f,            false
        'tYInOk',           s,            false   % hall -> rack at Main
        'tYInScrap',        s,            false
        'tYInRepaired',     u + s,        true    % back from a workshop, into a rack
        'tYInOkCoop',       l,            true    % hall -> lorry to Coop
        'tYStoreCoop',      u + s,        true    % lorry -> rack at Coop
        'tYFetch',          l,            true    % Coop bundle -> lorry to Main
        'tYFromCoopLong',   u,            true    % lorry -> Main
        'tYFromCoopShort',  u,            true
        'tYShip',           us + l,       true    % rack -> customer's lorry
        'tYShipCoop',       us + l,       true
        'tYForkToCoop',     P.fork_drive, false   % drive a forklift over
        'tYForkToMain',     P.fork_drive, false};
feed = rows(ismember(rows(:, 1), {'tYLong', 'tYShort'}), :);
for h = 2:P.halls                       % the other halls' feeds
    rows = [rows; hall_name(feed(:, 1), h)', feed(:, 2:3)];
end
W.name    = rows(:, 1)';
W.minutes = [rows{:, 2}];
W.lorry   = [rows{:, 3}];
