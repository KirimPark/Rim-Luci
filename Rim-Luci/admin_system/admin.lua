--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local fs = require "nixio.fs"

m = Map("system", translate("라우터 비밀번호"),
	translate("장치에 접근하기 위한 관리자의 비밀번호를 변경합니다"))

s = m:section(TypedSection, "_dummy", "")
s.addremove = false
s.anonymous = true

pw1 = s:option(Value, "pw1", translate("비밀번호"))
pw1.password = true

pw2 = s:option(Value, "pw2", translate("비밀번호 확인"))
pw2.password = true

function s.cfgsections()
	return { "_pass" }
end

function m.on_commit(map)
	local v1 = pw1:formvalue("_pass")
	local v2 = pw2:formvalue("_pass")

	if v1 and v2 and #v1 > 0 and #v2 > 0 then
		if v1 == v2 then
			if luci.sys.user.setpasswd(luci.dispatcher.context.authuser, v1) == 0 then
				m.message = translate("Password successfully changed!")
			else
				m.message = translate("Unknown Error, password not changed!")
			end
		else
			m.message = translate("Given password confirmation did not match, password not changed!")
		end
	end
end


if fs.access("/etc/config/dropbear") then

m2 = Map("dropbear", translate("SSH Access (Secure Shell)"),
	translate("<abbr title=\"Secure Shell\">SSH</abbr> 네트워크 셀 액세스와 통합된 <abbr title=\"Secure Copy\">SCP</abbr> 서버를 제공하는 Dropbear"))

s = m2:section(TypedSection, "dropbear", translate("Dropbear Instance"))
s.anonymous = true
s.addremove = true


ni = s:option(Value, "Interface", translate("Interface"),
	translate("지정하지 않을 시에 모두에게 interface 제공"))

ni.template    = "cbi/network_netlist"
ni.nocreate    = true
ni.unspecified = true


pt = s:option(Value, "Port", translate("Port"),
	translate("<em>Dropbear</em>내부 인스턴스의 수신 대기포트를 지정"))

pt.datatype = "port"
pt.default  = 22


pa = s:option(Flag, "PasswordAuth", translate("비밀번호  인증"),
	translate("<abbr title=\"Secure Shell\">SSH</abbr>접근 시 비밀번호 인증 여부"))

pa.enabled  = "on"
pa.disabled = "off"
pa.default  = pa.enabled
pa.rmempty  = false


ra = s:option(Flag, "RootPasswordAuth", translate("Allow root logins with password"),
	translate("<em>root</em>권한으로 로그인 시 비밀번호 인증 여부"))

ra.enabled  = "on"
ra.disabled = "off"
ra.default  = ra.enabled


gp = s:option(Flag, "Gateway ports", translate("게이트 웨이 Port"),
	translate("원격 호스트가 SSH전달 Port에 연결 허용 여부"))

gp.enabled  = "on"
gp.disabled = "off"
gp.default  = gp.disabled


s2 = m2:section(TypedSection, "_dummy", translate("SSH-Keys"),
	translate("공용 SSH키 (선 당 하나) SSH 공개 키 인증을 붙여 넣을 수 있습니다."))
s2.addremove = false
s2.anonymous = true
s2.template  = "cbi/tblsection"

function s2.cfgsections()
	return { "_keys" }
end

keys = s2:option(TextValue, "_data", "")
keys.wrap    = "off"
keys.rows    = 3
keys.rmempty = false

function keys.cfgvalue()
	return fs.readfile("/etc/dropbear/authorized_keys") or ""
end

function keys.write(self, section, value)
	if value then
		fs.writefile("/etc/dropbear/authorized_keys", value:gsub("\r\n", "\n"))
	end
end

end

return m, m2
