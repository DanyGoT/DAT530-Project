function [fire, transition] = COMMON_PRE(transition)
% Every transition passes through here; the model has no specific pre files.
%
% Colours live only in the wash and the hall. A joint gets them leaving the
% yard (its length, what inspection will find, its order) and loses them
% leaving the hall. GPenSIM copies every coloured token after each firing,
% so colourless joints in the yard, stock and workshops keep runs fast.
%
% A transition that moves a coloured joint picks the joint itself and gives
% its output exactly that joint's colours (override), so the machine and
% space tokens in the same firing never mix their colours into a joint.

global global_info
P = global_info.P;
t = transition.name;
fire = 0;

% The yard and the halls work during the shift; arrivals, tickets and workshops don't stop.
if not(ismember(t, {'tALong', 'tAShort', 'tABypass', 'tDTicket', 'tRMach', 'tRHb'})) ...
        && not(in_shift(P))
    return
end

switch t
    case 'tALong'                   % the next joint, once its time has come
        fire = next_arrival('hall', 'long');
    case 'tAShort'
        fire = next_arrival('hall', 'short');
    case 'tABypass'
        fire = next_arrival('bypass', '');

    case 'tDTicket'                 % the next joint asked for, once its time has come
        i = global_info.next_demand;
        fire = i <= numel(global_info.demand) && global_info.demand(i) <= current_time();

    case {'tDShip', 'tWDemobilize'}
        fire = 1;

    case 'tYLong'                   % hall joints leave the yard in arrival order
        [fire, transition] = to_wash(transition, 'long');
    case 'tYShort'
        [fire, transition] = to_wash(transition, 'short');

    % Washing goes in arrival order, so the joints of an order stay together.
    case 'tWMobilize'
        fire = ntokens('pWBuf') > 0;
    case 'tWToLong'
        fire = next_is('pWBuf', 'long');
    case 'tWToShort'
        fire = next_is('pWBuf', 'short');
    case 'tWLong'
        [fire, transition] = wash(transition, 'long');
    case 'tWShort'
        [fire, transition] = wash(transition, 'short');

    % Leaving the hall, by what inspection found; the joint loses its colours.
    case 'tIOk'
        [fire, transition] = leave(transition, 'ok');
    case 'tIMach'
        [fire, transition] = leave(transition, 'mach');
    case 'tIHb'
        [fire, transition] = leave(transition, 'hb');
    case 'tIScrap'
        [fire, transition] = leave(transition, 'scrapped');

    % Back from the workshop when the repair time is up; ok now.
    case 'tRMach'
        [fire, transition] = back(transition, 'pRMach', P.repair_days(1));
    case 'tRHb'
        [fire, transition] = back(transition, 'pRHb', P.repair_days(2));

    otherwise                       % a step in the hall, or its skip
        [fire, transition] = step(transition, global_info);
end


function [fire, transition] = step(transition, global_info)
% A free worker of the step's level (or higher) does the step on one joint.
% If the joint is scrap and this step can find it, it is found with
% probability 1/finds_left, so every finding step is equally likely to be
% the one. Joints already found scrap skip the steps marked skip.
s = global_info.S(global_info.step_of(transition.name));
if strcmp(transition.name, s.tskip)
    [id, c] = find_token(s.place, @(tok) has(tok.color, 'scrapped'));
    [fire, transition] = select(transition, id, c);
    return
end
if s.skip
    [id, c] = find_token(s.place, @(tok) not(has(tok.color, 'scrapped')));
else
    [id, c] = find_token(s.place, @(tok) true);
end
fire = id > 0 && requestAR(s.pool, 1);         % ask for the worker last
if not(fire), return, end
if s.finds && has(c, 'scrap') && not(has(c, 'scrapped')) && rand < 1/s.finds_left
    c = [c, {'scrapped'}];
end
[~, transition] = select(transition, id, c);


function fire = next_arrival(route, len)
global global_info
i = global_info.next_pipe;
fire = 0;
if i > numel(global_info.pipes), return, end
p = global_info.pipes(i);
fire = p.t <= current_time() && strcmp(p.route, route) && (isempty(len) || strcmp(p.len, len));


function [fire, transition] = to_wash(transition, len)
% The next hall joint in arrival order, if it has this length, gets its colours.
global global_info
fire = 0;
i = global_info.next_hall;
if i > numel(global_info.hall), return, end
j = global_info.hall(i);
if not(strcmp(j.len, len)), return, end
transition.new_color = {j.len, j.find, sprintf('order%d', j.order)};
transition.override = 1;
fire = 1;


function [fire, transition] = wash(transition, len)
% Wash the next joint if the machine is set up for its length; needs a worker.
fire = 0;
if not(next_is('pWBuf', len)), return, end
[id, c] = find_token('pWBuf', @(tok) true);
fire = requestAR({'L0', 'L1', 'L2', 'L3'}, 1);
if fire, [~, transition] = select(transition, id, c); end


function [fire, transition] = leave(transition, color)
[id, ~] = find_token('pIDone', @(tok) has(tok.color, color));
[fire, transition] = select(transition, id, {});


function [fire, transition] = select(transition, id, colors)
fire = id > 0;
transition.selected_tokens = id;
transition.new_color = colors;
transition.override = 1;


function [id, colors] = find_token(place, test)
% The first token in place that passes test (0 and {} if none).
p = get_place(place);
for tok = p.token_bank
    if test(tok)
        id = tok.tokID;
        colors = reshape(tok.color, 1, []);
        return
    end
end
id = 0; colors = {};


function yes = next_is(place, color)
[id, c] = find_token(place, @(tok) true);
yes = id > 0 && has(c, color);


function [fire, transition] = back(transition, place, days)
% The oldest joint at a workshop comes back once its repair time is over.
fire = 0;
p = get_place(place);
if isempty(p.token_bank), return, end
tok = p.token_bank(1);
if tok.creation_time + days*1440 > current_time(), return, end
[fire, transition] = select(transition, tok.tokID, {'ok', 'repaired'});


function yes = has(colors, color)
yes = any(strcmp(colors, color));


function on = in_shift(P)
now = current_time();
on = mod(floor(now/1440), 7) < 5 && mod(now, 1440) >= P.shift(1) && mod(now, 1440) < P.shift(2);
