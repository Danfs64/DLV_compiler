
function f(x)
    y = 2*x
    return function -- lacks parentheses
        return y+1
    end
end

print(f(2)())
