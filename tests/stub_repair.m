% PDF: stub_repair.m
%
% Test stub for the Repair module on its own: no new joints come in, and
% the joints that come back are collected in pRI (hall) and pRYReady (stock).
function [png] = stub_repair()
png.PN_name = 'stub_repair';
png.set_of_Ps = {'pIRMach', 'pIRHb', 'pRI', 'pRYReady'};
png.set_of_Ts = {};
png.set_of_As = { ...
  'pIRMach', 'tRInMach', 1, 'pIRHb', 'tRInHb', 1 ...
  'tRMachHall', 'pRI', 1, 'tRHbHall', 'pRI', 1, 'tRMachReady', 'pRYReady', 1, 'tRHbReady', 'pRYReady', 1 ...
 };
