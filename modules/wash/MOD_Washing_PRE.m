function [fire, transition] = MOD_Washing_PRE(transition)
% Washing goes in arrival order, so the joints of an order stay together.
% tWIn and tWOut pass joints on as soon as they come (COMMON_PRE picks them).
% A lane washes the first joint on the rack during the shift, with a free
% worker of P.wash_crew (lowest level first). With 'Wash' in P.auto the unit
% needs no one. Every hall's wash runs here (hall_of).

global global_info
P = global_info.P;

[h, t] = hall_of(transition.name);
if ismember(t, {'tWIn', 'tWOut'})
    fire = 1;
    return
end
fire = in_shift(P);
if not(fire), return, end
[id, c] = find_token(hall_name('pWRack', h), @(tok) true);
fire = id > 0;
if fire && not(ismember('Wash', P.auto))
    w = hall_workers(P.wash_crew);
    fire = not(isempty(w)) && requestAR(w, 1);
end
if fire
    [~, transition] = pick(transition, id, c);
end
