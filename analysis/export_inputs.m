% The model's arrival generator (gen_pipes) for many weeks, for the report's
% comparison with the data (figure F1). No simulation; seconds.
% Writes results/reference/model_receipts.csv (one row per weekday: seed,
% day, weekday 0-4, receipts, joints) and model_receipt_sizes.csv (one row
% per receipt: joints, hall or bypass, long or short).

clear all; clc;

weeks = 40;
days = []; sizes = [];
for seed = 1:5
    P = params();
    P.seed = seed;
    P.days = 7 * weeks;
    rng(P.seed);
    pipes = gen_pipes(P);
    [orders, first] = unique([pipes.order], 'stable');
    t = [pipes(first).t];
    n = arrayfun(@(o) sum([pipes.order] == o), orders);
    day = floor(t / 1440);
    for d = 0:P.days-1
        if mod(d, 7) >= 5, continue, end
        on = day == d;
        days(end+1, :) = [seed, d, mod(d, 7), sum(on), sum(n(on))];
    end
    sizes = [sizes; n', strcmp({pipes(first).route}, 'hall')', strcmp({pipes(first).len}, 'long')'];
end

folder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results', 'reference');
if not(isfolder(folder)), mkdir(folder); end
writetable(array2table(days, 'VariableNames', {'seed', 'day', 'weekday', 'receipts', 'joints'}), ...
           fullfile(folder, 'model_receipts.csv'));
writetable(array2table(sizes, 'VariableNames', {'joints', 'hall', 'long'}), ...
           fullfile(folder, 'model_receipt_sizes.csv'));
fprintf('%d weekdays, %.2f receipts a weekday, %d receipts, median %g joints\n', ...
        size(days, 1), mean(days(:, 4)), size(sizes, 1), median(sizes(:, 1)));
