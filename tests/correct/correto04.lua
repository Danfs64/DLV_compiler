
function foo(a)
    local b = {}
    return b
end

bar = foo(12)

function bar:_call()
    return 2
end

print(bar())