function k = poisson(lambda)
% A Poisson draw without the Statistics Toolbox (Knuth's method):
% count uniform draws until their product drops below e^-lambda.
k = 0; p = rand;
while p > exp(-lambda)
    k = k + 1; p = p*rand;
end
