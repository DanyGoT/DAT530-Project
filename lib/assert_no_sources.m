function [] = assert_no_sources(pns)
% Every transition takes from at least one place. A port left without its
% connector would otherwise fire on its own, every time step.
in = pns.incidence_matrix(:, 1:pns.No_of_places);
names = {pns.global_transitions.name};
loose = names(not(any(in, 2)));
assert(isempty(loose), ['transitions with no input place: ', strjoin(loose, ', ')]);
