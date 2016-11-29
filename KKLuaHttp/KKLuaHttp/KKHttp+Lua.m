//
//  KKHttp+Lua.m
//  KKLuaHttp
//
//  Created by zhanghailong on 2016/11/29.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import "KKHttp+Lua.h"

static int lua_http_send_function(lua_State * L) {
    
    int top = lua_gettop(L);
    
    if(top > 1 && lua_isObject(L, -top) && lua_istable(L, - top + 1)) {
        
        KKHttp * v = lua_toObject(L, - top);
        
        id weakObject = top > 2 ? lua_toValue(L, -top +2) : nil;
        
        NSString * url = nil;
        
        lua_pushvalue(L, - top + 1);
        
        lua_pushstring(L, "url");
        lua_rawget(L, -2);
        
        if(lua_isstring(L, -1)) {
            url = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
        }
        
        lua_pop(L, 1);
        
        if(url != nil) {
            
            KKLuaRef * opt = [[KKLuaRef alloc] initWithL:L];
            
            [opt get];
        
            KKHttpOptions * options = [[KKHttpOptions alloc] initWithUrl:url];
        
            lua_pushstring(L, "method");
            lua_rawget(L, -2);
            
            if(lua_isstring(L, -1)) {
                options.method = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
            }
            
            lua_pop(L, 1);
            
            lua_pushstring(L, "type");
            lua_rawget(L, -2);
            
            if(lua_isstring(L, -1)) {
                options.type = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
            }
            
            lua_pop(L, 1);
            
            lua_pushstring(L, "data");
            lua_rawget(L, -2);
            
            options.data = lua_toValue(L, -1);
            
            lua_pop(L, 1);
            
            lua_pushstring(L, "headers");
            lua_rawget(L, -2);
            
            if(lua_istable(L, -1)) {
                options.headers = lua_toValue(L, -1);
            }
            
            lua_pop(L, 1);
            
            lua_pushstring(L, "timeout");
            lua_rawget(L, -2);
            
            if(lua_isnumber(L, -1)) {
                options.timeout = lua_tonumber(L, -1);
            }
            
            lua_pop(L, 1);
            
            options.onFail = ^(NSError * error , id weakObject) {
            
                lua_State * L = [opt L];
                
                [opt get];
            
                lua_pushstring(L, "onfail");
                lua_rawget(L, -2);
                
                if(lua_isfunction(L, -1)) {
                    
                    if(error) {
                        lua_pushstring(L, [[error localizedDescription] UTF8String]);
                    }
                    else {
                        lua_pushnil(L);
                    }
                    
                    if(0 != lua_pcall(L, 1, 0, 0)) {
                        NSLog(@"[KK][KKLuaHttp] %s",lua_tostring(L, -1));
                        lua_pop(L, 1);
                    }
                    
                }
                
                lua_pop(L, 1);
                
                lua_pop(L, 1);
                
            };
            
            options.onLoad = ^(id data, NSError * error, id weakObject) {
                
                lua_State * L = [opt L];
                
                [opt get];
                
                lua_pushstring(L, "onload");
                lua_rawget(L, -2);
                
                if(lua_isfunction(L, -1)) {
                    
                    lua_pushValue(L, data);
                    
                    if(error) {
                        lua_pushstring(L, [[error localizedDescription] UTF8String]);
                    }
                    else {
                        lua_pushnil(L);
                    }
                    
                    if(0 != lua_pcall(L, 2, 0, 0)) {
                        NSLog(@"[KK][KKLuaHttp] %s",lua_tostring(L, -1));
                        lua_pop(L, 1);
                    }
                    
                }
                
                lua_pop(L, 1);
                
                lua_pop(L, 1);
                
            };
            
            options.onProcess = ^(int64_t value,int64_t maxValue, id weakObject) {
                
                lua_State * L = [opt L];
                
                [opt get];
                
                lua_pushstring(L, "onprocess");
                lua_rawget(L, -2);
                
                if(lua_isfunction(L, -1)) {
                    
                    lua_pushinteger(L, value);
                    lua_pushinteger(L, maxValue);
                    
                    if(0 != lua_pcall(L, 2, 0, 0)) {
                        NSLog(@"[KK][KKLuaHttp] %s",lua_tostring(L, -1));
                        lua_pop(L, 1);
                    }
                    
                }
                
                lua_pop(L, 1);
                
                lua_pop(L, 1);
                
            };
            
            options.onResponse = ^(NSHTTPURLResponse * response, id weakObject) {
                
                lua_State * L = [opt L];
                
                [opt get];
                
                lua_pushstring(L, "onresponse");
                lua_rawget(L, -2);
                
                if(lua_isfunction(L, -1)) {
                    
                    lua_newtable(L);
                    
                    lua_pushstring(L, "statusCode");
                    lua_pushinteger(L, response.statusCode);
                    lua_rawset(L, -3);
                    
                    lua_pushstring(L, "status");
                    lua_pushstring(L, [[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode] UTF8String]);
                    lua_rawset(L, -3);
                    
                    lua_pushstring(L, "headers");
                    lua_newtable(L);
                    
                    for(NSString * key in [response allHeaderFields]) {
                        lua_pushstring(L, [key UTF8String]);
                        lua_pushstring(L, [[[response allHeaderFields] valueForKey:key] UTF8String]);
                        lua_rawset(L, -3);
                    }
                    
                    lua_rawset(L, -3);
                    
                    if(0 != lua_pcall(L, 1, 0, 0)) {
                        NSLog(@"[KK][KKLuaHttp] %s",lua_tostring(L, -1));
                        lua_pop(L, 1);
                    }
                    
                }
                
                lua_pop(L, 1);
                
                lua_pop(L, 1);
                
            };
            
            lua_pop(L,1);
            
            NSError * error = nil;
            
            KKHttpTask * task = [v send:options :weakObject error:&error];
            
            lua_pushObject(L, task);
            
            if(error == nil) {
                lua_pushnil(L);
            }
            else {
                lua_pushstring(L, [[error localizedDescription] UTF8String]);
            }
            
            return 2;
            
        }
        else {
            lua_pop(L, 1);
        }
    }
    
    return 0;
}

