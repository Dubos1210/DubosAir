options = require('settings')

gpio.mode(4, gpio.INPUT)
if(gpio.read(4) == 0) then
    print("=== Settings ===")
    print("Starting the web-server")
    wifi.setmode(wifi.SOFTAP)
    scfg = {
        save = false,
        auth = wifi.OPEN,
        ssid = "DubosAirNano",
        pwd = "12345678"
    }     
    wifi.ap.config(scfg)
    dofile("server.lua")
else 
    scfg = {
        auto = true,
        save = true,
        ssid = options.wifissid,
        pwd = options.wifipwd
    }
    wifi.setmode(wifi.STATION)
    wifi.sta.config(scfg)
    wifi.sta.sethostname("DubosAirNano")
    wifi.sta.connect()
    
    tmr.create():alarm(30000, tmr.ALARM_SINGLE, function()
        if(wifi.sta.getip() ~= nil) then
            print(wifi.sta.getip())
        else
            print("Failed to connect WiFi")
        end
        dofile("narodmon.lua")
    end)
end
