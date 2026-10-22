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

net = Ops.net;

pns.PN_name = 'Operation Petri Net model';
pns.set_of_Ps = [{Ops.pDone}, net.Ps];
pns.set_of_Ts = [{Ops.tInput, Ops.tOutput}, net.Ts];
pns.set_of_As = [{ ...
  Ops.tInput, net.p.Clean, 1 ...  % Input port -> cleaning buffer
  Ops.pDone,  Ops.tOutput, 1 ...  % Done -> output port
}, net.As];                       % Clean and Inspect steps

pns.set_of_Ports = {Ops.tInput, Ops.tOutput};