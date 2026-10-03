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

pns.set_of_Ps = {'pNewOrders', 'pOngoingOrders', 'pCompletedOrders', ...
  'pReceives', 'pInspections', 'pDeliveries', 'pInvoices'};

pns.set_of_Ts = {'tProcessOrder', 'tProcessReceive', 'tProcessDelivery', ...
  'tReceiveFromOrder', 'tInspectionFromOrder', 'tDeliveryFromOrder', 'tInvoiceFromOrder'};

gp

pns.set_of_As = { ...
  'pNewOrders',     'tReceiveFromOrder',    1, 'tReceiveFromOrder',    'pOngoingOrders',   1, ... % Receive from order
  'pNewOrders',     'tReceiveFromOrder',    1, 'tReceiveFromOrder',    'pReceives',        1, ... % 
  'pOngoingOrders', 'tInspectionFromOrder', 1, 'tInspectionFromOrder', 'pOngoingOrders',   1, ... % Inspection from order
  'pOngoingOrders', 'tInspectionFromOrder', 1, 'tInspectionFromOrder', 'pInspections',     1, ... %
  'pOngoingOrders', 'tDeliveryFromOrder',   1, 'tDeliveryFromOrder',   'pOngoingOrders',   1, ... % Delivery from order
  'pOngoingOrders', 'tDeliveryFromOrder',   1, 'tDeliveryFromOrder',   'pDeliveries',      1, ... %
  'pOngoingOrders', 'tInvoiceFromOrder',    1, 'tInvoiceFromOrder',    'pCompletedOrders', 1, ... % Invoice from order
  'pOngoingOrders', 'tInvoiceFromOrder',    1, 'tInvoiceFromOrder',    'pInvoices',        1 ... %
};
