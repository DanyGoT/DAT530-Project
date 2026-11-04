function i = next_joint(h)
% Where in the hall list (global_info.hall) the next joint for hall h is, 0
% if there is none. A hall takes whole orders (batches): the next joint of
% the order it is on, and once it has all of that, the first joint of the
% next order no hall has yet. With two halls, that order goes to the hall
% with the most room (free floor and credits) of those with none of their
% own; ties to the first. MOD_Yard_PRE gives the order to the hall
% (global_info.order_hall) as its first joint leaves the yard.
global global_info
g = global_info;
rest = g.next_hall:numel(g.hall);
own = g.order_hall(g.hall_orders(rest));        % per joint: its order's hall, 0 none yet
i = rest(find(own == h & not(g.sent(rest)), 1));
if not(isempty(i)), return, end
i = 0;
k = find(own == 0, 1);
if isempty(k), return, end
for o = [1:h-1, h+1:g.P.halls]                 % the other halls
    busy = any(own == o & not(g.sent(rest)));
    if not(busy) && (room(o) > room(h) || (room(o) == room(h) && o < h)), return, end
end
i = rest(k);


function r = room(h)
r = ntokens(hall_name('pISpace', h)) + ntokens(hall_name('pYRoom', h));
