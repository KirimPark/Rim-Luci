local fs = require "nixio.fs"
m = nil


if fs.access("/etc/config/nfc_config") then
	m = Map("nfc_config","Wi-Fi 정보를 NFC로 보내기","보내기 위해 NFC 모듈과 설정을 해주세요!")
	s = m:section(NamedSection, "main",translate("Main settings"))
	serial_url = s:option(Value, "serialport",translate("데이터를 보낼 포트 설정"))
  
  function wait_t(seconds)
  	-- body
  	local _start = os.time()
  	local _end = _start+seconds
  	while (_end ~= os.time())do
  	end
  end

  function serial_url.write(self, section, value)
	m.uci:set("nfc_config", section, self.option, value)
  -- os.execute("/etc/init.d/fblikes restart >/dev/null") -- not work! why?		 	
 	os.execute("nfc.sh &")
  end
        
  local bauds = {9600, 19200, 28800, 38400, 57600, 115200}  
  o = s:option(ListValue, "baud_rate", translate("전송 속도 설정"))
  for i = 1,#bauds do o:value(bauds[i]) end 
  o.write = serial_url.write
  
  -- Note: o.write is called only when options's value is changed
end

return m