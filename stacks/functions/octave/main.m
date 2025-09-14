% Wczytaj dane (jeśli istnieją) lub użyj wektora przykładowego
data_path = fullfile(fileparts(mfilename('fullpath')), 'data', 'data.mat');
if exist(data_path, 'file')
  S = load(data_path);
  if isfield(S, 'x')
    x = S.x;
  else
    x = 1:5;
  end
else
  x = 1:5;
end

result = compute(x);
fprintf('Result: %.2f\n', result);


