% Plan:
% %%%% Initial fase
% Lage en forenklet modell, med hver av modulene for seg selv.
% ^ Teste hver module. Trenger ikke å sette disse sammen helt enda.
% Definere tokens, hva colors disse skal ha. 
% Kanskje i den initielle modellen så bruker man typ "Dirty"-"Clean", "Inspected"-"Not Inspected". Altså flagg (altså ikke modellere flere nivåer av ting. For eksempel Type 1 feil, type 2 feils...)
% 

% TODO: Ta bilder av operasjonen for kontekst til rapport og visualisering

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   Operasjonell avdeling
% Input buffer
% Cleaning buffer
% Cleaning transition
% Cleaning to inspection transition
% Inspection buffer
% Inspection transition
% Inspection to output transition
% Output buffer
% 
% Spyling, inspeksjon, reperasjon, personell, kompetanse (f.eks. NS1 sertifisert),
% Queuing system, hvor lang tid ting tar (Blir en FIFO queue, med at rør i samme ordre er sammenhengende ved siden av hverandre),
% 


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   Logistikk avdeling
% Input buffer
% 
% TODO: Fyll ut transitions og nodes
%        
% Trucker, interntransport (lastebil), lokasjoner, distanse, 
% personell, kompetanse (f.eks. truckførerkurs)
% Lasting på/av lastebil


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   IT avdeling
% 
% TODO: Fyll ut transitions og nodes
% 
% Ordre inn
% Blir denne som håndterer alt
% Bestemmer antall rør, hvilke rør, når, prioritet, alt sånt


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   Tokens
% 
% Definere typer og hva av colors disse skal ha
% Typer vil sikkert være litt flytende i systemet da...
% 
% %%%%%%%
%
% Pipe
% | 
% 
% Personell
% |
% 
% Kjøretøy
% |
% 
% IT system greie
% |
% 
% Kunde?
% | 
% 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%   Main simulation file
%
% Token = one joint (pipe). In the yard a joint's kind is the place it is in.
% In the wash and the hall it carries colours: 'long'/'short', what inspection
% will find ('ok', 'mach', 'hb' or 'scrap'), its order, and 'scrapped' once
% inspection has found scrap. Parameters: params.m.

clear all; clc;
global global_info

P = params();
% P.crew = [3 2 0 2];          % try another crew (L0-L3), as in the 2021 report

model_init(P);                  % arrivals, demand and hall steps into global_info
pns = pnstruct({'arrival_pdf', 'yard_pdf', 'wash_pdf', 'inspection_pdf', ...
                'repair_pdf', 'departure_pdf', ...
                'imc_arrival_yard', 'imc_yard_wash', 'imc_wash_inspection', ...
                'imc_inspection_yard', 'imc_inspection_repair', 'imc_yard_departure'});
pni = initialdynamics(pns, model_dyn(P, pns));   % marking, firing times, workers

Sim_Results = gpensim(pni);

out = {'tIOk', 'tIMach', 'tIHb', 'tIScrap'};
n = cellfun(@timesfired, out);
disp(['Joints arrived: ', int2str(global_info.next_pipe - 1), ...
      ', inspected: ', int2str(sum(n)), ' (ok ', int2str(n(1)), ', machining ', int2str(n(2)), ...
      ', hardbanding ', int2str(n(3)), ', scrap ', int2str(n(4)), ...
      '), shipped: ', int2str(timesfired('tDShip'))]);
prnschedule(Sim_Results);                                    % who worked how much
plotp(Sim_Results, {'pYLong', 'pYShort', 'pWBuf'});          % queue in front of the hall
plotp(Sim_Results, {'pISpace'});                             % free room on the hall floor
plotp(Sim_Results, {'pYReady', 'pDDemand'});                 % stock and unmet demand
plotp(Sim_Results, {'pDShipped', 'pRMach', 'pRHb', 'pYScrap'});  % where joints went
