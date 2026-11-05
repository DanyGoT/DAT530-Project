function flow_validate(P, C)
validateattributes(C.process_only, {'logical'}, {'scalar'});
validateattributes(C.batch_clearance, {'logical'}, {'scalar'});
validateattributes(C.batch_move_minutes, {'numeric'}, {'scalar', 'real', 'finite', 'positive'});
assert(~C.batch_clearance || C.process_only, 'flow:BatchMode', ...
    'Batch clearance is supported only in process-only mode.');
assert(~C.batch_clearance || C.batch_move_minutes <= diff(P.shift), ...
    'flow:BatchTime', 'The group movement must fit inside a shift.');
validateattributes(C.total, {'numeric'}, {'scalar', 'integer', 'positive', '<=', 800});
validateattributes(C.initial, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', C.total});
validateattributes(P.crew, {'numeric'}, {'row', 'numel', 4, 'integer', 'nonnegative'});
validateattributes(C.certified, {'numeric'}, {'row', 'numel', 4, 'integer', 'nonnegative'});
assert(all(C.certified <= P.crew) && (C.process_only || sum(C.certified) > 0), ...
    'flow:Certificates', 'Certified counts must fit the crew, with at least one driver.');
validateattributes(C.unload_workers, {'numeric'}, {'scalar', 'integer', 'positive'});
assert(C.process_only || C.unload_workers <= sum(P.crew), ...
    'flow:UnloadCrew', 'Not enough workers to unload.');
assert(~C.process_only || C.initial == C.total, ...
    'flow:Initial', 'Process-only mode requires all pipes initially waiting for washing.');
validateattributes(C.forklifts, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(P.wash_lanes, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(P.pace, {'numeric'}, {'scalar', 'real', 'finite', 'positive'});
validateattributes([P.steps{:, 2}], {'numeric'}, {'real', 'finite', 'positive'});
validateattributes([P.steps{:, 3}], {'numeric'}, {'integer', '>=', 0, '<=', 3});
validateattributes(P.wash, {'numeric'}, {'row', 'numel', 2, 'real', 'finite', 'positive'});
validateattributes([P.mobilize P.demobilize P.change], {'numeric'}, {'real', 'finite', 'positive'});
validateattributes(P.repair_median, {'numeric'}, {'row', 'numel', 2, 'real', 'finite', 'positive'});
validateattributes(P.repair_sigma, {'numeric'}, {'row', 'numel', 2, 'real', 'finite', 'nonnegative'});
validateattributes(P.p_reinspect, {'numeric'}, {'row', 'numel', 2, 'real', 'finite', '>=', 0, '<=', 1});
validateattributes(P.hall_space, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(C.wash_space, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(C.step_machines, {'numeric'}, ...
    {'row', 'numel', size(P.steps, 1), 'integer', 'positive'});
validateattributes(C.start, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});
validateattributes(C.first_arrival, {'numeric'}, {'scalar', 'real', 'finite', '>=', C.start});
validateattributes(C.arrival_gap, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});
validateattributes(C.max_days, {'numeric'}, {'scalar', 'real', 'finite', 'positive'});
durations = [P.unload, C.move_minutes, C.load_minutes, C.depart_minutes];
assert(all(isfinite(durations) & durations > 0), 'flow:Times', 'Task durations must be finite and positive.');
validateattributes(C.repair_transport, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});
shift = diff(P.shift);
assert(shift > 0 && P.shift(1) >= 0 && P.shift(2) <= 1440, 'flow:Shift', 'Invalid daily shift.');
assert(all(durations(1:3) <= shift) && max([P.steps{:, 2}])*P.pace/60 <= shift && ...
    P.mobilize + P.change + max(P.wash) + P.demobilize <= shift, ...
    'flow:Shift', 'A task is too long to fit within a shift.');
assert(sum(P.crew) > 0 && find(P.crew > 0, 1, 'last') - 1 >= max([P.steps{:, 3}]), ...
    'flow:Crew', 'No worker qualified for the highest inspection level.');
wash_levels = arrayfun(@(L) sprintf('L%d', L), 0:3, 'UniformOutput', false);
assert(any(P.crew(ismember(wash_levels, P.wash_crew)) > 0), ...
    'flow:WashCrew', 'No worker qualified to operate the wash.');
assert(any([P.steps{:, 4}]), 'flow:Scrap', 'At least one inspection step must detect scrap.');
end