static int lua_http_cancel_function(lua_State * L) {
    
    int top = lua_gettop(L);
    
    if(top > 0 && lua_isObject(L, -top) ) {
        
        KKHttp * v = lua_toObject(L, - top);
        
        id weakObject = top > 1 ? lua_toValue(L, -top +1) : nil;
        
        [v cancel:weakObject];
        
    }
    
    return 0;
}

static int lua_http_cache_function(lua_State * L) {
    
    int top = lua_gettop(L);
    
    if(top > 0 && lua_isstring(L, -top ) ) {
        
        NSString * v  = [NSString stringWithCString:lua_tostring(L, -top ) encoding:NSUTF8StringEncoding];
        
        NSString * key = [KKHttpOptions cacheKeyWithUrl:v];
        NSString * path = [KKHttpOptions pathWithUri:[NSString stringWithFormat:@"cache:///kk/%@",key]];
        
        
        lua_pushstring(L, [path UTF8String]);
        lua_pushstring(L, [key UTF8String]);
        lua_pushboolean(L, [[NSFileManager defaultManager] fileExistsAtPath:path]);
        
        return 3;
        
    }
    
    return 0;
}

static int lua_http_task_cancel_function(lua_State * L) {
    
    int top = lua_gettop(L);
    
    if(top > 0 && lua_isObject(L, -top) ) {
        
        KKHttpTask * v = lua_toObject(L, - top);
        
        [v cancel];
        
    }
    
    return 0;
}

@implementation KKHttp (Lua)

-(int) KKLuaObjectGet:(NSString *)key L:(lua_State *)L {
    
    if([@"send" isEqualToString:key]) {
        lua_pushcfunction(L, lua_http_send_function);
        return 1;
    }
    else if([@"cancel" isEqualToString:key]) {
        lua_pushcfunction(L, lua_http_cancel_function);
        return 1;
    }
    else if([@"cache" isEqualToString:key]) {
        lua_pushcfunction(L, lua_http_cache_function);
        return 1;
    }
    else {
        return [super KKLuaObjectGet:key L:L];
    }
    
}

@end

@implementation KKHttpTask (Lua)

-(int) KKLuaObjectGet:(NSString *)key L:(lua_State *)L {
    
    if([@"cancel" isEqualToString:key]) {
        lua_pushcfunction(L, lua_http_task_cancel_function);
        return 1;
    }
    else {
        return [super KKLuaObjectGet:key L:L];
    }
    
}

@end

