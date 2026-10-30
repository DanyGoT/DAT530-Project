% PDF: imc_inspection_yard.m
%
% Inter-modular connector (IMC): Inspection -> Yard
% pIYOk, pIYScrap: inspected joints back to the yard, colourless.
% pIYRoom: credits on their way back. The yard spends one on each joint it
% sends to the wash, and the hall hands it back when the joint comes onto
% the floor, so at most P.hall_buffer joints are between the yard and the
% floor (on their way, at the wash, or washed and waiting).
function [png] = imc_inspection_yard()
png.PN_name = 'imc_inspection_yard';
png.set_of_Ps = {'pIYOk', 'pIYScrap', 'pIYRoom'};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tIOk',    'pIYOk',    1, 'pIYOk',    'tYInOk',    1 ...
  'tIScrap', 'pIYScrap', 1, 'pIYScrap', 'tYInScrap', 1 ...
  'tIRoom',  'pIYRoom',  1, 'pIYRoom',  'tYRoom',    1 ...
 };
