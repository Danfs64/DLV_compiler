function fizzbuzz(limit)
  for i = 1,limit do
      local str = (i % 3 == 0 and " Fizz" or "") .. (i % 5 == 0 and " Buzz" or "")
      
      if #str > 0 then
          print(str)
      else
          print(" " .. i)
      end
  end
end

fizzbuzz(20)
