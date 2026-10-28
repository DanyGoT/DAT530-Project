% PDF: inspection_pdf.m
%
% %%%%%%%   Inspection hall
% An open floor joints roll through in order. Each step k (global_info.S) is
%   pI<name> -> tI<name>_1 ... tI<name>_m -> next step
% with one transition per person qualified for the step, so up to m joints can
% be at the same step at once; free workers (resources) decide how many are.
% Steps that scrap joints skip also have pI<name> -> tI<name>Skip -> next step.
% pIDone is sorted by what inspection found: tIOk, tIMach, tIHb, tIScrap.
% pISpace holds one token per free spot on the floor: joints take one coming
% in (IMCs) and give it back on the way out.

function [png] = inspection_pdf()

global global_info
S = global_info.S;

exits = {'tIOk', 'tIMach', 'tIHb', 'tIScrap'};
Ps = {S.place, 'pIDone', 'pISpace'};
Ts = [S.ts, exits];
As = {};
for k = 1:numel(S)
    for t = [S(k).ts, {S(k).tskip}]
        if isempty(t{1}), continue, end
        As = [As, {S(k).place, t{1}, 1, t{1}, S(k).next, 1}];
    end
    if S(k).skip, Ts{end+1} = S(k).tskip; end
end
for t = exits
    As = [As, {'pIDone', t{1}, 1, t{1}, 'pISpace', 1}];
end

png.PN_name = 'Inspection';
png.set_of_Ps = Ps;
png.set_of_Ts = Ts;
png.set_of_As = As;
