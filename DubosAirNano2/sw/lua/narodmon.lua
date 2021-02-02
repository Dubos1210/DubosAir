dofile("nm_init.lua")

function nm_send() 
	print("[NM] Sending")
	if(wifi.sta.getip() ~= nil) then
		local senddata = "#"..nm_mac.."\n"
		senddata = senddata.."#uptime#"..uptime.."\n"
		if(wifi.sta.getrssi() ~= nil) then senddata = senddata.."#rssi#"..wifi.sta.getrssi().."\n" end
		if(out_count > 0) then
			local t = out_t_sum / out_count
			local t1 = t / 100
			local t2 = t % 100
			--print("Outdoor temperature = "..t1.."."..t2)
			senddata = senddata .. "#OUT_TEMP#"..t1.."."..t2.."\n"
			
			local h = out_h_sum / out_count
			local h1 = h / 100
			local h2 = h % 100
			--print("Outdoor humidity = "..h1.."."..h2)
			senddata = senddata .. "#OUT_HUM#"..h1.."."..h2.."\n"
		end        
		if(ds1_count > 0) then   
			local t = ds1_t_sum / ds1_count
			local t1 = t / 10000
			local t2 = t % 10000
			--print("DS18B20 1 = "..t1.."."..t2)
			senddata = senddata .. "#DS18B20_"..ds1addr:byte(8)
			senddata = senddata.."#"..t1.."."..t2.."\n"
		end
		if(ds2_count > 0) then   
			local t = ds2_t_sum / ds2_count
			local t1 = t / 10000
			local t2 = t % 10000
			--print("DS18B20 2 = "..t1.."."..t2)
			senddata = senddata .. "#DS18B20_"..ds2addr:byte(8)
			senddata = senddata.."#"..t1.."."..t2.."\n"
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
	measures = 0
	ds1_count = 0
	ds1_t_sum = 0
	ds2_count = 0
	ds2_t_sum = 0
	out_count = 0
	out_t_sum = 0
	out_h_sum = 0
end

function nm_tick()
	print("[NM] Measure "..measures+1)
	--1W start
	ow.reset(owpin)
	ow.write(owpin, 0xCC, 1) --SKIP ROM
	ow.write(owpin, 0x44, 1) --CONVERT T
	tmr.delay(1000000)
	-- Dozor Outdoor
	ow.reset(owpin)
	ow.select(owpin, dozoraddr) --MATCH ROM
	ow.write(owpin, 0xBE, 1) --READ SCRATCHPAD
	local data = string.char(ow.read(owpin))
	for i = 1, 4 do
		data = data .. string.char(ow.read(owpin))
	end
	if(data:byte(5) == 164) then
		local t = (data:byte(4) + data:byte(3) * 256) * 17572
		out_t = (t / 65536) - 4685
		out_t_sum = out_t_sum + out_t
		local h = (data:byte(2) + data:byte(1) * 256) * 12500
		out_h = (h / 65536) - 600
		out_h_sum = out_h_sum + out_h
		out_count = out_count + 1
	end
	--DS18B20 1
	if(ds1addr ~= nil) then
		ow.reset(owpin)
		ow.select(owpin, ds1addr) --MATCH ROM
		ow.write(owpin, 0xBE, 1) --READ SCRATCHPAD
		data = string.char(ow.read(owpin))
		for i = 1, 8 do
			data = data .. string.char(ow.read(owpin))
		end
		local crc = ow.crc8(string.sub(data,1,8))
		if crc == data:byte(9) then
			ds1_t = (data:byte(1) + data:byte(2) * 256) * 625
			ds1_t_sum = ds1_t_sum + ds1_t
			ds1_count = ds1_count + 1
		end
	end
	--DS18B20 2
	if(ds2addr ~= nil) then
		ow.reset(owpin)
		ow.select(owpin, ds2addr) --MATCH ROM
		ow.write(owpin, 0xBE, 1) --READ SCRATCHPAD
		data = string.char(ow.read(owpin))
		for i = 1, 8 do
			data = data .. string.char(ow.read(owpin))
		end
		local crc = ow.crc8(string.sub(data,1,8))
		if crc == data:byte(9) then
			ds2_t = (data:byte(1) + data:byte(2) * 256) * 625
			ds2_t_sum = ds2_t_sum + ds2_t
			ds2_count = ds2_count + 1
		end
	end

	measures = measures + 1

	if(measures >= 6) then nm_send() end
end

nm_tick()

tmr.create():alarm(60000, tmr.ALARM_AUTO, nm_tick)
