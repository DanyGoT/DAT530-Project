function flow_classify(S, id)
% Terminal process-only outcome, shared by immediate and batch clearance.
if S.pipes(id).scrapped
    S.state{id} = 'scrap';
elseif ismember(S.pipes(id).finding, {'mach', 'hb'})
    S.state{id} = 'ready_repair';
else
    S.state{id} = 'ready';
end
end
