% PDF: imc_lo_pdf.m
%
% Inter-modular connector (IMC): Logistics -> Operations
% Completed logistics output is transferred into the operations buffer.
% No set_of_Ports here, so GPenSIM treats this as a plain connector.

function [pns] = imc_lo_pdf()

pns.PN_name = 'IMC_LO';
pns.set_of_Ps = {'pIMC_LO'};
pns.set_of_Ts = {'tLToOperations'};
pns.set_of_As = { ...
  'pLOutput', 'tLToOperations', 1, 'tLToOperations', 'pIMC_LO', 1 ...
  'pIMC_LO',  'tOCleaningInput', 1 ... % buffer -> Operations input port
 };
