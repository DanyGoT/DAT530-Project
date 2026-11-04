% PDF: imc_inspection_yard.m
%
% Inter-modular connector (IMC): Inspection -> Yard
% pIYOk, pIYScrap: inspected joints back to the yard, from every hall. Ok
% joints keep their order ('order<n>'), so the yard can store them at Main or
% Coop; scrap is colourless.
% pIYRoom: credits on their way back, one place per hall (hall_name). The
% yard spends one on each joint it sends to that hall's wash, and the hall
% hands it back when the joint comes onto the floor, so at most
% P.hall_buffer joints are between the yard and a hall's floor (on their
% way, at the wash, or washed and waiting).
function [png] = imc_inspection_yard()
global global_info
png.PN_name = 'imc_inspection_yard';
png.set_of_Ps = {'pIYOk', 'pIYScrap'};
png.set_of_Ts = {};
png.set_of_As = {'pIYOk', 'tYInOk', 1, 'pIYOk', 'tYInOkCoop', 1, 'pIYScrap', 'tYInScrap', 1};
for h = 1:global_info.P.halls
    n = @(name) hall_name(name, h);
    png.set_of_Ps{end+1} = n('pIYRoom');
    png.set_of_As = [png.set_of_As, {n('tIOk'), 'pIYOk', 1, n('tIScrap'), 'pIYScrap', 1, ...
                                     n('tIRoom'), n('pIYRoom'), 1, n('pIYRoom'), n('tYRoom'), 1}];
end
