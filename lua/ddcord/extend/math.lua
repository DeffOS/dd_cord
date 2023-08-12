module("math")
function PowerRound(var,exp,up)
    return pow(exp,(up != nil and (up and ceil or floor) or Round)(log(var,exp)))
end