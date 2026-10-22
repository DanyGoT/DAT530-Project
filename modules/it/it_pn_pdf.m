% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   IT avdeling
% 
% TODO: Fyll ut transitions og nodes
% 
% Ordre inn
% Blir denne som håndterer alt
% Bestemmer antall rør, hvilke rør, når, prioritet, alt sånt
% 
%
% Tanker:
% - Behandle ordre i tre states: Nye ordre, ongoing orders og completed orders. Mulig vi skulle endret dette til å bruke en "backlog" av ordre
%   - Kanskje bruke colours i stedet, men inntil vi introduserer colours så får det bare gå
%
% I/O:
% | Order Input
% | Pipe command output (qty, type, scope, logistics/operations)
% | Receiving pipes in
% | Sending pipes out
% | Storing pipes 
% | Inspecting pipes
%
% Order ->
%   Pipes received
%     To Storage
%       Order put in backlog
%       No inspection specified for order (just sent pipes for keepig in backlog)
%   Pipes already in storage
%
%     To Inspection hall
%       Order being handled
%       When finished, order status update
%       Pipes are moved to repair (creates a repair order)
%       Pipes are moved to storage
%       Delivery of pipes is ordered back to customer
%       Order set as complete
% 
%   Order gets invoiced
% 
% TODO: Legg på pre og post processing. IT-systemet trenger det veldig

function [pns] = it_pn_pdf()

pns.PN_name = 'IT Service Petri Net model';

pns.set_of_Ps = {'pINewOrders', 'pIOngoingOrders', 'pICompletedOrders', ...
  'pIReceives', 'pIInspections', 'pIDeliveries', 'pIInvoices'};

pns.set_of_Ts = {'tIProcessOrder', 'tIProcessReceive', 'tIProcessDelivery', ...
  'tIReceiveFromOrder', 'tIInspectionFromOrder', 'tIDeliveryFromOrder', 'tIInvoiceFromOrder'};

pns.set_of_As = { ...
  'pINewOrders',     'tIReceiveFromOrder',    1, 'tIReceiveFromOrder',    'pIOngoingOrders',   1, ... % Receive from order
  'pINewOrders',     'tIReceiveFromOrder',    1, 'tIReceiveFromOrder',    'pIReceives',        1, ... % 
  'pIOngoingOrders', 'tIInspectionFromOrder', 1, 'tIInspectionFromOrder', 'pIOngoingOrders',   1, ... % Inspection from order
  'pIOngoingOrders', 'tIInspectionFromOrder', 1, 'tIInspectionFromOrder', 'pIInspections',     1, ... %
  'pIOngoingOrders', 'tIDeliveryFromOrder',   1, 'tIDeliveryFromOrder',   'pIOngoingOrders',   1, ... % Delivery from order
  'pIOngoingOrders', 'tIDeliveryFromOrder',   1, 'tIDeliveryFromOrder',   'pIDeliveries',      1, ... %
  'pIOngoingOrders', 'tIInvoiceFromOrder',    1, 'tIInvoiceFromOrder',    'pICompletedOrders', 1, ... % Invoice from order
  'pIOngoingOrders', 'tIInvoiceFromOrder',    1, 'tIInvoiceFromOrder',    'pIInvoices',        1 ... %
};

