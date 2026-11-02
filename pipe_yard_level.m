function level = pipe_yard_level(difficulty)
% Minimum worker level for a difficulty: 1 = trainee, 2 = junior, 3 = senior.
level = find(strcmpi(difficulty, {'easy', 'moderate', 'hard'}), 1);
assert(~isempty(level), 'Difficulty must be easy, moderate or hard (got "%s").', difficulty);
end
