function [fire, transition] = MOD_Washing_PRE(transition)
% Washing goes in arrival order, so the joints of an order stay together.
% tWIn and tWOut pass joints on as soon as they come (COMMON_PRE picks them).
% A lane washes the first joint on the rack during the shift, with a free
% worker of P.wash_crew (lowest level first). With 'Wash' in P.auto the unit
% needs no one.

global global_info
P = global_info.P;

if ismember(transition.name, {'tWIn', 'tWOut'})
    fire = 1;
    return
end
fire = in_shift(P);
if not(fire), return, end
[id, c] = find_token('pWRack', @(tok) true);
fire = id > 0;
if fire && not(ismember('Wash', P.auto))
    w = hall_workers(P.wash_crew);
    fire = not(isempty(w)) && requestAR(w, 1);
end
if fire
    [~, transition] = pick(transition, id, c);
end
