% %%%%%%%   Operasjonell avdeling
% Input buffer
% Cleaning buffer
% Cleaning transition
% Cleaning to inspection transition
% Inspection buffer
% Inspection transition
% Inspection to output transition
% Output buffer

function [pns] = operations_pn_pdf()

pns.PN_name = 'Operation Petri Net model';
pns.set_of_Ps = {'pInput', 'pCleaning', 'pInspection', 'pOutput'};
pns.set_of_Ts = {'tMoveToClean', 'tClean', 'tMoveToInspection', 'tInspect', 'tMoveToOutput'}; 
pns.set_of_As = { ...
  'pInput',       'tMoveToClean',       1, 'tMoveToClean',      'pCleaning',     1 ... % Input to cleaning
  'pCleaning',    'tClean',             1, 'tClean',            'pCleaning',     1 ... % Cleaning
  'pCleaning',    'tMoveToInspection',  1, 'tMoveToInspection', 'pInspection',   1 ... % Cleaning to inspection
  'pInspection',  'tInspect',           1, 'tInspect',          'pInspection',   1 ... % Inspection
  'pInspection',  'tMoveToOutput',      1, 'tMoveToOutput',     'pOutput',       1 ... % Inspection to output
 };    
