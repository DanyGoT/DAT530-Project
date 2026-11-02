function MOD_Logistics_POST(transition)
global global_info

switch transition.name
    case 'tLDepart'
        % Truck has arrived at the customer
        global_info.shipments(end+1, :) = [current_time(), global_info.departingPipes];
    case 'tLDeliver'
        pipe_yard_check_done();
end
end
