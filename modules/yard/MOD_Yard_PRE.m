function [fire, transition] = MOD_Yard_PRE(transition)
% The yard works during the shift. Hall joints leave for the wash in the
% order of global_info.hall, so the joints of an order stay together; a joint
% unloaded at Coop must have been fetched to Main first. With two halls, each
% takes whole orders (next_joint) through its own feeds (t is the name in
% hall 1, h the hall). Every move of a joint
% is forklift work: the arcs take a forklift at that yard, and here a
% certified worker drives it, with P.lorry_helpers more people when a lorry
% is loaded or unloaded. Conditions are checked first, workers asked for last.
% At Main, feeding the wash goes before unloading and storing.

global global_info
P = global_info.P;
% Joints and forklifts in the yards carry no colours. GPenSIM gives every
% output token of a firing the same colours, so tYLong/tYShort hand their
% forklift back with the joint's colours (COMMON_PRE); the next job drops them.
transition.new_color = {};
transition.override = 1;
fire = in_shift(P);
if not(fire), return, end
[h, t] = hall_of(transition.name);

switch t
    case {'tYLong', 'tYShort'}                  % hall h's next joint, if it is at Main
        fire = next_hall_is(lower(t(3:end)), h);
    case {'tYFromCoopLong', 'tYFromCoopShort'}  % the lorry from Coop is here
        q = global_info.lorry;                  % (first, if a hall waits for a joint on it)
        fire = not(isempty(q)) && q(1, 2) + P.lorry_drive <= current_time() ...
               && q(1, 3) == strcmp(t, 'tYFromCoopLong') && (on_lorry() || not(main_urgent()));
    case 'tYStoreCoop'                          % the lorry from the hall is at Coop
        q = global_info.coop_q;
        fire = not(isempty(q)) && q(1) + P.lorry_drive <= current_time();
    case 'tYFetch'                              % a Coop bundle whose turn is near
        fire = not(isempty(fetchable()));
    case {'tYOrder', 'tYOrderCoop'}             % from the yard that holds the stock
        if isnan(global_info.ship_coop)
            stock = [ntokens('pYReady'), ntokens('pCReady')];
            global_info.ship_coop = sum(stock) > 0 && rand < stock(2)/sum(stock);
        end
        fire = global_info.ship_coop == strcmp(t, 'tYOrderCoop');
        return                                  % paperwork: no one needed
    case 'tYForkToCoop'
        fire = send_fork(P);
    case 'tYForkToMain'
        fire = coop_work() == 0;
    case 'tYRoom'
        return
    case {'tYInLong', 'tYInShort', 'tYInBypass', 'tYInOk', 'tYInOkCoop', 'tYInScrap', 'tYInRepaired'}
        fire = not(main_urgent());              % feeding the wash goes first
end
if fire
    fire = workers(t, P);
end
if fire && ismember(t, {'tYLong', 'tYShort'})   % its order is hall h's from now on
    global_info.order_hall(global_info.hall_orders(next_joint(h))) = h;
end


function ok = workers(t, P)
% A certified driver, and helpers at a lorry: L0 and L1 without a
% certificate first, so the other drivers stay free, then the rest. Forklift
% work goes first: if no driver is free, the hall and the wash leave the
% certified workers alone for the next step (global_info.yard_wants); if
% helpers are missing, L0 and L1 too (yard_helpers), so a lorry crew gathers
% as people come free (hall_workers).
global global_info
ok = requestAR(strcat({'L0', 'L1', 'L2', 'L3'}, 'T'), 1);
if not(ok)
    global_info.yard_wants = current_time();
elseif P.lorry_helpers > 0 && global_info.lorry_job(t)
    ok = requestAR({'L0', 'L1', 'L0T', 'L1T', 'L2', 'L2T', 'L3', 'L3T'}, P.lorry_helpers);
    if not(ok), global_info.yard_helpers = current_time(); end
end


function yes = main_urgent()
% At Main, a wash has a credit and waits for its next joint, which is in the
% yard or on the lorry from Coop: feeding it, or unloading that lorry, goes
% before unloading and storing. Other forklift jobs (shipping) take turns.
global global_info
yes = false;
for h = 1:global_info.P.halls
    yes = yes || (ntokens(hall_name('pYRoom', h)) > 0 ...
                  && (next_hall_is('long', h) || next_hall_is('short', h) || on_lorry(h)));
end


function yes = next_hall_is(len, h)
% Hall h's next joint has this length and is at Main: arrived there, or
% fetched from Coop, and the yard has a joint of that length to feed (one
% that has arrived may still be on its lorry at the gate).
global global_info
i = next_joint(h);
yes = i > 0;
if not(yes), return, end
j = global_info.hall(i);
here = (j.coop && global_info.cstate(j.id) == 3) || (not(j.coop) && j.t <= current_time());
yes = here && strcmp(j.len, len) && ntokens(['pY', upper(len(1)), len(2:end)]) > 0;


function yes = on_lorry(H)
% A hall in H (all by default) has a credit and its next joint is on a lorry
% from Coop.
global global_info
if nargin == 0, H = 1:global_info.P.halls; end
yes = false;
for h = H
    i = next_joint(h);
    if i > 0 && ntokens(hall_name('pYRoom', h)) > 0
        j = global_info.hall(i);
        yes = yes || (j.coop && global_info.cstate(j.id) == 2);
    end
end


function k = fetchable()
% Places in the hall list of the Coop bundles at Coop that are among the
% first P.fetch_ahead joints still in the yard, per hall (so a big order for
% one hall doesn't keep the other's waiting at Coop); the first is fetched next.
global global_info
P = global_info.P;
i = global_info.next_hall;
k = i - 1 + find(not(global_info.sent(i:end)), P.halls * P.fetch_ahead);
h = global_info.hall(k);
k = k([h.coop] & global_info.cstate([h.id]) == 1);


function n = coop_work()
% Joints waiting for a forklift at Coop: receipts at the gate, lorries from
% the hall, bundles to fetch, and joints asked for that Coop has.
global global_info
P = global_info.P;
n = ntokens('pAYCHall') + ntokens('pAYCBypass') + numel(fetchable()) ...
    + sum(global_info.coop_q + P.lorry_drive <= current_time()) ...
    + min(ntokens('pCOrder'), ntokens('pCReady'));


function yes = send_fork(P)
% One forklift goes to Coop when none is there or on its way, and enough work
% waits there (P.coop_batch joints), or some has waited P.coop_wait minutes.
global global_info
n = coop_work();
if n == 0
    global_info.coop_since = nan;
elseif isnan(global_info.coop_since)
    global_info.coop_since = current_time();
end
yes = global_info.forks_coop == 0 && n > 0 ...
      && (n >= P.coop_batch || current_time() - global_info.coop_since >= P.coop_wait);
