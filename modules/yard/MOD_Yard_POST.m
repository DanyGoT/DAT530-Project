function [] = MOD_Yard_POST(transition)
% On to the next hall joint. Short orders go to the wash in runs, as in the
% hall data: when a short order is done and the run is under P.short_run
% joints, the next short order already in the yard is brought forward.
global global_info
switch transition.name
    case 'tYLong'
        global_info.run = 0;
    case 'tYShort'
        global_info.run = global_info.run + 1;
    otherwise
        return
end
global_info.next_hall = global_info.next_hall + 1;
if strcmp(transition.name, 'tYShort') && global_info.run < global_info.P.short_run
    next_short();
end


function [] = next_short()
% Bring the next short order forward, if all of it is in the yard. Short
% joints keep their order among themselves, so the first ntokens('pYShort')
% short joints left in the list are the ones in the yard.
global global_info
h = global_info.hall;
i = global_info.next_hall;
if i > numel(h) || strcmp(h(i).len, 'short'), return, end   % the order goes on
k = i - 1 + find(strcmp({h(i:end).len}, 'short'), 1);
if isempty(k), return, end
n = sum([h(k:end).order] == h(k).order);                     % an order's joints are together
if n > ntokens('pYShort'), return, end
global_info.hall = h([1:i-1, k:k+n-1, i:k-1, k+n:end]);
