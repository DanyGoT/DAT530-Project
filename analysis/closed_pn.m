% Boundedness, deadlock, liveness and reversibility of the model's net.
%
% The model's net is unbounded: the arrival and ticket clocks make joints
% and delivery orders out of nothing, and shipped and scrapped joints pile
% up. close_net closes it (pXJoints, pXTickets): a joint leaving frees room
% for one to arrive. Then
%   1. one P-invariant covers every place: the closed net is bounded for
%      any initial marking (structurally bounded), and conservative;
%   2. from a small marking, GPenSIM's coverability tree, and the full
%      reachability graph (reach_graph), which also gives liveness and
%      reversibility.
%
% This is the net only: no colours, guards, times or workers. It says the
% structure can't get stuck; the processors can still hold a token back
% (a joint waits for a worker or for the shift), which the simulation runs
% show they release again.
%
% The net is the skeleton of analysis_pn.m: one transition per hall step
% (crew [0 0 0 1]). A step's other transitions are copies with the same
% input and output places, so they reach the same markings and are live
% when the first is. The wash is checked with one lane and with two.

clear all; clc;
global global_info

pdfs = {'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
        'repair_pdf', 'departure_pdf', ...
        'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', ...
        'imc_inspection_yard', 'imc_inspection_repair', 'imc_repair_yard', ...
        'imc_yard_departure'};

% Initial markings: N joints and K tickets of room, hall floor h, credits b.
% The rest as in the model: both clocks, the wash off, its lanes set up
% for long. No joints anywhere yet, so the start-up transition tIStart
% (which puts P.floor_start joints on the floor at t = 0) never fires.
%         lanes N  K  h  b
cases = [ 1     1  1  1  1
          1     2  1  2  1
          1     3  1  2  2
          2     2  1  2  1
          2     3  2  2  2 ];

P = params();
P.days = 1;
P.crew = [0 0 0 1];
for c = 1:size(cases, 1)
    [lanes, N, K, h, b] = deal(cases(c, 1), cases(c, 2), cases(c, 3), cases(c, 4), cases(c, 5));
    if c == 1 || lanes ~= cases(c-1, 1)
        P.wash_lanes = lanes;
        model_init(P);
        global_info.closed = close_net(pnstruct(pdfs));
        cns = pnstruct('closed_pdf');
        places = {cns.global_places.name};
        trans  = {cns.global_transitions.name};
        np = numel(places);
        C = cns.incidence_matrix(:, np+1:end) - cns.incidence_matrix(:, 1:np);

        % 1. Structural boundedness. Each invariant y: C*y = 0, so y'*m
        % never changes. Their sum is positive on every place, so no place
        % can hold more than (sum)'*m0 tokens, whatever m0 is.
        S = global_info.S;
        lane = @(name) arrayfun(@(k) sprintf('%s_%d', name, k), 1:lanes, 'UniformOutput', false);
        control = [{'pAClock', 'pDClock', 'pISpace', 'pYRoom', 'pIRoom', 'pIYRoom', ...
                    'pWOff', 'pXTickets', 'pDYOrder', 'pYOrder'}, ...
                   lane('pWReady'), lane('pWLong'), lane('pWShort')];
        inv = {
          'joints',        setdiff(places, control)
          'tickets',       {'pXTickets', 'pDYOrder', 'pYOrder'}
          'hall floor',    [{S.place}, {'pIDone', 'pISpace'}]
          'hall credits',  {'pYRoom', 'pYW', 'pWRack', 'pWDone', 'pWI', 'pIRoom', 'pIYRoom'}
          'arrival clock', {'pAClock'}
          'ticket clock',  {'pDClock'}
        };
        for k = 1:lanes
            inv(end+1, :) = {sprintf('lane %d set-up', k), {sprintf('pWLong_%d', k), sprintf('pWShort_%d', k)}};
            inv(end+1, :) = {sprintf('lane %d on/off', k), {'pWOff', sprintf('pWReady_%d', k)}};
        end
        cover = zeros(np, 1);
        fprintf('\nClosed net, %d wash lane(s): %d places, %d transitions\n', lanes, np, numel(trans));
        for k = 1:size(inv, 1)
            y = double(ismember(places, inv{k, 2}))';
            assert(all(C*y == 0), [inv{k, 1}, ' is not an invariant']);
            cover = cover + y;
            fprintf('  P-invariant %-14s %2d places\n', inv{k, 1}, sum(y));
        end
        assert(all(cover > 0), ['not covered: ', strjoin(places(cover == 0), ', ')]);
        fprintf('  Together they cover all %d places: structurally bounded and conservative.\n', np);
        fprintf('\n  %5s %2s %2s %2s %2s %8s %8s %6s %6s %10s  %s\n', 'lanes', 'N', 'K', 'h', 'b', ...
                'states', 'edges', 'dead', 'bottom', 'reversible', 'not live');
    end

    m0 = zeros(1, np);
    mk = {'pXJoints',N, 'pXTickets',K, 'pISpace',h, 'pYRoom',b, ...
           'pAClock',1, 'pDClock',1, 'pWOff',1};
    for k = 1:lanes, mk = [mk, {sprintf('pWLong_%d', k), 1}]; end
    [~, at] = ismember(mk(1:2:end), places);
    m0(at) = [mk{2:2:end}];

    tic;
    R = reach_graph(cns, m0);
    notlive = setdiff(trans(not(R.live)), {'tIStart'});
    assert(isequal(trans(not(R.fired)), {'tIStart'}), 'a transition never fires');
    fprintf('  %5d %2d %2d %2d %2d %8d %8d %6d %6d %10s  %s  (%.0f s)\n', lanes, N, K, h, b, ...
            size(R.M, 1), size(R.edges, 1), numel(R.dead), R.bottom, mat2str(R.reversible), ...
            strjoin(notlive, ' '), toc);

    % 2. GPenSIM's own coverability tree, on the smallest case: its
    % markings must be the graph's, and it must find the same deadlocks.
    if c == 1
        dyn.m0 = reshape([mk(1:2:end); mk(2:2:end)], 1, []);
        evalc('pni = initialdynamics(cns, dyn); CT = cotree(pni);');
        X = unique(CT(:, 1:np), 'rows');
        assert(isequal(X, unique(R.M, 'rows')), 'cotree and reach_graph disagree');
        evalc('bounded = boundedness(CT); safe = safeness(CT); dead = deadStates(CT);');
        fprintf('  cotree: %d nodes, %d markings (the same), bounded %d, safe %d, %d dead states\n', ...
                size(CT, 1), size(X, 1), bounded, safe, numel(dead));
    end
end
disp(' ');
disp('tIStart never fires from these markings: it only puts the start floor');
disp('down at t = 0 (pIStart), and nothing refills pIStart.');
