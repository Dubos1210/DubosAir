dofile("settings.lua")

print("\t\t=== DubosAirNano2 ===")

wifi_got_ip_event = function(T)
    print("IP: "..T.IP)
    tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() dofile("narodmon.lua") end)
end

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)

wifi.setmode(wifi.STATION)
wifi.sta.config({ssid = wifissid, pwd = wifipwd})
wifi.sta.sethostname("DubosAirNano2")