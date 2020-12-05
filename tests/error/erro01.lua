x = 2
local z, w = x + 1, 3

function foo()
    local y = 1 + x
    do
        local zzz = y + 2
    end
    y = y + zzz -- Erro
    return y
end

for id = 1, 2, 3 do
end
foo(id)
