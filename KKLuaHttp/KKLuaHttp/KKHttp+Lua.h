//
//  KKHttp+Lua.h
//  KKLuaHttp
//
//  Created by zhanghailong on 2016/11/29.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import <KKHttp/KKHttp.h>
#import <KKLua/KKLua.h>

/**
 * options = {
 *    method="GET"|"POST"
 *    url = {}
 *    body = {}|"text"|"uri"
 *    type = "json"|"text"|"uri"
 *    headers = {}
 *    timeout = 1.3
 *    onload = function(data,err) end ,
 *    onfail = function(err) end ,
 *    onprocess = function(value,maxValue) end,
 *    onresponse = function(response) end ,
 * }
 * task,err = http:send(options,weakObject)
 * task:cancel()
 *
 * http:cancel(weakObject)
 *
 * path,key,cached = http.cache(url)
 *
 * uri -> path
 * document:///path     ->  ~/Documents/path
 * app:///path          ->  ~/path
 * /path                ->  /path
 */
@interface KKHttp (Lua)

@end

@interface KKHttpTask (Lua)

@end
