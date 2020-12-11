function collatz_seq(n)
  if n <= 1 then
      return n
  else
      return n .. " " .. collatz_seq(n % 2 == 0 and n/2 or 3*n+1)
  end
end

print(collatz_seq(27))
