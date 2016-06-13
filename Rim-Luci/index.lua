module("luci.controller.TizenXOpenwrt.index", package.seeall)

local encryptions = {}
	encryptions[1] = { code = "none", label = "None" }
	encryptions[2] = { code = "wep", label = "WEP" }
	encryptions[3] = { code = "psk", label = "WPA" }
	encryptions[4] = { code = "psk2", label = "WPA2" }
	encryptions[5] = { code = "psk-mixed", label = "WPA/WPA2 혼합"}
local protocols = {}
	protocols[1] = { code = "static", label = "정적할당" }
	protocols[2] = { code = "dhcp", label = "동적할당" }
	protocols[3] = { code = "pppoe", label = "PPPOE" }
local channels = {}
	channels[1] = { code = "auto", label ="자동"}
	channels[2] = { code = "1", label="1 (2.412 GHz)"}
	channels[3] = { code = "2", label="2 (2.417 GHz)"}
	channels[4] = { code = "3", label="3 (2.422 GHz)"}
	channels[5] = { code = "4", label="4 (2.427 GHz)"}
	channels[6] = { code = "5", label="5 (2.432 GHz)"}
	channels[7] = { code = "6", label="6 (2.437 GHz)"}
	channels[8] = { code = "7", label="7 (2.442 GHz)"}
	channels[9] = { code = "8", label="8 (2.447 GHz)"}
	channels[10] = { code = "9", label="9 (2.452 GHz)"}
	channels[11] = { code = "10", label="10 (2.457 GHz)"}
	channels[12] = { code = "11", label="11 (2.462 GHz)"}

local function not_nil_or_empty(value)
	return value and value ~="" --return valuable value
end
local function param(x)
		return luci.http.formvalue(x)
	end
local function params(name)
	local val = luci.http.formvalue(name)
	if val then
		val = luci.util.trim(val)
		if string.len(val) > 0 then
			return val
		end
		return nil
	end
	return nil
end
local function get_first(cursor, config, type, option)
	return cursor:get_first(config, type, option)
end
local function set_first(cursor, config, type, option, value)
	return cursor:foreach(config, type, function (s)
		if s[".type"] == type then
			cursor:set(config, s[".name"], option, value)
		end
	end)
end
local function set_list_first(cursor, config, type, option, value)
	return cursor:foreach(config, type, function (s)
		if s[".type"] == type then
			cursor:set_list(config, s[".name"], option, value)
		end
	end)
end
local function delete_first(cursor, config, type, option)
	return cursor:foreach(config, type, function (s)
		if s[".type"] == type then
			cursor:delete(config, s[".name"], option)
		end
	end)
end
function http_error(code, text)
  luci.http.prepare_content("text/plain")
  luci.http.status(code)
  if text then
    luci.http.write(text)
  end
end

--homepage menu and Initialize
function index()
	local function make_entry(path, target, title, order) --add entry
		local page = entry(path, target, title, order)
		page.leaf = true
		return page
	end
	--webpanel

	local TizenXOpenwrt = entry({ "TizenXOpenwrt" }, alias("TizenXOpenwrt", "go_to_homepage"), _("기본 설정 페이지"), 10)
 	TizenXOpenwrt.sysauth = "root"
  	TizenXOpenwrt.sysauth_authenticator = "htmlauth"

	make_entry({ "TizenXOpenwrt", "homepage" }, call("homepage"), _("기본 설정 페이지"),10) --Call function homepage
	make_entry({ "TizenXOpenwrt", "go_to_homepage" }, call("go_to_homepage"), nil)
	make_entry({ "TizenXOpenwrt", "config" }, call("config"), nil)
	make_entry({ "TizenXOpenwrt", "network_config" }, call("network_config"), nil)
	make_entry({ "TizenXOpenwrt", "admin_pass"}, call("admin_pass"), nil)
	make_entry({ "TizenXOpenwrt", "reboot"}, call("reboot"), nil)
end
--redirect
function go_to_homepage()
  luci.http.redirect(luci.dispatcher.build_url("TizenXOpenwrt/homepage"))
end

