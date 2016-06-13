module("luci.controller.myprint.index", package.seeall)

function index()
	-- body
	page = entry({"myprint"}, template("myprint/myprint"))
	page.dependent = false
end
