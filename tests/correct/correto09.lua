function f123() return 1, 2, 3 end
function f456() return 4, 5, 6 end

print(table.getn({ f123(), f456() })) -- 4
print(f123(), f456()) -- prints 1, 4, 5, 6
print(f456(), f123()) -- prints 4, 1, 2, 3
