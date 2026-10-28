% Arrival, yard, wash and hall, 2 days. The run stops at midnight, when the
% hall is idle, so every joint is in a place. Checks: the floor never holds
% more than P.hall_space joints, colours exist only in the wash and the hall,
% and every scrap joint past the last finding step has been found.

clear all; clc;
global global_info

P = params();
P.seed = 4;                     % a seed with arrivals from Monday
P.days = 2;
model_init(P);
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', 'imc_inspection_yard'});
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

S = global_info.S;
on_floor = sum(cellfun(@ntokens, {S.place})) + ntokens('pIDone');
assert(on_floor + ntokens('pISpace') == P.hall_space, 'hall space not conserved');

washed = timesfired('tWLong') + timesfired('tWShort');
assert(washed > 0, 'nothing was washed');
left = sum(cellfun(@timesfired, {'tIOk', 'tIMach', 'tIHb', 'tIScrap'}));
assert(washed == on_floor + left, 'joints lost in the hall');

for p = {'pYLong', 'pYShort', 'pYReady', 'pYScrap', 'pISpace'}
    bank = get_place(p{1}).token_bank;
    if isempty(bank), continue, end
    assert(all(cellfun(@isempty, {bank.color})), [p{1}, ' has coloured tokens']);
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
