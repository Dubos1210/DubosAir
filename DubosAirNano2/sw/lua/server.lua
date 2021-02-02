srv = net.createServer(net.TCP)
function receiver(sck, data)
    sck:on("sent", function() sck:close(); print("[WEB] Respond") end)

    local password = false
    local light = false;
    if(data:find(web_pwd) ~= nil) then
        password = true
        if(data:find("light") ~= nil) then light = true end

        if(data:find("ALARM=0") ~= nil) then
            alarm = false
            print("Alarm mode OFF")
        elseif(data:find("ALARM=1") ~= nil) then
            alarm = true
            print("Alarm mode ON")
        end
    end

    local senddata = "<!DOCTYPE html><html lang=\"ru\"><head><META charset=\"UTF-8\"><title>DubosAirNano2</title><link rel=\"preload\"href=\"https://cdn.jsdelivr.net/npm/dseg@0.46.0/fonts/DSEG7-Classic/DSEG7Classic-BoldItalic.ttf\"as=\"font\"type=\"font/ttf\"crossorigin=\"anonymous\"><style>@font-face{font-family:'DSEG';src:url('https://cdn.jsdelivr.net/npm/dseg@0.46.0/fonts/DSEG7-Classic/DSEG7Classic-BoldItalic.ttf')}body{background:#111}*{margin:0;padding:0;font-family:'Arial',sans-serif}h1{color:white;text-align:center;font-style:italic}.panel{margin:15px;padding:15px;background:#222;border:1px solid white;color:white}.heading{color:white;margin-bottom:5px;font-size:60px;font-style:italic}.data{font-family:'DSEG';font-size:120px;text-align:right}.data-text{font-size:30px;text-align:right}.red{color:red}.orange{color:orange}.yellow{color:yellow}.green{color:green}.blue{color:dodgerblue}.violet{color:violet}.button a button{width:100%;font-style:italic;font-size:200px}</style></head><body><h1>Dubos Air Nano2</h1><hr>"
    
    if(not light) then
        local t1 = out_t / 100
        local t2 = out_t % 100
        senddata = senddata .. "<div class=\"panel red\"><p class=\"heading\">T на улице, °</p><p class=\"data\">"..t1.."."..t2.."</p></div>"
            
        local h1 = out_h / 100
        senddata = senddata .. "<div class=\"panel blue\"><p class=\"heading\">H на улице, %</p><p class=\"data\">"..h1.."</p></div>"     
        
        if(dsaddr ~= nil) then   
            local t = ds_t / 100
            local t1 = t / 100
            local t2 = t % 100
            senddata = senddata .. "<div class=\"panel orange\"><p class=\"heading\">T DS18B20, °</p><p class=\"data\">"..t1.."."..t2.."</p></div>"
        end
    end
    
    if(password) then
        senddata = senddata.."<br><div class=\"panel yellow\"><p class=\"heading\">Охрана</p><p class=\"data\">"
        if(alarm) then 
            senddata = senddata.."ON"
        else 
            senddata = senddata.."OFF"
        end
        senddata = senddata.."</p></div>"
    end

    if(not light) then
        senddata = senddata.."<div class=\"panel green\"><p class=\"heading\">Движение</p><p class=\"data\">"..in_count
        senddata = senddata.."</p></div><div class=\"panel\"><p class=\"heading\">RSSI, дБм</p><p class=\"data\">"..wifi.sta.getrssi()
        senddata = senddata.."</p></div>"
    end
    if(light) then
        senddata = senddata.."<br><div class=\"panel button\"><p class=\"heading\">Охрана</p><a href=\"/"..web_pwd
        senddata = senddata.."/light/ALARM=1\"><button>Вкл.</button></a></div><div class=\"panel button\"><p class=\"heading\">Охрана</p><a href=\"/"..web_pwd
        senddata = senddata.."/light/ALARM=0\"><button>Выкл.</button></a></div>"
    elseif(password) then
        senddata = senddata.."<br><div class=\"panel button\"><p class=\"heading\">Охрана</p><a href=\"/"..web_pwd
        senddata = senddata.."/light/ALARM=1\"><button>Вкл.</button></a></div><div class=\"panel button\"><p class=\"heading\">Охрана</p><a href=\"/"..web_pwd
        senddata = senddata.."/light/ALARM=0\"><button>Выкл.</button></a></div><div class=\"panel button\"><p class=\"heading\">Обновить</p><a href=\"/"..web_pwd
        senddata = senddata.."/\"><button>O</button></a></div><hr><div class=\"panel\"><p class=\"heading\">MAC-адрес станции:</p><p class=\"data-text\">"
        senddata = senddata..wifi.ap.getmac().."</p></div>"
    end

    senddata = senddata.."</body></html>"
    sck:send(senddata)
    print("[WEB] Prepared")
end

srv:listen(80, function(conn)
    print("[WEB] Request")
    conn:on("receive", receiver)
end)