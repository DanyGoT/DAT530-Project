function fig = plot_process(results)
% Plot Trym's scenario_process results, including saved process.mat runs.
fig = figure('Name', 'Pipes versus time: washing and inspection');
batch_mode = isfield(results{1}.C, 'batch_clearance') && results{1}.C.batch_clearance;
plot_rows = 2 + batch_mode;
layout = tiledlayout(plot_rows, size(results, 2));
for j = 1:size(results, 2)
    completed_axes = nexttile(layout, j);
    hold(completed_axes, 'on');
    hall_axes = nexttile(layout, size(results, 2) + j);
    hold(hall_axes, 'on');
    if batch_mode
        yard_axes = nexttile(layout, 2*size(results, 2) + j);
        hold(yard_axes, 'on');
    end
    for i = 1:size(results, 1)
        R = results{i, j};
        L = R.log(R.log.completed & strcmp(R.log.task, 'inspect'), :);
        done = [];
        for id = 1:R.C.total
            last_step = size(R.P.steps, 1);
            while R.pipes.scrapped(id) && R.P.steps{last_step, 5}
                last_step = last_step - 1;
            end
            rows = cellfun(@(ids) isequal(ids, id), L.pipe) & L.step == last_step;
            done = [done; L.finish(rows)];
        end
        done = sort(done);
        label = sprintf('%d workers %s', sum(R.P.crew), mat2str(R.P.crew));
        stairs(completed_axes, ([R.C.start; done; R.end_time] - R.C.start)/1440, ...
            [0; (1:numel(done))'; numel(done)], 'DisplayName', label);
        H = R.history;
        stairs(hall_axes, (H.time - R.C.start)/1440, H.hall, 'DisplayName', label);
        if batch_mode
            moves = R.log(R.log.completed & strcmp(R.log.task, 'batch_move_out'), :);
            moves = sortrows(moves, 'finish');
            counts = cellfun(@numel, moves.pipe);
            stairs(yard_axes, ([R.C.start; moves.finish; R.end_time]-R.C.start)/1440, ...
                [0; cumsum(counts); sum(counts)], 'DisplayName', label);
        end
    end
    title(completed_axes, sprintf('%d washing lanes', R.P.wash_lanes));
    xlabel(completed_axes, 'Elapsed calendar days since run start');
    ylabel(completed_axes, 'Pipes inspected (OK / repair / scrap)');
    ylim(completed_axes, [0 R.C.total]);
    grid(completed_axes, 'on');
    legend(completed_axes, 'Location', 'best');
    title(hall_axes, 'Inspection hall occupancy');
    xlabel(hall_axes, 'Elapsed calendar days');
    ylabel(hall_axes, 'Pipes in hall');
    yline(hall_axes, R.P.hall_space, '--', 'Hall capacity', 'HandleVisibility', 'off');
    ylim(hall_axes, [0 R.P.hall_space + 1]);
    grid(hall_axes, 'on');
    if batch_mode
        title(yard_axes, 'Groups cleared into yard');
        xlabel(yard_axes, 'Elapsed calendar days');
        ylabel(yard_axes, 'Pipes ready in yard (all outcomes)');
        ylim(yard_axes, [0 R.C.total]);
        grid(yard_axes, 'on');
    end
end
title(layout, 'Washing and inspection: progress and hall occupancy');
end
