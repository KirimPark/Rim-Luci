"use strict";
function send_post (e,t,n)
{
	var r={};
	for(var i=3;i<arguments.length;i++)
		t[arguments[i]].disabled||(r[arguments[i]]=t[arguments[i]].value);
	var s=doEncrypt(key_id,0,public_key,JSON.stringify(r));
	var o=document.getElementById(n);
	return o.submit(),!1
}