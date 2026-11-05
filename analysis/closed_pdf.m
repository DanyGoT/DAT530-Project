% PDF: closed_pdf.m
%
% The closed net, for analysis only (closed_pn.m). close_net builds its
% places, transitions and arcs from the model's own net and leaves them in
% global_info.closed; this file only hands them to pnstruct. One flat net,
% no modules, so no processors run.

function [png] = closed_pdf()

global global_info
c = global_info.closed;
png.PN_name = 'Closed';
png.set_of_Ps = c.Ps;
png.set_of_Ts = c.Ts;
png.set_of_As = c.As;
