--[[Подмена MAC-адреса, если нужно]]
if(nm_mac == "" or nm_mac == nil) then
	nm_mac = wifi.sta.getmac()
end
print("NarodMon MAC: "..nm_mac)

--[[Инициализация 1-Wire]]
owpin = 4
ow.setup(owpin)
ow.reset_search(owpin)
ds1addr = ow.search(owpin)
if(ds1addr ~= nil) then print("DS18B20 (1) found at address ", ds1addr:byte(1,8)) end
ds2addr = ow.search(owpin)
if(ds2addr ~= nil) then print("DS18B20 (2) found at address ", ds2addr:byte(1,8)) end
print("Dozor Outdoor Module expected at address ", dozoraddr:byte(1,8))

--[[Инициализация счётного входа (прерывание)]]
inpin = 9
--inpin = 3
gpio.mode(inpin, gpio.INT)
gpio.trig(inpin, "up", function()
	in_count = in_count + 1
	if(alarm) then
		if(wifi.sta.getip() ~= nil) then
			print("ALARM: Sending SMS")
         
			local sms_srv = net.createConnection(net.TCP, 0)
			--local sms_srv = tls.createConnection()
			sms_srv:on("receive", function(sck, c) sms_srv:close(); sms_srv = nil end)
			sms_srv:on("connection", function(sck, c)
				sck:send("GET "..alarm_url.." HTTP/1.1\r\nHost: "..alarm_host.."\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")  
			end)
			sms_srv:connect(80, alarm_host)
		else
			print("ALARM: Failed to connect WiFi")
		end
		alarm = false
		print("Alarm mode OFF")
	end
end)

collectgarbage()
