function order = order_of(colors)
% The order number in a joint's colours ('order12' -> 12).
order = sscanf(colors{strncmp(colors, 'order', 5)}, 'order%d');
