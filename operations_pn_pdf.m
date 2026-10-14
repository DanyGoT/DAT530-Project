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
pns.set_of_Ps = {'pOInput', 'pOCleaning', 'pOInspection', 'pOOutput'};
pns.set_of_Ts = {'tOI', 'tOMoveToClean', 'tOClean', 'tOMoveToInspection', 'tOInspect', 'tOMoveToOutput'};
pns.set_of_As = { ...
  'pOInput',       'tOMoveToClean',       1, 'tOMoveToClean',      'pOCleaning',     1 ... % Input to cleaning
  'pOCleaning',    'tOClean',             1, 'tOClean',            'pOCleaning',     1 ... % Cleaning
  'pOCleaning',    'tOMoveToInspection',  1, 'tOMoveToInspection', 'pOInspection',   1 ... % Cleaning to inspection
  'pOInspection',  'tOInspect',           1, 'tOInspect',          'pOInspection',   1 ... % Inspection
  'pOInspection',  'tOMoveToOutput',      1, 'tOMoveToOutput',     'pOOutput',       1 ... % Inspection to output
 };    
