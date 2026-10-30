function yes = next_is(place, color)
% The first joint in place has this colour.
[id, c] = find_token(place, @(tok) true);
yes = id > 0 && has_color(c, color);
