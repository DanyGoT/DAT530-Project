function [] = MOD_Washing_POST(transition)
% The worker who mobilized the unit goes back to the hall once it is demobilized.
if strcmp(transition.name, 'tWDemobilize')
    release('tWMobilize');
end
