function [fire, transition] = MOD_Logistics_PRE(transition)
global global_info

fire = true;
crew = regexp(transition.name, '^tL(?:Unload|Load)_L\d+_C(\d+)H(\d+)$', 'tokens', 'once');
if ~isempty(crew)
    % One certified driver; helpers are taken from non-certified workers
    % first, so certified workers are only used as helpers when needed.
    variant = str2double(crew);
    helpersNeeded = sum(variant) - 1;
    others = min(ntokens('pLHelpers'), helpersNeeded);
    fire = isequal(variant, [1 + helpersNeeded - others, others]);
    return
end

switch transition.name
    case 'tLDepart'
        onTruck = ntokens('pLOnTruck');
        noMorePipes = onTruck + ntokens('pLDelivered') + ntokens('pIScrapped') == ...
            global_info.totalPipes;
        fire = onTruck >= global_info.cfg.logistics.shipmentSize || ...
            (onTruck > 0 && noMorePipes);
        if fire
            global_info.departingPipes = onTruck;
        end
    case 'tLReturn'
        fire = ntokens('pLOnTruck') == 0;
end
end
