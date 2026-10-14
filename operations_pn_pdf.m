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
pns.set_of_Ps = {
    'pOCleaning', ...
    'pOInspection' ...
};
pns.set_of_Ts = {
    'tOCleaningInput', 'tOClean', ...
    'tOMoveToInspection', 'tOInspect', 'tOInspectionOutput' ...
};
pns.set_of_As = { ...
  'tOCleaningInput', 'pOCleaning',         1,                                         ... % Input to cleaning
  'pOCleaning',      'tOClean',            1, 'tOClean',            'pOCleaning',   1 ... % Cleaning
  'pOCleaning',      'tOMoveToInspection', 1, 'tOMoveToInspection', 'pOInspection', 1 ... % Cleaning to inspection
  'pOInspection',    'tOInspect',          1, 'tOInspect',          'pOInspection', 1 ... % Inspection
  'pOInspection',    'tOInspectionOutput', 1
 };

pns.set_of_Ports = {'tOCleaningInput', 'tOInspectionOutput'};
