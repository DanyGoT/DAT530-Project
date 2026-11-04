function names = with_cert(levels)
% The resources for workers of these levels ({'L0', 'L1'}), with and without
% a forklift certificate, lowest level first and at each level the ones
% without a certificate first, so certified workers stay free to drive.
% Each level is two resources: 'L1' (no certificate) and 'L1T' (certificate).
names = reshape([levels; strcat(levels, 'T')], 1, []);
