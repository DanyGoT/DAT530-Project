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

pns.set_of_Ps = {IT.pNewOrders, IT.pOngoingOrders, IT.pCompletedOrders, ...
  IT.pReceives, IT.pInspections, IT.pDeliveries, IT.pInvoices};

pns.set_of_Ts = {IT.tProcessOrder, IT.tProcessReceive, IT.tProcessDelivery, ...
  IT.tReceiveFromOrder, IT.tInspectionFromOrder, IT.tDeliveryFromOrder, IT.tInvoiceFromOrder};

pns.set_of_As = { ...
  IT.pNewOrders,     IT.tReceiveFromOrder,    1, IT.tReceiveFromOrder,    IT.pOngoingOrders,   1, ... % Receive from order
  IT.pNewOrders,     IT.tReceiveFromOrder,    1, IT.tReceiveFromOrder,    IT.pReceives,        1, ... %
  IT.pOngoingOrders, IT.tInspectionFromOrder, 1, IT.tInspectionFromOrder, IT.pOngoingOrders,   1, ... % Inspection from order
  IT.pOngoingOrders, IT.tInspectionFromOrder, 1, IT.tInspectionFromOrder, IT.pInspections,     1, ... %
  IT.pOngoingOrders, IT.tDeliveryFromOrder,   1, IT.tDeliveryFromOrder,   IT.pOngoingOrders,   1, ... % Delivery from order
  IT.pOngoingOrders, IT.tDeliveryFromOrder,   1, IT.tDeliveryFromOrder,   IT.pDeliveries,      1, ... %
  IT.pOngoingOrders, IT.tInvoiceFromOrder,    1, IT.tInvoiceFromOrder,    IT.pCompletedOrders, 1, ... % Invoice from order
  IT.pOngoingOrders, IT.tInvoiceFromOrder,    1, IT.tInvoiceFromOrder,    IT.pInvoices,        1 ... %
};
