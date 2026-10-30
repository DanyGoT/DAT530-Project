% PDF: inspection_pdf.m
%
% %%%%%%%   Inspection hall (module)
% An open floor joints roll through in order. Each step k (global_info.S) is
%   pI<name> -> tI<name>_1 ... tI<name>_m -> next step
% with one transition per person qualified for the step, so up to m joints can
% be at the same step at once; free workers (resources) decide how many are.
% Steps that scrap joints skip also have pI<name> -> tI<name>Skip -> next step.
% pISpace holds one token per free spot on the floor: joints take one coming
% in and give it back on the way out. tIStart puts the joints that are on the
% floor at t = 0 (pIStart, global_info.floor) at the first step.
% Input ports:  tIIn       (washed joints; frees a credit, pIRoom)
%               tIInRepair (repaired joints, inspected again)
% Output ports: tIOk, tIScrap (to the yard), tIMach, tIHb (to Repair),
%               sorted from pIDone by what inspection found
%               tIRoom     (hands the credit back to the yard)

function [png] = inspection_pdf()

global global_info
S = global_info.S;
first = S(1).place;

ins = {'tIIn', 'tIInRepair'};
exits = {'tIOk', 'tIMach', 'tIHb', 'tIScrap'};
Ps = {S.place, 'pIDone', 'pISpace', 'pIStart', 'pIRoom'};
Ts = [{'tIStart'}, ins, S.ts, exits, {'tIRoom'}];
As = {'pIStart', 'tIStart', 1, 'pISpace', 'tIStart', 1, 'tIStart', first, 1, ...
      'tIIn', 'pIRoom', 1, 'pIRoom', 'tIRoom', 1};
for t = ins
    As = [As, {'pISpace', t{1}, 1, t{1}, first, 1}];
end
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
png.set_of_Ports = [ins, exits, {'tIRoom'}];
