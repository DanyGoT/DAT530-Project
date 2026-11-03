function [fire, transition] = MOD_Departure_PRE(transition)
% The next joint asked for, once its time has come; shipping takes what comes.
% Drain test (P.ship_ready): every rig-ready joint is asked for at once.

global global_info

switch transition.name
    case 'tDTicket'
        if global_info.P.ship_ready
            fire = ntokens('pYReady') > ntokens('pDYOrder') + ntokens('pYOrder');
            return
        end
        i = global_info.next_demand;
        fire = i <= numel(global_info.demand) && global_info.demand(i) <= current_time();
    case 'tDShip'
        fire = 1;
end
