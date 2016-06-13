module("luci.controller.myapp.mymodule",package.seeall) 

function index()
 page = entry({"myapp", "mymodule"},alias("myapp","mymodule","time.htm"),"abc",10)
 page.dependent = false
 entry({"myapp","mymodule","time.htm"},template("mymodule/time"),"ab",10)
 page.dependent = false; page.leaf = true
 end
