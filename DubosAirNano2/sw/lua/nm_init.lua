uptime = 0
narod_count = 6
ds_count = 0
ds_t = 0
out_count = 0
out_t = 0
out_h = 0
in_count = 0

alarm = false
alarmNM = 0

owpin = 4
ow.setup(owpin)
ow.reset_search(owpin)
dsaddr = ow.search(owpin)
if(dsaddr ~= nil) then print("DS18B20 found at address ", dsaddr:byte(1,8)) end
dozoraddr = string.char(199, 194, 195, 196, 197, 198, 199, 218)   --Dozor Meteo
print("Dozor Outdoor Module expected at address ", dozoraddr:byte(1,8))

inpin = 9
gpio.mode(inpin, gpio.INT)
gpio.trig(inpin, "up", function()
    in_count = in_count + 1
    if(alarm) then
        alarmNM = 10
        if(wifi.sta.getip() ~= nil) then
            print("ALARM: Sending SMS")
            srv = net.createConnection(net.TCP, 0)
            srv:on("receive", function(sck, c) print(c); srv:close(); srv = nil end)
            srv:on("connection", function(sck, c)
                sck:send("GET "..alarm_url.." HTTP/1.1\r\nHost: sms.ru\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")  
            end)
            srv:connect(80, alarm_host)
        else
            alarmNM = alarmNM + 7
            print("ALARM: Failed to connect WiFi")
        end
        alarm = false
        print("Alarm mode OFF")
    end
end)
