% PDF: imc_lo_pdf.m
%
% Inter-modular connector (IMC): Logistics -> Operations
% Output port tLUnload deposits pipes in the IMC buffer,
% input port tOCleaningInput takes them from there.
% No set_of_Ports here, so GPenSIM treats this as a plain connector.

function [pns] = imc_lo_pdf()

pns.PN_name = 'IMC_LO';
pns.set_of_Ps = {ImcLO.pBuffer};
pns.set_of_Ts = {};
pns.set_of_As = { ...
  Lgs.tUnload,   ImcLO.pBuffer, 1 ... % Logistics output port -> buffer
  ImcLO.pBuffer, Ops.tInput,    1 ... % buffer -> Operations input port
 };
