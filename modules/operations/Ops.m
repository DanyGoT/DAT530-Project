% Names for the Operations module. Use Ops.<name> instead of string literals.

classdef Ops
  properties (Constant)
    tInput      = 'tOCleaningInput'
    tOutput     = 'tOInspectionOutput'
    pDone       = 'pODone'

    nCleaners   = 2
    nInspectors = 10

    % pOClean -> tOClean_1..n -> pOInspect -> tOInspect_1..n -> pODone
    net = chain('O', {'Clean', 'Inspect'}, [Ops.nCleaners, Ops.nInspectors], Ops.pDone)
  end
end