function homepage()
	local wa = require("luci.tools.webadmin")
	local network = luci.util.exec("LANG=en ifconfig | grep HWaddr") -- get info access to router 
	network = string.split(network, "\n")
	local ifnames = {} -- Mac addresses initialize
	for i, v in ipairs(network) do
		local ifname = luci.util.trim(string.split(network[i], " ")[1])
		if not_nil_or_empty(ifname) then -- judge empty ifname -> if not empty name then insert table ifname
			table.insert(ifnames,ifname)
		end -- if end
	end -- for end


	local ifaces_pretty_names = { 
		wlan0 = "와이파이",
		eth1 = "유선 연결"
	} -- define connection names

	local ifaces = {} -- initialize interfaces
	for i, ifname in ipairs(ifnames) do -- define interfaces ipaddress & netmask
		local ix = luci.util.exec("LANG=en ifconfig " .. ifname)
		local mac = ix and ix : match("HWaddr ([^%s]+)") or "-" -- get mac address
		ifaces[ifname] = {
			mac = mac:upper(), -- Uppercase Mac Address
			pretty_name = ifaces_pretty_names[ifname]
		}
		local address = ix and ix:match("inet addr:([^%s]+)") -- get ipaddress
		local netmask = ix and ix:match("Mask:([^%s]+)") -- get netmask
		if address then -- if have address return address and netmask
			ifaces[ifname]["address"] = address
			ifaces[ifname]["netmask"] = netmask
		end --if end
	end --for end

	local  deviceinfo = luci.sys.net.deviceinfo() --get device info
	for k, v in pairs(deviceinfo) do
		if ifaces[k] then
		ifaces[k]["tx"] = v[1] and wa.byte_format(tonumber(v[1])) or "-"
		ifaces[k]["rx"] = v[9] and wa.byte_format(tonumber(v[9])) or "-"
		end
	end -- tx,rx power of get interfaces 

	local ntm = require "luci.model.network".init()

	local devices = { }
	for _, dev in luci.util.vspairs(luci.sys.net.devices()) do
		if dev ~= "lo" and not ntm:ignore_interface(dev) then
			devices[#devices+1] = dev
		end
	end

	local ctx = {
		hostname = luci.sys.hostname() ,
		ifaces = ifaces
	} -- struct hostname

	luci.template.render("TizenXOpenwrt/homepage", ctx)
	return
end--homepage function end


function config_get()
	local uci = luci.model.uci.cursor()
	uci:load("wireless") -- get file /etc/config/wireless

	local ctx = {
		wifi={
		ssid = get_first(uci, "wireless", "wifi-iface", "ssid"),
		encryption = get_first(uci, "wireless", "wifi-iface", "encryption"),
		password = get_first(uci, "wireless", "wifi-iface", "key"),
		channel = get_first(uci, "wireless", "wifi-device", "channel"),
		
	}, -- get info in wireless file
		encryptions=encryptions,
		channels = channels
	}
	luci.template.render("TizenXOpenwrt/config", ctx) -- send to page
end

function config_post()
	params = luci.http.formvalue(config_form)
	local uci = luci.model.uci.cursor()
	uci:load("wireless")
	uci:load("network")
	uci:load("dhcp") -- load configs

	if params["wifi.ssid"] then
		set_first(uci, "wireless", "wifi-iface", "ssid", params["wifi.ssid"])
	end
	if params["wifi.encryption"] and params["wifi.password"] then
		if params["wifi.encryption"] == "none" then
		delete_first(uci, "wireless", "wifi-iface", "encryption",  params["wifi.encryption"])
		delete_first(uci, "wireless", "wifi-iface", "key", params["wifi.password"])
		else
		set_first(uci, "wireless", "wifi-iface", "encryption",  params["wifi.encryption"])
		set_first(uci, "wireless", "wifi-iface", "key", params["wifi.password"])
		end
	end
		uci:set("wireless", "radio0" , "country", "KR") -- set default region
		uci:set("wireless", "radio0" , "channel", params["wifi.channel"])
	uci:commit("wireless")
	uci:commit("network")

	local ctx = {
		wifi={
		ssid = get_first(uci, "wireless", "wifi-iface", "ssid"),
		encryption = get_first(uci, "wireless", "wifi-iface", "encryption"),
		password = get_first(uci, "wireless", "wifi-iface", "key"),
		channel = get_first(uci, "wireless", "wifi-device", "channel"),
		
	}, -- get info in wireless file
		encryptions=encryptions,
		channels = channels,
		submit_value = true
	}	

	luci.template.render("TizenXOpenwrt/config", ctx)
end
function network_config_get()
	local uci = luci.model.uci.cursor()
	uci:load("network") -- get file /etc/config/network

	local ctx = {
		wan = {
			protocol = uci:get("network", "wan", "proto"),
			ipaddress = uci:get("network", "wan", "ipaddr"),
			netmask = uci:get("network", "wan", "netmask"),
			gateway = uci:get("network", "wan", "gateway"),
			dns = uci:get("network", "wan", "dns"),
			username = uci:get("network", "wan", "username"),
			passwd = uci:get("network", "wan", "password"),
		},
		protocols=protocols
		
	}
	luci.template.render("TizenXOpenwrt/network_config",ctx)
	
end
function network_config_post()
	params = luci.http.formvalue(config_network_form)
	local uci = luci.model.uci.cursor()
	
	uci:load("network")
	uci:load("dhcp") -- load configs
	
	
	--set_first(uci, "network", "wan", "proto",  params["network.protocol"])
	uci:set("network", "wan", "proto",  params["network.protocol"])
	if params["network.protocol"] == "dhcp" then
	uci:delete("network", "wan", "ipaddr")
	uci:delete("network", "wan", "netmask")
	uci:delete("network", "wan", "gateway")
	uci:delete("network", "wan", "dns")	
	uci:delete("network", "wan", "username")
	uci:delete("network", "wan", "password")
	set_list_first(uci, "dhcp", "dnsmasq", "interface", "lo")
	elseif params["network.protocol"] == "pppoe" then
	uci:delete("network", "wan", "ipaddr")
	uci:delete("network", "wan", "netmask")
	uci:delete("network", "wan", "gateway")
	uci:delete("network", "wan", "dns")	
	uci:set("network", "wan", "username",  params["network.username"])
	uci:set("network", "wan", "password",  params["network.passwd"])
	set_list_first(uci, "dhcp", "dnsmasq", "interface", "lo")
	else
	uci:set("network", "wan", "ipaddr",  params["network.ipaddress"])
	uci:set("network", "wan", "netmask",  params["network.netmask"])
	uci:set("network", "wan", "gateway",  params["network.gateway"])
	uci:set("network", "wan", "dns",  params["network.dns"])
	uci:delete("network", "wan", "username")
	uci:delete("network", "wan", "password")
	set_list_first(uci, "dhcp", "dnsmasq", "interface", "lo","wan")
	--set_first(uci, "network", "wan", "ipaddr",  params["network.ipaddress"])
	--set_first(uci, "network", "wan", "netmask", params["network.netmask"])
	--set_first(uci, "network", "wan", "gateway",  params["network.gateway"])
	--set_first(uci, "network", "wan", "dns", params["network.dns"])
	end
	uci:commit("network")
 	--luci.util.exec("/etc/init.d/network reload")
	local ctx = {
		wan = {
			protocol = uci:get("network", "wan", "proto"),
			ipaddress = uci:get("network", "wan", "ipaddr"),
			netmask = uci:get("network", "wan", "netmask"),
			gateway = uci:get("network", "wan", "gateway"),
			dns = uci:get("network", "wan", "dns"),
			username = uci:get("network", "wan", "username"),
			passwd = uci:get("network", "wan", "password"),
		},
		submit_value = true,
		protocols=protocols,
		
	}

	luci.template.render("TizenXOpenwrt/network_config",ctx)
end
function config()
	if luci.http.getenv("REQUEST_METHOD") == "POST" then
		config_post()
	else
		config_get()
	end
end
function network_config()
	if luci.http.getenv("REQUEST_METHOD") == "POST" then
		network_config_post()
	else
		network_config_get()
	end
end
function admin_pass()
	if luci.http.getenv("REQUEST_METHOD") == "POST" then
		set_admin_pass()
	else
		luci.template.render("TizenXOpenwrt/setadmin")
	end
end
function set_admin_pass()
	local ret = "false"
	params = luci.http.formvalue(password_form)
	--if not_nil_or_empty(params["admin.password"]) then
	--	local password = params["admin.password"]
	--	luci.sys.user.setpasswd("root", password)
	--	ret = "true"
	--end
	if not_nil_or_empty(params["admin.password"]) then
		local password = params["admin.password"]
		luci.sys.user.setpasswd("root", password)
		ret = "true"
	end -- test
	ctx = {
	submit_value = ret
	}
	luci.template.render("TizenXOpenwrt/setadmin",ctx)
end

function reboot()
	ctx = {
	ret_reboot = true
	}
	luci.template.render("TizenXOpenwrt/homepage",ctx)
	luci.sys.reboot()

end