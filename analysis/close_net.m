function closed = close_net(pns)
% The model's net, closed so that every token stays in it. The open net
% makes joints and delivery orders out of nothing (the arrival and ticket
% clocks) and keeps every shipped and scrapped joint (pDShipped, pYScrap),
% so it is unbounded. Closed:
%   pXJoints  - room for a joint in the system. An arrival takes one; a
%               shipped or scrapped joint gives it back (in place of the
%               sinks pDShipped and pYScrap).
%   pXTickets - room for a joint asked for. A ticket takes one; loading the
%               joint (tYShip) gives it back.
% Everything else is the model's net as it is. Returns the places,
% transitions and arcs for closed_pdf.

places = {pns.global_places.name};
trans  = {pns.global_transitions.name};
np = numel(places);
Ai = pns.incidence_matrix(:, 1:np);        % Ai(t, p): tokens t takes from p
Ao = pns.incidence_matrix(:, np+1:end);    % Ao(t, p): tokens t puts in p

sinks = {'pDShipped', 'pYScrap'};
As = {};
for t = 1:numel(trans)
    for p = find(Ai(t, :))
        As = [As, {places{p}, trans{t}, Ai(t, p)}];
    end
    for p = find(Ao(t, :))
        to = places{p};
        if ismember(to, sinks), to = 'pXJoints'; end
        As = [As, {trans{t}, to, Ao(t, p)}];
    end
end
for t = {'tALong', 'tAShort', 'tABypass'}
    As = [As, {'pXJoints', t{1}, 1}];
end
As = [As, {'pXTickets', 'tDTicket', 1, 'tYShip', 'pXTickets', 1}];

closed.Ps = [setdiff(places, sinks, 'stable'), {'pXJoints', 'pXTickets'}];
closed.Ts = trans;
closed.As = As;
