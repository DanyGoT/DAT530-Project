function [fire, transition] = COMMON_PRE(transition)
% The ports between the modules: which joint an input port takes from its
% connector, and which colours an output port gives it. When a port may fire
% is decided by its module (MOD_<module>_PRE).
%
% Colours, as agreed between the modules:
%   Yard -> Washing -> Inspection  len ('long'/'short'), find ('ok', 'mach',
%                                  'hb' or 'scrap') and 'order<n>'
%   Inspection -> Repair           'order<n>' only
%   Inspection -> Yard (ok)        'order<n>' (none if back from repair): the yard
%                                  stores it at Main or Coop by order (to_coop)
%   Repair -> Inspection           'ok' 'repaired'
%   everything else                no colours (credits, orders, stock)
% A port that takes a joint gives its output exactly the joint's colours
% (override), so a floor space or credit taken in the same firing adds none.
% A hall's ports go by their name in hall 1 (t); h is the hall (hall_of).

global global_info
fire = 1;
[h, t] = hall_of(transition.name);

switch t
    case {'tYLong', 'tYShort'}      % hall h's next joint from the yard gets its colours
        i = next_joint(h);
        if i == 0, return, end      % none: MOD_Yard_PRE says no
        j = global_info.hall(i);
        transition.new_color = {j.len, j.find, sprintf('order%d', j.order)};
        transition.override = 1;

    case 'tWIn'                     % the next joint from the yard
        [fire, transition] = first(transition, hall_name('pYW', h));
    case 'tWOut'                    % the next washed joint
        [fire, transition] = first(transition, hall_name('pWDone', h));
    case 'tIIn'
        [fire, transition] = first(transition, hall_name('pWI', h));
    case 'tIInRepair'
        [fire, transition] = first(transition, 'pRI');
    case {'tIRoom', 'tYRoom'}       % a credit carries no colours
        transition.new_color = {};
        transition.override = 1;

    % Leaving the hall, by what inspection found.
    case 'tIOk'                     % keeps its order: the yard stores it by order
        [id, c] = find_token(hall_name('pIDone', h), @(tok) has_color(tok.color, 'ok'));
        [fire, transition] = pick(transition, id, c(strncmp(c, 'order', 5)));
    case 'tIScrap'
        [id, ~] = find_token(hall_name('pIDone', h), @(tok) has_color(tok.color, 'scrapped'));
        [fire, transition] = pick(transition, id, {});
    case 'tIMach'
        [fire, transition] = to_repair(transition, 'mach', h);
    case 'tIHb'
        [fire, transition] = to_repair(transition, 'hb', h);

    case 'tRInMach'                 % colourless at the workshops
        [id, ~] = find_token('pIRMach', @(tok) true);
        [fire, transition] = pick(transition, id, {});
    case 'tRInHb'
        [id, ~] = find_token('pIRHb', @(tok) true);
        [fire, transition] = pick(transition, id, {});
    case 'tYInOk'                   % into a rack at Main, colourless
        [id, ~] = find_token('pIYOk', @(tok) not(to_coop(tok.color)));
        [fire, transition] = pick(transition, id, {});
    case 'tYInOkCoop'               % onto a lorry to Coop, colourless
        [id, ~] = find_token('pIYOk', @(tok) to_coop(tok.color));
        [fire, transition] = pick(transition, id, {});

    case {'tRMachHall', 'tRHbHall'}
        transition.new_color = {'ok', 'repaired'};
        transition.override = 1;
end


function [fire, transition] = first(transition, place)
% The first joint in place, with its colours.
[id, c] = find_token(place, @(tok) true);
[fire, transition] = pick(transition, id, c);


function [fire, transition] = to_repair(transition, color, h)
% A joint for the workshop keeps only its order: the repair time is per order.
[id, c] = find_token(hall_name('pIDone', h), @(tok) has_color(tok.color, color));
fire = id > 0;
if not(fire), return, end
[~, transition] = pick(transition, id, {sprintf('order%d', order_of(c))});


function yes = to_coop(colors)
% The joint's order stores its rig-ready joints at Coop. Joints back from
% repair carry no order and go to Main.
global global_info
yes = any(strncmp(colors, 'order', 5)) && global_info.to_coop(order_of(colors));
