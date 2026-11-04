function [] = MOD_Washing_POST(transition)
% The worker goes back to the pool after each wash.
if strncmp(transition.name, 'tWash_', 6)
    release();
end
