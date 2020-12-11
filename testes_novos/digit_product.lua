function digitProduct(n)
  if n == 0 then
      return 0
  end
  
  local prod = 1
  
  repeat
      prod = prod * (n % 10)
      n = n // 10
  until n == 0
  
  return prod
end

print(digitProduct(12345)) -- fatorial de 5
