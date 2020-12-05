my_data = { "one", "two", "three" }
table_map = { one = 1, two = "2", three = {} };

function init_x(v) 
  x = table_map[my_data[v]];
end

init_x(1)
print(x)