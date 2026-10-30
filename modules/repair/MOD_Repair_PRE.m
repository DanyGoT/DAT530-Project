function [fire, transition] = MOD_Repair_PRE(transition)
% Joints at the workshops are colourless, so global_info.workshop{w} keeps
% one row per joint: when its order's repair is done, and whether it goes
% through the hall again. A joint coming in reads its order from the joint
% the input port takes (COMMON_PRE takes the first). GPenSIM fires a
% transition as soon as its pre-processors say yes, so the row can be added
% here.

switch transition.name
    case 'tRInMach'
        fire = arrive('pIRMach', 1);
    case 'tRInHb'
        fire = arrive('pIRHb', 2);
    case 'tRMachHall'
        fire = back(1, true);
    case 'tRMachReady'
        fire = back(1, false);
    case 'tRHbHall'
        fire = back(2, true);
    case 'tRHbReady'
        fire = back(2, false);
end


function fire = arrive(place, w)
global global_info
[id, c] = find_token(place, @(tok) true);
fire = id > 0;
if not(fire), return, end
done = current_time() + global_info.repair(order_of(c), w)*1440;
again = rand < global_info.P.p_reinspect(w);
global_info.workshop{w}(end+1, :) = [done, again];


function fire = back(w, hall)
% A joint whose repair is done leaves workshop w, to the hall or to stock.
global global_info
q = global_info.workshop{w};
i = find(q(:, 1) <= current_time() & q(:, 2) == hall, 1);
fire = not(isempty(i));
if fire, global_info.workshop{w}(i, :) = []; end
