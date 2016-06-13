module("luci.controller.test.index",package.seeall)

function index()
	-- body
	page = entry({"mymodule","time.htm"}, call("action_time"))
	page.dependent = false
	page.leaf = true
end

function action_time( ... )
	-- body
	luci.http.prepare_content("text/html")
	luci.http.write("<h1>Hello Luci</h1>")
	luci.http.write("<h2>Current time : "..os.date("%D %T").."</h2>")
end