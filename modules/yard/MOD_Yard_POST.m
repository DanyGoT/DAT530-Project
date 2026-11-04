function [] = MOD_Yard_POST(transition)
% Hand back the workers, and keep the yards' books: which hall joints are at
% Coop, on a lorry or at Main, and what is on the lorries. On to the next
% hall joint. Short orders go to the wash in runs, as in the hall data: when
% a short order is done and the run is under P.short_run joints, the next
% short order already at Main is brought forward.
global global_info
t = transition.name;
if not(ismember(t, {'tYRoom', 'tYOrder', 'tYOrderCoop'}))
    release();
end
switch t
    case 'tYLong'
        global_info.run = 0;
    case 'tYShort'
        global_info.run = global_info.run + 1;
    case 'tYInCHall'                        % unloaded at Coop
        id = global_info.coop_ids(global_info.coop_next);
        global_info.cstate(id) = 1;
        global_info.coop_next = global_info.coop_next + 1;
        return
    case 'tYFetch'                          % loaded onto a lorry to Main
        id = fetched();
        global_info.cstate(id) = 2;
        j = global_info.hall([global_info.hall.id] == id);
        global_info.lorry(end+1, :) = [id, current_time(), strcmp(j.len, 'long')];
        return
    case {'tYFromCoopLong', 'tYFromCoopShort'}   % unloaded at Main
        global_info.cstate(global_info.lorry(1, 1)) = 3;
        global_info.lorry(1, :) = [];
        return
    case 'tYInOkCoop'                       % loaded onto a lorry to Coop
        global_info.coop_q(end+1, 1) = current_time();
        return
    case 'tYStoreCoop'
        global_info.coop_q(1) = [];
        return
    case {'tYOrder', 'tYOrderCoop'}         % the next joint asked for is drawn afresh
        global_info.ship_coop = nan;
        return
    case 'tYForkToCoop'
        global_info.forks_coop = global_info.forks_coop + 1;
        return
    case 'tYForkToMain'
        global_info.forks_coop = global_info.forks_coop - 1;
        return
    otherwise
        return
end
j = global_info.hall(global_info.next_hall);         % for days in the yard
global_info.yard_out(end+1, :) = [current_time(), j.t, j.order];
global_info.next_hall = global_info.next_hall + 1;
if strcmp(t, 'tYShort') && global_info.run < global_info.P.short_run
    next_short();
end


function id = fetched()
% The Coop bundle tYFetch loaded: the first at Coop in the hall list from the
% front (MOD_Yard_PRE picked it within P.fetch_ahead).
global global_info
h = global_info.hall(global_info.next_hall:end);
ids = [h.id];
id = ids(find([h.coop] & global_info.cstate(ids) == 1, 1));


function [] = next_short()
% Bring the next short order forward, if all of it is at Main. Short joints
% keep their order among themselves, so the first ntokens('pYShort') short
% joints left in the list are roughly the ones at Main; a Coop joint must
% have been fetched, a Main joint must have arrived.
global global_info
h = global_info.hall;
i = global_info.next_hall;
if i > numel(h) || strcmp(h(i).len, 'short'), return, end   % the order goes on
k = i - 1 + find(strcmp({h(i:end).len}, 'short'), 1);
if isempty(k), return, end
in = find([h(k:end).order] == h(k).order) + k - 1;           % an order's joints are together
if numel(in) > ntokens('pYShort'), return, end
coop = [h(in).coop];
if any(coop & global_info.cstate([h(in).id]) ~= 3) || any(not(coop) & [h(in).t] > current_time())
    return
end
n = numel(in);
global_info.hall = h([1:i-1, k:k+n-1, i:k-1, k+n:end]);
