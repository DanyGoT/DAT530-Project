function on = in_shift(P)
% Mon-Fri during the shift (P.shift, minutes after midnight).
now = current_time();
on = mod(floor(now/1440), 7) < 5 && mod(now, 1440) >= P.shift(1) && mod(now, 1440) < P.shift(2);
