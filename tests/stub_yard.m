% PDF: stub_yard.m
%
% Test stub for the Yard module on its own: empty places in front of the
% input ports that tests don't feed, and places that collect what the
% output ports send. The yard starts with the credits (P.hall_buffer in
% pYRoom, model_dyn); nothing hands them back, so it sends at most that many.
function [png] = stub_yard()
png.PN_name = 'stub_yard';
png.set_of_Ps = {'pYW', 'pIYRoom', 'pIYOk', 'pIYScrap', 'pRYReady', 'pDYOrder', 'pYDOut'};
png.set_of_Ts = {};
png.set_of_As = { ...
  'tYLong', 'pYW', 1, 'tYShort', 'pYW', 1, 'pIYRoom', 'tYRoom', 1 ...
  'pIYOk', 'tYInOk', 1, 'pIYScrap', 'tYInScrap', 1, 'pRYReady', 'tYInRepaired', 1 ...
  'pDYOrder', 'tYOrder', 1, 'tYShip', 'pYDOut', 1 ...
 };
