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

clear all; clc;
[Sim_Results, Order_Summary, Inventory_Summary, Resource_Summary] = run_pipe_simulation();
