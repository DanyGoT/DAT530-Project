function names = hall_workers(levels)
% Who the hall or the wash may take for work of these levels: with_cert(levels),
% less those the yard is waiting for. Forklift work goes first: if it found no
% driver free in the last time step (global_info.yard_wants), no certified
% workers; if a lorry lacked helpers (yard_helpers), no L0 or L1 either, so
% they go to the lorry as they come free.
global global_info
names = with_cert(levels);
recent = current_time() - global_info.DELTA_TIME;
if global_info.yard_wants >= recent
    names = names(not(endsWith(names, 'T')));
end
if global_info.yard_helpers >= recent
    names = setdiff(names, {'L0', 'L1', 'L0T', 'L1T'}, 'stable');
end
