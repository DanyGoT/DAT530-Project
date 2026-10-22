% Names for the Logistics module. Use Lgs.<name> instead of string literals.

classdef Lgs
  properties (Constant)
    pYard1            = 'pLYard1'
    pYard2            = 'pLYard2'
    pTruckAvailable   = 'pLTruckAvailable'
    pTruckAtYard1     = 'pLTruckAtYard1'
    pTruckAtYard2     = 'pLTruckAtYard2'
    pLoaded1          = 'pLLoaded1'
    pLoaded2          = 'pLLoaded2'
    pForkliftYard1    = 'pLForkliftYard1'
    pForkliftYard2    = 'pLForkliftYard2'
    pForkliftWorkshop = 'pLForkliftWorkshop'
    pAtDestination    = 'pLAtDestination'
    pOutput           = 'pLOutput'

    tDriveToYard1     = 'tLDriveToYard1'
    tDriveToYard2     = 'tLDriveToYard2'
    tLoad1            = 'tLLoad1'
    tLoad2            = 'tLLoad2'
    tDriveFromYard1   = 'tLDriveFromYard1'
    tDriveFromYard2   = 'tLDriveFromYard2'
    tUnload           = 'tLUnload'
  end
end
