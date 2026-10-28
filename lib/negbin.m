function k = negbin(m, r)
% A negative binomial draw with mean m and shape r (variance m + m^2/r): a
% Poisson draw whose rate is itself random (gamma), so some days are much
% busier than others. Gamma by Marsaglia and Tsang; needs r >= 1.
d = r - 1/3; c = 1/sqrt(9*d);
while true
    x = randn; v = (1 + c*x)^3;
    if v > 0 && log(rand) < x^2/2 + d - d*v + d*log(v), break, end
end
k = poisson(d*v * m/r);
