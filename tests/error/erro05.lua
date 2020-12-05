
local x = 1

function foo()
    if x == 1 then
        local y = 2*x
        break -- Break in non loop block
    end
end

foo()
