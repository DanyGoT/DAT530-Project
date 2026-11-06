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
pns = pnstruct({'yard_pdf', 'wash_pdf', 'inspection_pdf', 'imc_yard_wash', ...
                'imc_wash_inspection', 'imc_inspection_yard', 'stub_hall'});
assert_no_sources(pns);
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

fired = @(ts) sum(cellfun(@timesfired, ts));
ntok  = @(ps) sum(cellfun(@ntokens, ps));
S = global_info.S;
lanes = arrayfun(@(k) sprintf('tWash_%d', k), 1:P.wash_lanes, 'UniformOutput', false);

% Floor space and credits are conserved.
on_floor = ntok({S.place}) + ntokens('pIDone');
assert(on_floor + ntokens('pISpace') == P.hall_space, 'hall space not conserved');
waiting = ntok({'pYRoom', 'pIYRoom', 'pIRoom', 'pYW', 'pWRack', 'pWDone', 'pWI'});
assert(waiting == P.hall_buffer, 'credits not conserved');

% No joint is lost from the yard through the wash and the hall and back.
washed = fired(lanes);
left   = fired({'tIOk', 'tIMach', 'tIHb', 'tIScrap'});
assert(washed > 0, 'nothing was washed');
assert(timesfired('tWIn') == fired({'tYLong', 'tYShort'}) - ntokens('pYW'), ...
       'joints lost on the way to the wash');
assert(timesfired('tIIn') + ntok({'pWI', 'pWDone'}) == washed, ...
       'joints lost between wash and hall');
assert(P.floor_start + timesfired('tIIn') == on_floor + left, 'joints lost in the hall');
assert(timesfired('tIOk') == fired({'tYInOk', 'tYInOkCoop'}) + ntokens('pIYOk'), ...
       'ok joints lost on the way to the yard');
assert(timesfired('tIScrap') == timesfired('tYInScrap') + ntokens('pIYScrap'), ...
       'scrap lost on the way to the yard');

% The yard is colourless; joints for the workshops carry only their order.
for p = {'pYLong', 'pYShort', 'pYReady', 'pYScrap', 'pCHall', 'pCReady', 'pYToCoop', 'pIYScrap'}
    bank = get_place(p{1}).token_bank;
    assert(isempty(bank) || all(cellfun(@isempty, {bank.color})), [p{1}, ' has coloured tokens']);
end
for p = {'pIRMach', 'pIRHb'}
    for tok = get_place(p{1}).token_bank
        just_order = isscalar(tok.color) && strncmp(tok.color{1}, 'order', 5);
        assert(just_order, [p{1}, ' joint without just its order']);
    end
end

% Every scrap joint past the last step that finds scrap has been found.
last = find([S.finds], 1, 'last');
for p = [{S(last+1:end).place}, {'pIDone'}]
    for tok = get_place(p{1}).token_bank
        c = tok.color;
        assert(not(any(strcmp(c, 'scrap'))) || any(strcmp(c, 'scrapped')), ['unfound scrap in ', p{1}]);
    end
end

disp(['test_hall: ok (', int2str(washed), ' washed, ', int2str(left), ' through the hall)']);
