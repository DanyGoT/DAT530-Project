function pipe_yard_check_done()
% Stop the simulation when every pipe has been delivered or scrapped.
global global_info
if ntokens('pLDelivered') + ntokens('pIScrapped') == global_info.totalPipes
    global_info.STOP_SIMULATION = 1;
end
end
