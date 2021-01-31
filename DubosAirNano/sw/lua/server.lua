options = require('settings')

owpin = 4
ow.setup(owpin)
ow.reset_search(owpin)
dsaddr = ow.search(owpin)
dozoraddr = string.char(199, 194, 195, 196, 197, 198, 199, 218)   --Dozor Meteo
ow.reset(owpin)
ow.select(owpin, dozoraddr) --MATCH ROM
ow.write(owpin, 0xBE, 1) --READ SCRATCHPAD
data = string.char(ow.read(owpin))
for i = 1, 4 do
    data = data .. string.char(ow.read(owpin))
end

srv = net.createServer(net.TCP)
function receiver(sck, data)
    local tg, val
    a, b, c, d, e = string.match(data,"?(%a+)=(.+)&(%a+)=(.+)&(.+)")

    if((a == "wifissid") and (c == "wifipwd")) then
        if file.open("settings.lua", "r+") then
            file.readline()
            file.writeline('    wifissid = "'..b..'",')
            file.write('    wifipwd = "'..d)
            file.writeline('"')
            file.close()
        end
        options.wifissid = b
        options.wifipwd = d
    end

    sck:on("sent", function() sck:close() end)    
    local senddata = "<h1 align='center'>Панель управления станцией Dubos Air Nano (v1)</h1><br><p><b>MAC-адрес станции:</b> "
    senddata = senddata..wifi.ap.getmac().."</p><br>"
    if(dsaddr ~= nil) then 
        senddata = senddata.."<p>Обнаружен DS18B20 ("
        senddata = senddata..dsaddr:byte(1).." "..dsaddr:byte(2).." "..dsaddr:byte(3).." "..dsaddr:byte(4).." "..dsaddr:byte(5).." "..dsaddr:byte(6).." "..dsaddr:byte(7).." "..dsaddr:byte(8)..")</p>"
    end
    if(data:byte(5) == 164) then senddata = senddata.."<p>Обнаружен Outdoor module</p>"
    else senddata = senddata.."Outdoor module не обнаружен</p>"
    end
    senddata = senddata.."<br><form action='handler.php'><h2>Настройка WiFi</h2><p>SSID: <input name='wifissid' type='text' value='"
    senddata = senddata..options.wifissid.."'></p><p>Пароль: <input name='wifipwd' type='password' value='"
    senddata = senddata..options.wifipwd.."'></p><p><input type='submit' value='Сохранить' name='submit'></p></form>"
    sck:send(senddata)
end
srv:listen(80, function(conn)
  conn:on("receive", receiver)
end)