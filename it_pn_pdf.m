% PDF: it_pn_pdf.m
%
% %%%%%%%   IT avdeling
% IT keeps track of every pipe. Each place is a status register, and every
% hand-over between Logistics and Operations goes through an IT transition:
%
%   incoming -> ready for washing -> ready for inspection
%            -> ready to ship | ready for easy/hard repair -> repair done -> ready to ship
%            -> scrapped
%
% Places owned by other modules (pL*, pO*) are the department "out trays".

function [pns] = it_pn_pdf()
global global_info
cfg = global_info.cfg;

pns.PN_name = 'IT';
pns.set_of_Ps = {'pIIncoming', 'pIReadyForWash', 'pIReadyForInspection', ...
    'pIReadyForEasyRepair', 'pIReadyForHardRepair', 'pIRepairDone', ...
    'pIReadyToShip', 'pIScrapped'};
pns.set_of_Ts = {};
pns.set_of_As = {};

% Incoming trucks: each notice token fires at the truck's arrival time
for truck = 1:height(cfg.incoming)
    notice = sprintf('pIArrivalNotice%d', truck);
    arrival = sprintf('tIArrival%d', truck);
    pns.set_of_Ps{end+1} = notice;
    pns.set_of_Ts{end+1} = arrival;
    pns.set_of_As = [pns.set_of_As, pipe_yard_task(arrival, ...
        {notice, 1}, {'pIIncoming', cfg.incoming.Pipes(truck)})];
end

%            transition              from            to
registers = {'tIRegisterUnloaded',   'pLUnloaded',   'pIReadyForWash'; ...
             'tIRegisterWashed',     'pOWashed',     'pIReadyForInspection'; ...
             'tIRegisterPassed',     'pOPassed',     'pIReadyToShip'; ...
             'tIRegisterEasyRepair', 'pOEasyRepair', 'pIReadyForEasyRepair'; ...
             'tIRegisterHardRepair', 'pOHardRepair', 'pIReadyForHardRepair'; ...
             'tIRegisterRepaired',   'pORepaired',   'pIRepairDone'; ...
             'tIReleaseRepaired',    'pIRepairDone', 'pIReadyToShip'; ...
             'tIRegisterScrap',      'pOScrap',      'pIScrapped'};
for row = 1:size(registers, 1)
    pns.set_of_Ts{end+1} = registers{row, 1};
    pns.set_of_As = [pns.set_of_As, pipe_yard_task(registers{row, 1}, ...
        {registers{row, 2}, 1}, {registers{row, 3}, 1})];
end

pns.set_of_Ports = setdiff(registers(:, 1)', {'tIReleaseRepaired'}, 'stable');
end
