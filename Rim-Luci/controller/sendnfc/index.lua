module("luci.controller.sendnfc.index", package.seeall)

function index()
	page = entry({"sendnfc"}, cbi("sendnfc/sendnfc"))
  	page.dependent = false
  
  -- å¿…é ˆä»?root èº«åˆ†?»å…¥
  page.sysauth = "root"
  page.sysauth_authenticator = "htmlauth"    
  
  -- å®šç¾©ç¯€é»? request ?‚æœƒ?¼å« action_logout ?½å¼
  entry({"fblikes", "logout"}, call("action_logout"), "로그아웃")
end

function action_logout()
  local dsp = require "luci.dispatcher"
  local sauth = require "luci.sauth"
  if dsp.context.authsession then
  	sauth.kill(dsp.context.authsession)
  	dsp.context.urltoken.stok = nil
  end
  
  luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
  -- redirect to /cgi-bin/luci/fblikes
  luci.http.redirect(luci.dispatcher.build_url() .. "/sendnfc")
end
 
