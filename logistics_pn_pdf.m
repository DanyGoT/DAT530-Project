% PDF: logistics_pn_pdf.m
%
% %%%%%%%   Logistikk avdeling
% Unloading: incoming truck (pIIncoming) -> yard (pLUnloaded).
%   Needs a forklift, free yard space and a crew of crewSize workers where
%   one is a certified forklift driver. Certified workers also help when no
%   other workers are free.
% Loading: ready to ship (pIReadyToShip) -> customer truck (pLOnTruck).
% Shipping: the customer truck leaves when full (shipmentSize) or when no
%   more pipes can come, delivers the pipes and drives back.
%
% Crew transitions: tLUnload_L<lane>_C<certified>H<helpers>.
% Lanes let several forklifts work at the same time (GPenSIM transitions are
% single-server). MOD_Logistics_PRE picks which crew variant fires.

function [pns] = logistics_pn_pdf()
global global_info
cfg = global_info.cfg.logistics;

pns.PN_name = 'Logistics';
pns.set_of_Ps = {'pLForklift', 'pLCertified', 'pLHelpers', 'pLYardSpace', ...
    'pLUnloaded', 'pLTruckDocked', 'pLTruckSpace', 'pLOnTruck', ...
    'pLTruckAway', 'pLDelivered'};
pns.set_of_Ts = {};
pns.set_of_As = {};
pns.set_of_Ports = {};

helpers = cfg.crewSize - 1;
for lane = 1:cfg.forklifts
    for extraCertified = 0:helpers
        certified = 1 + extraCertified;
        others = helpers - extraCertified;
        if certified > cfg.certifiedDrivers || others > cfg.otherWorkers
            continue
        end
        crew = {'pLForklift', 1, 'pLCertified', certified, 'pLHelpers', others};

        unload = sprintf('tLUnload_L%d_C%dH%d', lane, certified, others);
        addTask(unload, [{'pIIncoming', 1, 'pLYardSpace', 1}, crew], ...
            [{'pLUnloaded', 1}, crew], true);

        load = sprintf('tLLoad_L%d_C%dH%d', lane, certified, others);
        addTask(load, [{'pIReadyToShip', 1, 'pLTruckSpace', 1, 'pLTruckDocked', 1}, crew], ...
            [{'pLOnTruck', 1, 'pLTruckDocked', 1}, crew], true);
    end
end

addTask('tLDepart', {'pLTruckDocked', 1}, {'pLTruckAway', 1}, false);
addTask('tLDeliver', {'pLTruckAway', 1, 'pLOnTruck', 1}, ...
    {'pLTruckAway', 1, 'pLDelivered', 1, 'pLTruckSpace', 1}, false);
addTask('tLReturn', {'pLTruckAway', 1}, {'pLTruckDocked', 1}, false);

    function addTask(name, inputs, outputs, isPort)
        pns.set_of_Ts{end+1} = name;
        pns.set_of_As = [pns.set_of_As, pipe_yard_task(name, inputs, outputs)];
        if isPort
            pns.set_of_Ports{end+1} = name;
        end
    end
end
