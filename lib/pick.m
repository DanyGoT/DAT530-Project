function [fire, transition] = pick(transition, id, colors)
% Fire on token id, and give the output exactly colors (override), so that
% tokens taken from other places in the same firing (space, credits, lane
% state) never mix their colours into the joint.
fire = id > 0;
transition.selected_tokens = id;
transition.new_color = colors;
transition.override = 1;
