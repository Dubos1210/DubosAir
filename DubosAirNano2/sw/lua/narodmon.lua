print("Starting narodmon.lua")

dofile("nm_init.lua")

function nm_send() 
	if(wifi.sta.getip() ~= nil) then
		local senddata = "#"..nm_mac.."\n"
		senddata = senddata.."#uptime#"..uptime.."\n"
		if(wifi.sta.getrssi() ~= nil) then senddata = senddata.."#rssi#"..wifi.sta.getrssi().."\n" end
		if(out_count > 0) then
			t = out_t / out_count
			t1 = t / 100
			t2 = t % 100
			print("Outdoor temperature = "..t1.."."..t2)
			senddata = senddata .. "#OUT_TEMP#"..t1.."."..t2.."\n"
			
			h = out_h / out_count
			h1 = h / 100
			h2 = h % 100
			print("Outdoor humidity = "..h1.."."..h2)
			senddata = senddata .. "#OUT_HUM#"..h1.."."..h2.."\n"
		end        
		if(ds_count > 0) then   
			   t = ds_t / ds_count
			   t1 = t / 10000
			   t2 = t % 10000
			   print("DS18B20 = "..t1.."."..t2)
			   senddata = senddata .. "#DS18B20#"..t1.."."..t2.."\n"
		end
		senddata = senddata .. "#IN_COUNT#"..in_count.."\n"
		if(alarm) then 
			senddata = senddata.."#ALARM#1\n"
		else 
			senddata = senddata.."#ALARM#0\n"
		end
		senddata = senddata .. "##"

		local srv = net.createConnection(net.TCP, 0)
		srv:on("connection", function(sck, c)
			sck:send(senddata)
		end)
		srv:on("receive", function(sck, s)
			s1 = s:reverse()
			if(s1:find(string.reverse("ALARM=1")) ~= nil) then
				alarm = true
				print("Alarm mode ON")
			elseif(s1:find(string.reverse("ALARM=0")) ~= nil) then
				alarm = false
				print("Alarm mode OFF")
			end
			srv:close()
			srv = nil
		end)
		srv:connect(8283, "narodmon.ru")
		--srv:connect(8283, "192.168.1.100")

		uptime = uptime + 1
	else
		print("Failed to connect WiFi")
		return
	end
	   
	in_count = 0
	narod_count = 0
	ds_count = 0
	ds_t = 0
	out_count = 0
	out_t = 0
	out_h = 0
end

function nm_data()
	--1W start
	ow.reset(owpin)
	ow.write(owpin, 0xCC, 1) --SKIP ROM
	ow.write(owpin, 0x44, 1) --CONVERT T
	tmr.delay(1000000)
	-- Dozor Outdoor
	ow.reset(owpin)
	ow.select(owpin, dozoraddr) --MATCH ROM
	ow.write(owpin, 0xBE, 1) --READ SCRATCHPAD
	data = string.char(ow.read(owpin))
	for i = 1, 4 do
		data = data .. string.char(ow.read(owpin))
	end
	if(data:byte(5) == 164) then
		t = (data:byte(4) + data:byte(3) * 256) * 17572
		t = (t / 65536) - 4685
		out_t = out_t + t
		h = (data:byte(2) + data:byte(1) * 256) * 12500
		h = (h / 65536) - 600
		out_h = out_h + h
		out_count = out_count + 1
	end
	--DS18B20
	if(dsaddr ~= nil) then
		ow.reset(owpin)
		ow.select(owpin, dsaddr) --MATCH ROM
		ow.write(owpin, 0xBE, 1) --READ SCRATCHPAD
		data = string.char(ow.read(owpin))
		for i = 1, 8 do
			data = data .. string.char(ow.read(owpin))
		end
		crc = ow.crc8(string.sub(data,1,8))
		if crc == data:byte(9) then
			t = (data:byte(1) + data:byte(2) * 256) * 625
			ds_t = ds_t + t
			ds_count = ds_count + 1
		end
	end

	narod_count = narod_count + 1

	if(narod_count >= 6) then nm_send() end
end

nm_data()

tmr.create():alarm(60000, tmr.ALARM_AUTO, nm_data)
