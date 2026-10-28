% PDF: yard_pdf.m
%
% %%%%%%%   Yard
% pYLong / pYShort - joints waiting for the hall, by length (racks by type)
% pYReady          - rig-ready stock
% pYScrap          - scrap
% tYLong / tYShort send the next hall joint to the wash, in arrival order.
% Joints in the yard carry no colours; a joint gets its colours from
% global_info.hall when it leaves for the wash (COMMON_PRE).

function [png] = yard_pdf()

png.PN_name = 'Yard';
png.set_of_Ps = {'pYLong', 'pYShort', 'pYReady', 'pYScrap'};
png.set_of_Ts = {'tYLong', 'tYShort'};
png.set_of_As = {'pYLong', 'tYLong', 1, 'pYShort', 'tYShort', 1};
