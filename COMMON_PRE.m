function [fire, transition] = COMMON_PRE(transition)
% The interface between the modules. GPenSIM only runs COMMON_PRE for port
% transitions; a module's own transitions run its MOD_<module>_PRE alone.
% Here: which joint an input port takes from its connector, and which colours
% an output port gives it. When a port may fire is the module's business
% (its MOD_<module>_PRE); both must say yes.
%
% Colours, as agreed between the modules:
%   Yard -> Washing -> Inspection  len ('long'/'short'), find ('ok', 'mach',
%                                  'hb' or 'scrap') and 'order<n>'
%   Inspection -> Repair           'order<n>' only
%   Repair -> Inspection           'ok' 'repaired'
%   everything else                no colours (credits, orders, stock)
% A port that takes a coloured joint picks it and gives its output exactly the
% joint's colours (override), so a space or credit token taken in the same
% firing never mixes its colours in.

global global_info
fire = 1;
t = transition.name;

switch t
    case {'tYLong', 'tYShort'}      % the yard's next hall joint gets its colours
        j = global_info.hall(global_info.next_hall);
        transition.new_color = {j.len, j.find, sprintf('order%d', j.order)};
        transition.override = 1;

    case 'tWIn'                     % the next joint from the yard
        [fire, transition] = first(transition, 'pYW');
    case 'tWOut'                    % the next washed joint
        [fire, transition] = first(transition, 'pWDone');
    case 'tIIn'
        [fire, transition] = first(transition, 'pWI');
    case 'tIInRepair'
        [fire, transition] = first(transition, 'pRI');
    case {'tIRoom', 'tYRoom'}       % a credit carries no colours
        transition.new_color = {};
        transition.override = 1;

    % Leaving the hall, by what inspection found.
    case 'tIOk'
        [id, ~] = find_token('pIDone', @(tok) has_color(tok.color, 'ok'));
        [fire, transition] = pick(transition, id, {});
    case 'tIScrap'
        [id, ~] = find_token('pIDone', @(tok) has_color(tok.color, 'scrapped'));
        [fire, transition] = pick(transition, id, {});
    case 'tIMach'
        [fire, transition] = to_repair(transition, 'mach');
    case 'tIHb'
        [fire, transition] = to_repair(transition, 'hb');

    case 'tRInMach'                 % colourless at the workshops
        [id, ~] = find_token('pIRMach', @(tok) true);
        [fire, transition] = pick(transition, id, {});
    case 'tRInHb'
        [id, ~] = find_token('pIRHb', @(tok) true);
        [fire, transition] = pick(transition, id, {});
    case {'tRMachHall', 'tRHbHall'}
        transition.new_color = {'ok', 'repaired'};
        transition.override = 1;
end


function [fire, transition] = first(transition, place)
% The first joint in place, with its colours.
[id, c] = find_token(place, @(tok) true);
[fire, transition] = pick(transition, id, c);


function [fire, transition] = to_repair(transition, color)
% A joint for the workshop keeps only its order: the repair time is per order.
[id, c] = find_token('pIDone', @(tok) has_color(tok.color, color));
fire = id > 0;
if not(fire), return, end
[~, transition] = pick(transition, id, {sprintf('order%d', order_of(c))});
