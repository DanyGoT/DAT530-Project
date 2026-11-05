function R = reach_graph(pns, m0)
% Reachability graph of a bounded P/T net (no inhibitor arcs, no time, no
% processors): every marking reachable from m0, and an edge for every
% firing. The coverability tree (cotree) lists the same markings, but as a
% tree; liveness and reversibility need the graph.
%
% R.M      reachable markings, one row each, R.M(1, :) = m0
% R.edges  [from to transition]
% R.dead   markings that enable nothing (deadlocks)
% R.live   per transition: can fire again from every reachable marking (L4)
% R.fired  per transition: fires from some reachable marking (L1)
% R.reversible  m0 can be reached again from every reachable marking
% R.bound  per place: the most tokens it ever holds

np = pns.No_of_places;
Ai = pns.incidence_matrix(:, 1:np);
C  = pns.incidence_matrix(:, np+1:end) - Ai;
nt = size(Ai, 1);

key = @(m) char(m + 32);                    % a marking as a map key
seen = containers.Map('KeyType', 'char', 'ValueType', 'double');
M = zeros(1024, np);
M(1, :) = m0(:)';
seen(key(M(1, :))) = 1;
n = 1;
E = zeros(4096, 3);
ne = 0;
next = 1;
while next <= n
    m = M(next, :);
    for t = find(all(Ai <= m, 2))'
        m2 = m + C(t, :);
        k = key(m2);
        if isKey(seen, k)
            j = seen(k);
        else
            n = n + 1;
            if n > size(M, 1), M(2*n, :) = 0; end
            M(n, :) = m2;
            seen(k) = n;
            j = n;
        end
        ne = ne + 1;
        if ne > size(E, 1), E(2*ne, :) = 0; end
        E(ne, :) = [next j t];
    end
    next = next + 1;
end
M = M(1:n, :);
E = E(1:ne, :);

% From any marking the net can reach a bottom component of the graph (one
% it can't leave). A transition is live iff it fires inside every bottom
% component; m0 is a home state iff it lies in the only one.
G = digraph(E(:, 1), E(:, 2), [], n);
scc = conncomp(G, 'Type', 'strong')';
leaves = scc(E(:, 1)) ~= scc(E(:, 2));
bottom = setdiff(unique(scc), unique(scc(E(leaves, 1))));
live = true(1, nt);
for b = bottom'
    inside = scc(E(:, 1)) == b & scc(E(:, 2)) == b;
    live = live & ismember(1:nt, E(inside, 3));
end

R.M = M;
R.edges = E;
R.dead = setdiff(1:n, E(:, 1));
R.live = live;
R.fired = ismember(1:nt, E(:, 3));
R.reversible = isscalar(bottom) && scc(1) == bottom;
R.bottom = numel(bottom);
R.bound = max(M, [], 1);
