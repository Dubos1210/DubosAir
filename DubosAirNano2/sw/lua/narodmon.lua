uptime = 0										--Счётчик циклов работы
ds1addr = string.char(0, 0, 0, 0, 0, 0, 0, 0)	--Адрес первого датчика DS18B20 на шине
ds1_t = 0										--Текущая температура DS1
ds2addr = string.char(0, 0, 0, 0, 0, 0, 0, 0)	--Адрес второго датчика DS18B20 на шине
ds2_t = 0										--Текущая температура DS2
dozoraddr = string.char(199, 194, 195, 196, 197, 198, 199, 218)   --Dozor Meteo
out_t = 0										--Текущая температура внешнего модуля
out_h = 0										--Текущая влажность внешнего модуля
in_count = 0									--Счётчик дискретного входа

alarm = false		--Охранный режим

dofile("nm_init.lua")

function nm_tick()
	if(wifi.sta.getip() ~= nil) then
		print("[NM] Measure and sending")

		local senddata = "#"..nm_mac.."\n"
		senddata = senddata.."#uptime#"..uptime.."\n"
		if(wifi.sta.getrssi() ~= nil) then senddata = senddata.."#rssi#"..wifi.sta.getrssi().."\n" end

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
			local h = (data:byte(2) + data:byte(1) * 256) * 12500
			out_h = (h / 65536) - 600

			local t1 = out_t / 100
			local t2 = out_t % 100
			--print("Outdoor temperature = "..t1.."."..t2)
			senddata = senddata .. "#OUT_TEMP#"..t1.."."..t2.."\n"
			local h1 = out_h / 100
			local h2 = out_h % 100
			--print("Outdoor humidity = "..h1.."."..h2)
			senddata = senddata .. "#OUT_HUM#"..h1.."."..h2.."\n"
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

				local t1 = ds1_t / 10000
				local t2 = ds1_t % 10000
				--print("DS18B20 1 = "..t1.."."..t2)
				senddata = senddata .. "#DS18B20_"..ds1addr:byte(8)
				senddata = senddata.."#"..t1.."."..t2.."\n"
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
				
				local t1 = ds2_t / 10000
				local t2 = ds2_t % 10000
				--print("DS18B20 2 = "..t1.."."..t2)
				senddata = senddata .. "#DS18B20_"..ds2addr:byte(8)
				senddata = senddata.."#"..t1.."."..t2.."\n"
			end
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
			oldalarm = alarm
			s1 = s:reverse()
			if(s1:find(string.reverse("ALARM=1")) ~= nil) then
				alarm = true
				print("Alarm mode ON")
			elseif(s1:find(string.reverse("ALARM=0")) ~= nil) then
				alarm = false
				print("Alarm mode OFF")
			end

			if(oldalarm ~= alarm) then
				local senddata = "#"..nm_mac.."\n"
				if(alarm) then 
					senddata = senddata.."#ALARM#1\n"
				else 
					senddata = senddata.."#ALARM#0\n"
				end
				senddata = senddata .. "##"

				sck:send(senddata)
			else
				srv:close()
				srv = nil
			end
		end)
		
		srv:connect(8283, "narodmon.ru")
		--srv:connect(8283, "192.168.1.100")
	else
		print("[NM] Failed to connect WiFi")
	end

	in_count = 0
end

nm_tick()

tmr.create():alarm(360000, tmr.ALARM_AUTO, nm_tick)
