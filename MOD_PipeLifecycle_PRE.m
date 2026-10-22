function [fire, transition] = MOD_PipeLifecycle_PRE(transition)
global global_info
cfg = global_info.lifecycleConfig;
fire = true;
parts = strsplit(transition.name, '_');
switch parts{1}
    case {'tRouteInspect', 'tRouteReinspect'}
        worker = str2double(parts{3});
        fire = global_info.lifecycleOutcome(worker) == str2double(parts{4});
    case {'tStoreRaw', 'tStoreReady'}
        if strcmp(parts{3}, '2')
            fire = ~any(tokenAny('pYardSpace1', 1));
        end
    case 'tFetchRaw'
        if strcmp(parts{3}, '2')
            fire = ~any(tokenAny(['pRaw_' parts{2} '_1'], 1));
        end
    case 'tRepair'
        difficulty = str2double(parts{3});
        level = str2double(parts{4});
        for lowerLevel = difficulty:level-1
            if any(tokenAny(sprintf('pRepairWorker%d', lowerLevel), 1))
                fire = false;
                break
            end
        end
    case 'tDispatch'
        order = str2double(parts{2});
        yard = str2double(parts{3});
        pipeType = cfg.orders.Type{order};
        if yard == 2 && any(tokenAny(['pReady_' pipeType '_1'], 1))
            fire = false;
        end
        for earlier = 1:height(cfg.orders)
            isEarlier = cfg.orders.Time(earlier) < cfg.orders.Time(order) || ...
                (cfg.orders.Time(earlier) == cfg.orders.Time(order) && earlier < order);
            if isEarlier && strcmp(cfg.orders.Type{earlier}, pipeType) && ...
                    any(tokenAny(sprintf('pDemand%d', earlier), 1))
                fire = false;
                break
            end
        end
end
end