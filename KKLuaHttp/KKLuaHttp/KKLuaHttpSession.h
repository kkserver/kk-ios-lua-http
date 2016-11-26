//
//  KKLuaHttpSession.h
//  KKLuaHttp
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
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
 *    oncancel = function() end ,
 *    ondownload = function() end
 * }
 * task = http:send(options)
 * task:cancel()
 *
 * uri -> path
 * document:///path     ->  ~/Documents/path
 * app:///path          ->  ~/path
 * /path                ->  /path
 */

@interface KKLuaHttpSession : NSObject

-(instancetype) initWithSessionConfiguration:(NSURLSessionConfiguration *) configuration;

+(NSString *) pathWithURI:(NSString *) uri ;

@end
