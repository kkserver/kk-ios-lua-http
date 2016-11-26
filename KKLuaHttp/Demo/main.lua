

function log(...) 
	print("[KK]",...)
end

log("OK")

http:send({
	method="GET",
	url="http://www.baidu.com/img/baidu_jgylogo3.gif",
	type="url",
	onload = function(data)
		log(data)
	end,
	onfail = function(err)
		log(err)
	end,
	onresponse = function(response)
		log(response.headers["Content-Type"])
	end
})
