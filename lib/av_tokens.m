function a = av_tokens(sim, places)
% Time-weighted mean of the tokens in places (summed), over the whole run.
% GPenSIM v11 has no avtokens; the log has a row per state change.
global PN
PN = sim;
TM = extractp(places);
t = TM(2:end, 1);                       % a row holds from its time to the next row's
T = max(PN.completion_time, t(end));
tok = sum(TM(2:end, 2:end), 2);
a = sum(tok .* diff([t; T])) / (T - t(1));
