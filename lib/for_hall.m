function png = for_hall(png, h)
% A module's PDF as hall h's: every name through hall_name. The module keeps
% its name (Inspection), so both halls run the same MOD_Inspection_PRE, which
% finds the hall from the transition's name (hall_of).
if h == 1, return, end
png.set_of_Ps = hall_name(png.set_of_Ps, h);
png.set_of_Ts = hall_name(png.set_of_Ts, h);
png.set_of_Ports = hall_name(png.set_of_Ports, h);
A = png.set_of_As;
i = sort([1:3:numel(A), 2:3:numel(A)]);    % from, to (not the weights)
A(i) = hall_name(A(i), h);
png.set_of_As = A;
