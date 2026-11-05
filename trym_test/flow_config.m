function C = flow_config(P)
% Trym's logistics/equipment assumptions, not measured site data.
C.total = 100;                    % change to 800 for 400 already there + 400 arriving
C.initial = 50;
C.start = P.shift(1);             % Monday, minutes after midnight
C.first_arrival = 8*60;
C.arrival_gap = 60;               % minutes between incoming orders
C.max_days = 1500;
C.certified = [1 1 1 1];         % certified people per level, must not exceed P.crew
C.forklifts = 1;
C.unload_workers = 3;             % includes one certified driver
C.move_minutes = 2;               % per pipe: yard/wash/hall/repair-return movements
C.load_minutes = 0.5;             % per pipe, after the whole order is ready
C.depart_minutes = 15;            % truck leaves after its order is fully loaded
C.repair_transport = 60;          % each way; external transport, not the shared forklift
C.wash_space = P.hall_buffer;     % includes washed pipes awaiting transfer to inspection
C.step_machines = ones(1, size(P.steps, 1));
C.process_only = false;           % true: all pipes start at wash; stop after inspection
C.batch_clearance = false;        % process-only: fill/inspect/clear one hall-sized group
C.batch_move_minutes = 15;        % one shared worker moves the whole group to yard
end
