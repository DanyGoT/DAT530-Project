% Main simulation file: one run of the pipe yard and its inspection hall.
%
% Joints of drill pipe come back from the rigs by lorry and are unloaded at
% one of two yards: Main, by the hall, or Coop. Most queue for the hall,
% where they are washed and inspected, and leave as rig-ready stock, as
% scrap, or for repair at an outside workshop; the rest go straight to
% stock. Customer tickets take rig-ready joints out again. One crew of four
% qualification levels (L0-L3) does the yard, the wash and the hall.
%
% Six modules (Arrival, Yard, Washing, Inspection, Repair, Departure) and the
% connectors between them (imc/). A token is one joint. In the yard a
% joint's kind is the place it is in; in the wash and the hall it carries
% its length, what inspection will find ('ok', 'mach', 'hb' or 'scrap'),
% its order, and 'scrapped' once scrap is found. Parameters: params.m.

clear all; clc;
global global_info

P = params();
% P.crew = [6 4 0 2];          % a scenario is a change to P, here the crew (L0-L3)

model_init(P);                  % arrivals, demand, start state and hall steps into global_info
pns = pnstruct(model_pdfs(P));  % P.halls = 2: a second hall with its own wash
pni = initialdynamics(pns, model_dyn(P, pns));   % marking, firing times, workers

Sim_Results = gpensim(pni);

out = hall_name({'tIOk', 'tIMach', 'tIHb', 'tIScrap'}, 1:P.halls);
n = sum(reshape(cellfun(@timesfired, out), 4, []), 2)';    % all halls
disp(['Joints arrived: ', int2str(global_info.next_pipe - 1), ...
      ' (and ', int2str(numel(global_info.backlog)), ' queued at the start)', ...
      ', inspected: ', int2str(sum(n)), ' (ok ', int2str(n(1)), ', machining ', int2str(n(2)), ...
      ', hardbanding ', int2str(n(3)), ', scrap ', int2str(n(4)), ...
      '), shipped: ', int2str(timesfired('tDShip'))]);
disp(['Back from the workshops: ', int2str(timesfired('tRMachHall') + timesfired('tRHbHall')), ...
      ' to the hall, ', int2str(timesfired('tRMachReady') + timesfired('tRHbReady')), ' to stock']);
weekdays = sum(mod(0:P.days-1, 7) < 5);
man_hours = sum(P.crew) * weekdays * diff(P.shift)/60;      % the whole crew, wash included
disp(['Joints per man-hour: ', num2str(sum(n)/man_hours, 2), ' (KPI 4, now ~3.3)']);
W = yard_work(P);
work = weekdays * diff(P.shift);                             % shift minutes per forklift
jobs = cellfun(@timesfired, W.name);
disp(['Yard: ', int2str(timesfired('tYFromCoopLong') + timesfired('tYFromCoopShort')), ...
      ' hall joints fetched from Coop, ', int2str(timesfired('tYForkToCoop')), ' forklift trips to Coop, ', ...
      'forklifts in use ', int2str(round(100*sum(jobs .* W.minutes)/(P.forklifts*work))), '% of the shift, ', ...
      num2str(sum(jobs .* W.minutes .* (1 + P.lorry_helpers*W.lorry))/60, 3), ' person-hours of yard work']);
prnschedule(Sim_Results);                                    % who worked how much (L1T: L1 with a forklift certificate)
plotp(Sim_Results, {'pYLong', 'pYShort', 'pWRack', 'pWI'});  % queue in front of the hall
plotp(Sim_Results, {'pISpace'});                             % free room on the hall floor
plotp(Sim_Results, {'pYReady', 'pCReady', 'pDYOrder'});      % stock at both yards and unmet demand
plotp(Sim_Results, {'pCHall', 'pAYLong', 'pAYCHall'});       % hall joints at Coop, and receipts at the gates
plotp(Sim_Results, {'pDShipped', 'pRMach', 'pRHb', 'pYScrap'});  % where joints went
