% Yard, Washing and Inspection, 2 days. The run stops at midnight, when the
% wash and the hall are idle, so every joint is in a place. Checks: room on
% the floor and the credits are conserved, no joint is lost on the way, the
% yard stays colourless, joints for the workshops carry only their order,
% and every scrap joint past the last finding step has been found.

clear all; clc;
global global_info

P = params();
P.seed = 4;
P.days = 2;
model_init(P);
pns = pnstruct({'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'imc_yard_wash', 'imc_wash_inspection', 'imc_inspection_yard', 'stub_hall'});
assert_no_sources(pns);
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

S = global_info.S;
on_floor = sum(cellfun(@ntokens, {S.place})) + ntokens('pIDone');
assert(on_floor + ntokens('pISpace') == P.hall_space, 'hall space not conserved');
waiting = sum(cellfun(@ntokens, {'pYRoom', 'pIYRoom', 'pIRoom', 'pYW', 'pWRack', 'pWDone', 'pWI'}));
assert(waiting == P.hall_buffer, 'credits not conserved');

lanes = 1:P.wash_lanes;
washed = sum(cellfun(@timesfired, [arrayfun(@(k) sprintf('tWLong_%d', k), lanes, 'UniformOutput', false), ...
                                   arrayfun(@(k) sprintf('tWShort_%d', k), lanes, 'UniformOutput', false)]));
assert(washed > 0, 'nothing was washed');
assert(timesfired('tWIn') == timesfired('tYLong') + timesfired('tYShort') - ntokens('pYW'), 'joints lost on the way to the wash');
assert(timesfired('tIIn') + ntokens('pWI') + ntokens('pWDone') == washed, 'joints lost between wash and hall');
left = sum(cellfun(@timesfired, {'tIOk', 'tIMach', 'tIHb', 'tIScrap'}));
assert(P.floor_start + timesfired('tIIn') == on_floor + left, 'joints lost in the hall');
assert(timesfired('tIOk') == timesfired('tYInOk') + ntokens('pIYOk') && ...
       timesfired('tIScrap') == timesfired('tYInScrap') + ntokens('pIYScrap'), 'joints lost on the way to the yard');

for p = {'pYLong', 'pYShort', 'pYReady', 'pYScrap', 'pIYOk', 'pIYScrap'}
    bank = get_place(p{1}).token_bank;
    if isempty(bank), continue, end
    assert(all(cellfun(@isempty, {bank.color})), [p{1}, ' has coloured tokens']);
end
for p = {'pIRMach', 'pIRHb'}
    for tok = get_place(p{1}).token_bank
        assert(numel(tok.color) == 1 && strncmp(tok.color{1}, 'order', 5), [p{1}, ' joint without just its order']);
    end
end

last = find([S.finds], 1, 'last');
for p = [{S(last+1:end).place}, {'pIDone'}]
    for tok = get_place(p{1}).token_bank
        c = tok.color;
        assert(not(any(strcmp(c, 'scrap'))) || any(strcmp(c, 'scrapped')), ...
               ['unfound scrap in ', p{1}]);
    end
end
disp(['test_hall: ok (', int2str(washed), ' washed, ', int2str(left), ' through the hall)']);
