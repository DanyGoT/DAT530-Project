function [id, colors] = find_token(place, test)
% The first token in place that passes test (0 and {} if none).
p = get_place(place);
for tok = p.token_bank
    if test(tok)
        id = tok.tokID;
        colors = reshape(tok.color, 1, []);
        return
    end
end
id = 0; colors = {};
