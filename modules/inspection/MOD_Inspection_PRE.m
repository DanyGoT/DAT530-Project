function [fire, transition] = MOD_Inspection_PRE(transition)
% The hall works during the shift. A free worker of a step's level (or
% higher) does the step on one joint. If the joint is scrap and this step can
% find it, it is found with probability 1/finds_left, so every finding step
% is equally likely to be the one. Joints already found scrap skip the steps
% marked skip. Nobody takes work below their level while a joint waits at a
% step of their own level (in any hall), so the one L3 is there for UT. A
% step in P.auto is a machine: it needs no worker. Every hall runs here: t is
% the transition's name in hall 1, h its hall (hall_of).

global global_info
[h, t] = hall_of(transition.name);

if strcmp(t, 'tIStart')       % at t = 0, before the first shift
    j = global_info.floor(global_info.next_floor);
    transition.new_color = {j.len, j.find, sprintf('order%d', j.order)};
    transition.override = 1;
    fire = 1;
    return
end
if strcmp(t, 'tIRoom')        % the credit goes back at once
    fire = 1;
    return
end
fire = in_shift(global_info.P);
if fire && strcmp(t, 'tIIn')  % for days in the yard: COMMON_PRE takes
    [~, c] = find_token(hall_name('pWI', h), @(tok) true);   % the first joint, and it fires now
    global_info.floor_in(end+1, :) = [current_time(), order_of(c)];
end
if fire && ismember(t, {'tIOk', 'tIMach', 'tIHb', 'tIScrap'})
    log_out(t, h);               % for lead times; it fires now
end
if not(fire) || ismember(t, {'tIIn', 'tIInRepair', 'tIOk', 'tIMach', 'tIHb', 'tIScrap'})
    return
end

s = global_info.S(global_info.step_of(t));
place = hall_name(s.place, h);
if strcmp(t, s.tskip)
    [id, c] = find_token(place, @(tok) has_color(tok.color, 'scrapped'));
    [fire, transition] = pick(transition, id, c);
    return
end
if s.skip
    [id, c] = find_token(place, @(tok) not(has_color(tok.color, 'scrapped')));
else
    [id, c] = find_token(place, @(tok) true);
end
if s.auto
    fire = id > 0;                             % a machine
else
    w = hall_workers(pool(s));                 % ask for the worker last
    fire = id > 0 && not(isempty(w)) && requestAR(w, 1);
end
if not(fire), return, end
if s.finds && has_color(c, 'scrap') && not(has_color(c, 'scrapped')) && rand < 1/s.finds_left
    c = [c, {'scrapped'}];
end
[~, transition] = pick(transition, id, c);


function levels = pool(s)
% Who may do step s: its level or higher, lowest first, except the higher
% levels that have work of their own waiting in any hall.
global global_info
S = global_info.S;
levels = {};
for L = s.level:3
    own = S([S.level] == L & not([S.auto]));
    waiting = cellfun(@ntokens, hall_name({own.place}, 1:global_info.P.halls));
    if L > s.level && any(waiting > 0), continue, end
    levels{end+1} = sprintf('L%d', L);
end


function log_out(name, h)
% The joint an exit port takes (COMMON_PRE picks the first with its
% outcome) and how it leaves: [time, order, how]. Joints back from repair
% carry no order (0).
global global_info
how = find(strcmp(name, {'tIOk', 'tIMach', 'tIHb', 'tIScrap'}));
outcome = {'ok', 'mach', 'hb', 'scrapped'};
[id, c] = find_token(hall_name('pIDone', h), @(tok) has_color(tok.color, outcome{how}));
if id == 0, return, end
order = 0;
if any(strncmp(c, 'order', 5)), order = order_of(c); end
global_info.hall_out(end+1, :) = [current_time(), order, how];
