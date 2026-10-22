% Names for the IT module. Use IT.<name> instead of string literals.

classdef IT
  properties (Constant)
    pNewOrders           = 'pINewOrders'
    pOngoingOrders       = 'pIOngoingOrders'
    pCompletedOrders     = 'pICompletedOrders'
    pReceives            = 'pIReceives'
    pInspections         = 'pIInspections'
    pDeliveries          = 'pIDeliveries'
    pInvoices            = 'pIInvoices'

    tProcessOrder        = 'tIProcessOrder'
    tProcessReceive      = 'tIProcessReceive'
    tProcessDelivery     = 'tIProcessDelivery'
    tReceiveFromOrder    = 'tIReceiveFromOrder'
    tInspectionFromOrder = 'tIInspectionFromOrder'
    tDeliveryFromOrder   = 'tIDeliveryFromOrder'
    tInvoiceFromOrder    = 'tIInvoiceFromOrder'
  end
end
