function [] = MOD_Washing_POST(transition)
% The worker goes back to the pool after each wash.
[~, t] = hall_of(transition.name);
if strncmp(t, 'tWash_', 6)
    release();
end
