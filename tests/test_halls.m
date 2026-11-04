% Two halls (P.halls = 2), 2 days: both inspect, every order goes to one
% hall, and neither hall loses joints or credits between the yard and its
% floor. The run ends at midnight, so nothing is half done.

clear all; clc;
global global_info

P = params();
P.seed = 4;                     % a seed with arrivals from Monday
P.days = 2;
P.halls = 2;
model_init(P);
pns = pnstruct(model_pdfs(P));
assert_no_sources(pns);
pni = initialdynamics(pns, model_dyn(P, pns));
Sim_Results = gpensim(pni);

fired = @(ts) sum(cellfun(@timesfired, ts));
o = global_info.yard_out;                 % [time, received, order, hall]
for h = 1:2
    n = @(name) hall_name(name, h);
    done(h) = fired(n({'tIOk', 'tIMach', 'tIHb', 'tIScrap'}));
    assert(done(h) > 0, sprintf('hall %d inspected nothing', h));
    sent = fired(n({'tYLong', 'tYShort'}));
    assert(sent == sum(o(:, 4) == h), 'yard_out out of step with the feeds');
    on_way = sum(cellfun(@ntokens, n({'pYW', 'pWRack', 'pWDone', 'pWI'})));
    assert(sent == on_way + timesfired(n('tIIn')), sprintf('hall %d lost joints before its floor', h));
    credits = sum(cellfun(@ntokens, n({'pYRoom', 'pIYRoom', 'pIRoom'})));
    assert(credits + on_way == P.hall_buffer, sprintf('hall %d credits do not add up', h));
end
for k = unique(o(:, 3))'
    assert(isscalar(unique(o(o(:, 3) == k, 4))), sprintf('order %d went to both halls', k));
end
disp(['test_halls: ok (inspected ', int2str(done(1)), ' in hall 1, ', int2str(done(2)), ' in hall 2; ', ...
      int2str(numel(unique(o(o(:, 4) == 1, 3)))), ' and ', int2str(numel(unique(o(o(:, 4) == 2, 3)))), ' orders)']);
