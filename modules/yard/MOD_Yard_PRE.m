function [fire, transition] = MOD_Yard_PRE(transition)
% The yard works during the shift. Hall joints leave for the wash in the
% order of global_info.hall, so the joints of an order stay together; a joint
% unloaded at Coop must have been fetched to Main first. Every move of a joint
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
t = transition.name;

switch t
    case {'tYLong', 'tYShort'}                  % the next hall joint, if it is at Main
        fire = next_hall_is(lower(t(3:end)));
    case {'tYFromCoopLong', 'tYFromCoopShort'}  % the lorry from Coop is here
        q = global_info.lorry;
        fire = not(isempty(q)) && q(1, 2) + P.lorry_drive <= current_time() ...
               && q(1, 3) == strcmp(t, 'tYFromCoopLong') && not(main_urgent());
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
% At Main, the wash waits for its next joint (it is there and there is a
% credit): feeding it goes before unloading and storing. Other forklift jobs
% (shipping, unloading) take turns.
yes = ntokens('pYRoom') > 0 && (next_hall_is('long') || next_hall_is('short'));


function yes = next_hall_is(len)
% The next hall joint has this length and is at Main: arrived there, or
% fetched from Coop.
global global_info
i = global_info.next_hall;
yes = i <= numel(global_info.hall);
if not(yes), return, end
j = global_info.hall(i);
here = (j.coop && global_info.cstate(j.id) == 3) || (not(j.coop) && j.t <= current_time());
yes = here && strcmp(j.len, len);


function k = fetchable()
% Places in the hall list of the Coop bundles at Coop that are within
% P.fetch_ahead joints of the front; the first is fetched next.
global global_info
i = global_info.next_hall;
h = global_info.hall(i:min(end, i + global_info.P.fetch_ahead - 1));
ids = [h.id];
k = i - 1 + find([h.coop] & global_info.cstate(ids) == 1);


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
