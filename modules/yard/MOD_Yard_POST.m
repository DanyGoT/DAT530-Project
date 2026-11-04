function [] = MOD_Yard_POST(transition)
% Hand back the workers, and keep the yards' books: which hall joints are at
% Coop, on a lorry or at Main, and what is on the lorries. On to the next
% hall joint.
global global_info
t = transition.name;
if not(ismember(t, {'tYRoom', 'tYOrder', 'tYOrderCoop'}))
    release();
end
switch t
    case {'tYLong', 'tYShort'}
        j = global_info.hall(global_info.next_hall);     % for days in the yard
        global_info.yard_out(end+1, :) = [current_time(), j.t, j.order];
        global_info.next_hall = global_info.next_hall + 1;
    case 'tYInCHall'                        % unloaded at Coop
        id = global_info.coop_ids(global_info.coop_next);
        global_info.cstate(id) = 1;
        global_info.coop_next = global_info.coop_next + 1;
    case 'tYFetch'                          % loaded onto a lorry to Main
        id = fetched();
        global_info.cstate(id) = 2;
        j = global_info.hall([global_info.hall.id] == id);
        global_info.lorry(end+1, :) = [id, current_time(), strcmp(j.len, 'long')];
    case {'tYFromCoopLong', 'tYFromCoopShort'}   % unloaded at Main
        global_info.cstate(global_info.lorry(1, 1)) = 3;
        global_info.lorry(1, :) = [];
    case 'tYInOkCoop'                       % loaded onto a lorry to Coop
        global_info.coop_q(end+1, 1) = current_time();
    case 'tYStoreCoop'
        global_info.coop_q(1) = [];
    case {'tYOrder', 'tYOrderCoop'}         % the next joint asked for is drawn afresh
        global_info.ship_coop = nan;
    case 'tYForkToCoop'
        global_info.forks_coop = global_info.forks_coop + 1;
    case 'tYForkToMain'
        global_info.forks_coop = global_info.forks_coop - 1;
end


function id = fetched()
% The Coop bundle tYFetch loaded: the first at Coop in the hall list from the
% front (MOD_Yard_PRE picked it within P.fetch_ahead).
global global_info
h = global_info.hall(global_info.next_hall:end);
ids = [h.id];
id = ids(find([h.coop] & global_info.cstate(ids) == 1, 1));
