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


if luci.http.formvalue("cbid.luci.1._list") then
	luci.http.redirect(luci.dispatcher.build_url("admin/system/flashops/backupfiles") .. "?display=list")
elseif luci.http.formvalue("cbid.luci.1._edit") then
	luci.http.redirect(luci.dispatcher.build_url("admin/system/flashops/backupfiles") .. "?display=edit")
	return
end

m = SimpleForm("luci", translate("백업 파일 목록"))
m:append(Template("admin_system/backupfiles"))

if luci.http.formvalue("display") ~= "list" then
	f = m:section(SimpleSection, nil, translate("시스템 업그레이드동안 포함 할 파일과 디렉토리를 일치시키기위한 shell glob partterns의 목록입니다. 수정된 파일은 /etc/config/ 및 기타 구성에서 자동으로 유지됩니다."))

	l = f:option(Button, "_list", translate("핸재 백업된 파일 목록 보기"))
	l.inputtitle = translate("목록 열기")
	l.inputstyle = "apply"

	c = f:option(TextValue, "_custom")
	c.rmempty = false
	c.cols = 70
	c.rows = 30

	c.cfgvalue = function(self, section)
		return nixio.fs.readfile("/etc/sysupgrade.conf")
	end

	c.write = function(self, section, value)
		value = value:gsub("\r\n?", "\n")
		return nixio.fs.writefile("/etc/sysupgrade.conf", value)
	end
else
	m.submit = false
	m.reset  = false

	f = m:section(SimpleSection, nil, translate("Below is the determined list of files to backup. It consists of changed configuration files marked by opkg, essential base files and the user defined backup patterns."))

	l = f:option(Button, "_edit", translate("구성으로 돌아가기"))
	l.inputtitle = translate("목록 닫기")
	l.inputstyle = "link"


	d = f:option(DummyValue, "_detected")
	d.rawhtml = true
	d.cfgvalue = function(s)
		local list = io.popen(
			"( find $(sed -ne '/^[[:space:]]*$/d; /^#/d; p' /etc/sysupgrade.conf " ..
			"/lib/upgrade/keep.d/* 2>/dev/null) -type f 2>/dev/null; " ..
			"opkg list-changed-conffiles ) | sort -u"
		)

		if list then
			local files = { "<ul>" }

			while true do
				local ln = list:read("*l")
				if not ln then
					break
				else
					files[#files+1] = "<li>"
					files[#files+1] = luci.util.pcdata(ln)
					files[#files+1] = "</li>"
				end
			end

			list:close()
			files[#files+1] = "</ul>"

			return table.concat(files, "")
		end

		return "<em>" .. translate("No files found") .. "</em>"
	end

end

return m
