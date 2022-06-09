local tableRemove = table.remove
local timerSimple = timer.Simple

function util.TickLater(func)
    timerSimple(0,func)
end
function net.WriteCompressTable(tab)
    local data = util.Compress(util.TableToJSON(tab))
    local len = #data
    net.WriteUInt(len,16)
    net.WriteData(data,len)
    return len
end
function net.ReadCompressTable()
    local len = net.ReadUInt(16)
    return util.JSONToTable(util.Decompress(net.ReadData(len))),len
end
function net.PokeChannel(channel,ply) net.Start(channel) if SERVER then net.Send(ply) else net.SendToServer() end end
function table.ForceInsertM3(tab,var,x,y,z)
    tab[x] = tab[x] or {}
    tab[x][y] = tab[x][y] or {}
    tab[x][y][z] = var
end
function math.PowerRound(var,exp,up)
    return math.pow(exp,(up != nil and (up and math.ceil or math.floor) or math.Round)(math.log(var,exp)))
end

function table.RemoveIValue(tab,val)
    for index,check in ipairs(tab) do
        if val == check then
            tableRemove(tab,index)
        end
    end
end