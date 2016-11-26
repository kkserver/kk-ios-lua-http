//
//  KKLuaHttpSession.m
//  KKLuaHttp
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import "KKLuaHttpSession.h"
#import "KKLuaHttpData.h"
#import <CommonCrypto/CommonDigest.h>

static int lua_http_send_function(lua_State * L);

@interface KKLuaSessionTask : KKLuaRef {
    NSMutableArray * _children;
    NSMutableData * _data;
}

@property(nonatomic,assign) NSUInteger identifier;
@property(nonatomic,strong) NSString * type;
@property(nonatomic,strong) NSString * path;
@property(nonatomic,strong) NSString * key;
@property(nonatomic,strong) NSString * tpath;

-(NSMutableURLRequest *) request;

-(void) onfail:(NSString *) error;

-(void) onload;

-(void) onprocess:(long long) value maxValue:(long long) maxValue;

-(void) onresponse:(NSURLResponse *) response;

-(void) ondata:(NSData *) data;

-(void) onbackgrounddata:(NSData *) data;

-(void) addChildren:(KKLuaSessionTask *) sessionTask;

-(BOOL) isNeedBackground;

@end

@interface KKLuaHttpSession () <NSURLSessionDataDelegate> {
    NSURLSession * _session;
    NSMutableDictionary * _tasks;
    NSMutableDictionary * _tasksWithKey;
    dispatch_queue_t _iodispatch;
}

@property(nonatomic,strong,readonly) NSURLSession * session;

-(void) addSessionTask:(KKLuaSessionTask *) task;

-(KKLuaSessionTask *) sessionTaskWithKey:(NSString *) key;

@end


@implementation KKLuaHttpSession

@synthesize session = _session;

-(instancetype) initWithSessionConfiguration:(NSURLSessionConfiguration *) configuration {
    if((self = [super init])) {
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue currentQueue]];
        _tasks = [[NSMutableDictionary alloc] initWithCapacity:4];
        _tasksWithKey = [[NSMutableDictionary alloc] initWithCapacity:4];
        _iodispatch = dispatch_queue_create("KKLuaHttpSession IO", nil);
    }
    return self;
}

+(NSString *) pathWithURI:(NSString *) uri {
    if([uri hasPrefix:@"document:///"]) {
        return [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[uri substringFromIndex:12]];
    }
    else if([uri hasPrefix:@"app:///"]) {
        return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[uri substringFromIndex:7]];
    }
    else if([uri hasPrefix:@"cache:///"]) {
        return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:[uri substringFromIndex:9]];
    }
    else {
        return uri;
    }
}


-(int) KKLuaObjectGet:(NSString *)key L:(lua_State *)L {
    if([key isEqualToString:@"send"]) {
        lua_pushcfunction(L, lua_http_send_function);
        return 1;
    }
    else {
        return [super KKLuaObjectGet:key L:L];
    }
}

-(void) addSessionTask:(KKLuaSessionTask *) task {
    [_tasks setObject:task forKey:@(task.identifier)];
    if(task.key) {
        [_tasksWithKey setObject:task forKey:task.key];
    }
}

-(KKLuaSessionTask *) sessionTaskWithKey:(NSString *) key {
    return [_tasksWithKey objectForKey:key];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
        didCompleteWithError:(nullable NSError *)error {
    
    NSNumber * key = @(task.taskIdentifier);
    KKLuaSessionTask * v = [_tasks objectForKey:key];
    
    if(v) {
        
        dispatch_block_t fn = ^{
            if(error) {
                [v onfail:[error localizedDescription]];
            }
            else {
                [v onload];
            }
            [v unref];
            if(v.key) {
                [_tasksWithKey setObject:task forKey:v.key];
            }
            [_tasks removeObjectForKey:key];
        };
        
        if([v isNeedBackground]) {
            NSOperationQueue * queue = self.session.delegateQueue;
            dispatch_async(_iodispatch, ^{
                [queue addOperationWithBlock:fn];
            });
        }
        else {
            fn();
        }
        
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSNumber * key = @(task.taskIdentifier);
    KKLuaSessionTask * v = [_tasks objectForKey:key];
    if(v) {
        [v onprocess:totalBytesSent maxValue:totalBytesExpectedToSend];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
    completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSNumber * key = @(dataTask.taskIdentifier);
    KKLuaSessionTask * v = [_tasks objectForKey:key];
    if(v) {
        [v onresponse:response];
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSNumber * key = @(dataTask.taskIdentifier);
    KKLuaSessionTask * v = [_tasks objectForKey:key];
    if(v) {
        
        if([v isNeedBackground]) {
            dispatch_async(_iodispatch, ^{
                [v onbackgrounddata:data];
            });
        }
        
        [v ondata:data];
    }
}

@end

@implementation KKLuaSessionTask

-(NSMutableURLRequest *) request {
    
    self.type = @"json";
    
    NSMutableURLRequest * r = nil;
    NSString * method = @"GET";
    NSString * url = nil;
    NSTimeInterval timeout = 60;
    
    lua_State * L = self.L;
    
    [self get];
    
    lua_pushstring(L, "method");
    lua_rawget(L, -2);
    if(lua_isstring(L, -1)) {
        method = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
    }
    lua_pop(L, 1);
    
    lua_pushstring(L, "url");
    lua_rawget(L, -2);
    if(lua_isstring(L, -1)) {
        url = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
    }
    lua_pop(L, 1);
    
    lua_pushstring(L, "timeout");
    lua_rawget(L, -2);
    if(lua_isnumber(L, -1)) {
        timeout = lua_tonumber(L, -1);
    }
    lua_pop(L, 1);
    
    lua_pushstring(L, "type");
    lua_rawget(L, -2);
    if(lua_isstring(L, -1)) {
        self.type = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
    }
    lua_pop(L, 1);

    if([self.type isEqualToString:@"uri"]) {
        method = @"GET";
    }
    
    if(url != nil) {
        
        lua_pushstring(L, "data");
        lua_rawget(L, -2);
        
        if([self.type isEqualToString:@"url"]) {
            
            if(lua_isstring(L, -1)) {
                self.path = [self createPathWithURI:[NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding]];
            }
            else {
                self.key = [self MD5String:url];
                self.path = [self createPathWithURI:[NSString stringWithFormat:@"cache:///kk/%@",self.key]];
            }
            
            r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
            
            r.HTTPMethod = method;
            
            self.tpath = [self.path stringByAppendingPathExtension:@"t"];
            
            NSFileManager * fm = [NSFileManager defaultManager];
            
            if([fm fileExistsAtPath:self.tpath]) {
                size_t size = [[fm attributesOfItemAtPath:self.tpath error:nil] fileSize];
                [r addValue:[NSString stringWithFormat:@"%ld-",size] forHTTPHeaderField:@"Range"];
            }
            
        }
        else if(lua_isstring(L, -1)) {
            
            r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
            
            r.HTTPMethod = method;
            
            if([method isEqualToString:@"POST"]) {
                size_t n = 0;
                const char * b = lua_tolstring(L, -1, &n);
                r.HTTPBody = [NSData dataWithBytes:b length:n];
            }
        }
        else if(lua_istable(L, -1)) {
            
            KKLuaHttpData * data = [[KKLuaHttpData alloc] init];
            
            lua_pushnil(L);
            
            while(lua_next(L, -2)) {
                
                if(lua_type(L, -2) == LUA_TSTRING) {
                    
                    NSString * key = [NSString stringWithCString:lua_tostring(L, -2) encoding:NSUTF8StringEncoding];
                    
                    if(lua_type(L, -1) == LUA_TTABLE) {
                        
                        NSString * name = nil;
                        NSString * uri = nil;
                        NSString * type = nil;
                        
                        lua_pushstring(L, "name");
                        lua_rawget(L, -2);
                        if(lua_isstring(L, -1)) {
                            name = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
                        }
                        lua_pop(L, 1);
                        
                        lua_pushstring(L, "uri");
                        lua_rawget(L, -2);
                        if(lua_isstring(L, -1)) {
                            name = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
                        }
                        lua_pop(L, 1);
                        
                        lua_pushstring(L, "type");
                        lua_rawget(L, -2);
                        if(lua_isstring(L, -1)) {
                            name = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
                        }
                        lua_pop(L, 1);
                        
                        if(uri != nil && type != nil) {
                            
                            NSData * bytes = [self bytesWithURI:uri];
                            
                            if(bytes) {
                                [data addItemBytes:bytes contentType:type name:name forKey:key];
                            }
                            
                        }
                        
                    }
                    else if(lua_type(L, -1) == LUA_TSTRING) {
                        [data addItemValue:[NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding] forKey:key];
                    }
                    
                }
                
                lua_pop(L, 1);
            }
            
            NSData * body = [data bytesBody];
            
            if([method isEqualToString:@"GET"]) {
                if(![data isMutilpart]) {
                    if([url hasSuffix:@"?"]) {
                        url = [url stringByAppendingString:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
                    }
                    else if([url containsString:@"?"]) {
                        url = [[url stringByAppendingString:@"&"] stringByAppendingString:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
                    }
                    else {
                        url = [[url stringByAppendingString:@"?"] stringByAppendingString:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
                    }
                }
                r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
                
                r.HTTPMethod = method;
            }
            else {
                
                r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
                
                r.HTTPMethod = method;
                r.HTTPBody = body;
                [r addValue:[data contentType] forHTTPHeaderField:@"Content-Type"];
            }
            
        }
        else {
            r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
            r.HTTPMethod = method;
        }
        
        lua_pop(L, 1);
        
        
        lua_pushstring(L, "headers");
        lua_rawget(L, -2);
        
        if(lua_istable(L, -1)) {
            
            lua_pushnil(L);
            
            while(lua_next(L, -2)) {
                
                if(lua_type(L, -2) == LUA_TSTRING) {
                    
                    NSString * key = [NSString stringWithCString:lua_tostring(L, -2) encoding:NSUTF8StringEncoding];
                    
                    if(lua_type(L, -1) == LUA_TSTRING) {
                        [r setValue:[NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding]  forHTTPHeaderField:key];
                    }
                    
                }
                
                lua_pop(L, 1);
            }
            
            
        }
        
        lua_pop(L, 1);

    }
    
    lua_pop(L, 1);
    
    return r;
}

-(void) addChildren:(KKLuaSessionTask *) sessionTask {
    if(_children == nil) {
        _children = [[NSMutableArray alloc] initWithCapacity:4];
    }
    [_children addObject:sessionTask];
}

-(void) onfail:(NSString *) error {
    
    lua_State * L  = self.L;
    
    [self get];
    
    lua_pushstring(L, "onfail");
    lua_rawget(L, -2);
    
    if(lua_isfunction(L, -1)) {
        
        lua_pushstring(L, [error UTF8String]);
        
        if(0 != lua_pcall(L, 1, 0, 0)) {
            NSLog(@"[KK][KKLuaHttp][KKLuaSessionTask] %s" ,lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        
    }
    
    lua_pop(L, 1);
    
    for(KKLuaSessionTask * v in _children) {
        [v onfail:error];
    }
    
}

-(void) onload {
    
    if(self.path) {
        [[NSFileManager defaultManager] moveItemAtPath:self.tpath toPath:self.path error:nil];
    }
    
    lua_State * L  = self.L;
    
    [self get];
    
    lua_pushstring(L, "onload");
    lua_rawget(L, -2);
    
    if(lua_isfunction(L, -1)) {
        
        if(self.path) {
            
            lua_pushstring(L, [self.path UTF8String]);
            
            if(0 != lua_pcall(L, 1, 0, 0)) {
                NSLog(@"[KK][KKLuaHttp][KKLuaSessionTask] %s" ,lua_tostring(L, -1));
                lua_pop(L, 1);
            }
        }
        else if([self.type isEqualToString:@"json"]) {
            
            NSError * err = nil;
            id object = [NSJSONSerialization JSONObjectWithData:_data options:NSJSONReadingMutableContainers error:& err];
            
            if(err == nil) {
                
                lua_pushObject(L, object);
                
                if(0 != lua_pcall(L, 1, 0, 0)) {
                    NSLog(@"[KK][KKLuaHttp][KKLuaSessionTask] %s" ,lua_tostring(L, -1));
                    lua_pop(L, 1);
                }
                
            }
            else {
                
                lua_pushnil(L);
                lua_pushstring(L, [[err localizedDescription] UTF8String]);
                
                if(0 != lua_pcall(L, 2, 0, 0)) {
                    NSLog(@"[KK][KKLuaHttp][KKLuaSessionTask] %s" ,lua_tostring(L, -1));
                    lua_pop(L, 1);
                }
            }
        }
        else {
            
            lua_pushlstring(L, [_data bytes], [_data length]);
            
            if(0 != lua_pcall(L, 1, 0, 0)) {
                NSLog(@"[KK][KKLuaHttp][KKLuaSessionTask] %s" ,lua_tostring(L, -1));
                lua_pop(L, 1);
            }

        }
        
    }
    
    lua_pop(L, 1);
    
    for(KKLuaSessionTask * v in _children) {
        [v onload];
    }
    
}

-(void) onprocess:(long long) value maxValue:(long long) maxValue {
    
    lua_State * L  = self.L;
    
    [self get];
    
    lua_pushstring(L, "onprocess");
    lua_rawget(L, -2);
    
    if(lua_isfunction(L, -1)) {
        
        lua_pushinteger(L, value);
        lua_pushinteger(L, maxValue);
        
        if(0 != lua_pcall(L, 2, 0, 0)) {
            NSLog(@"[KK][KKLuaHttp][KKLuaSessionTask] %s" ,lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        
    }
    
    lua_pop(L, 1);
    
    for(KKLuaSessionTask * v in _children) {
        [v onprocess:value maxValue:maxValue];
    }
    
}

-(void) onresponse:(NSURLResponse *) response {
    
    if(self.path) {
        NSFileManager * fm = [NSFileManager defaultManager];
        if(! [fm fileExistsAtPath:self.tpath]) {
            FILE * fd = fopen([self.tpath UTF8String], "wb");
            fclose(fd);
        }
    }
    else {
        _data = [[NSMutableData alloc] initWithCapacity:64];
    }
    
    lua_State * L  = self.L;
    
    [self get];
    
    lua_pushstring(L, "onresponse");
    lua_rawget(L, -2);
    
    if(lua_isfunction(L, -1)) {
        
        NSHTTPURLResponse * r = (NSHTTPURLResponse *) response;
        
        lua_pushObject(L, @{@"statusCode": @(r.statusCode),@"status": [NSHTTPURLResponse localizedStringForStatusCode:r.statusCode],@"headers": r.allHeaderFields});
        
        if(0 != lua_pcall(L, 1, 0, 0)) {
            NSLog(@"[KK][KKLuaHttp][KKLuaSessionTask] %s" ,lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        
    }
    
    lua_pop(L, 1);
    
}

-(BOOL) isNeedBackground {
    return self.path != nil;
}

-(void) onbackgrounddata:(NSData *) data {
    
    if(self.path) {
        FILE * fd = fopen([self.tpath UTF8String], "ab");
        fwrite([data bytes], 1, [data length], fd);
        fclose(fd);
    }
    
}

-(void) ondata:(NSData *) data {
    if(_data) {
        [_data appendData:data];
    }
}

-(NSData *) bytesWithURI:(NSString *) uri {
    return [NSData dataWithContentsOfFile:[KKLuaHttpSession pathWithURI:uri]];
}

-(NSString *) createPathWithURI:(NSString *) uri {
    NSString * path = [KKLuaHttpSession pathWithURI:uri];
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

-(NSString *) MD5String:(NSString *) v {
    
    CC_MD5_CTX md;
    
    CC_MD5_Init(&md);
    
    NSData * bytes = [v dataUsingEncoding:NSUTF8StringEncoding];
    
    CC_MD5_Update(&md, [bytes bytes], (CC_LONG) [bytes length]);
    
    unsigned char vs[16];
    
    CC_MD5_Final(vs, &md);
    
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x"
            ,vs[0],vs[1],vs[2],vs[3],vs[4],vs[5],vs[6],vs[7]
            ,vs[8],vs[9],vs[10],vs[11],vs[12],vs[13],vs[14],vs[15]];
}

@end

static int lua_http_send_function(lua_State * L) {
    
    int top = lua_gettop(L);
    
    if(top > 1 && lua_isObject(L, -top) && lua_istable(L, - top + 1)) {
        
        KKLuaHttpSession * v = lua_toObject(L, - top);
        
        lua_pushvalue(L, - top + 1);
        
        KKLuaSessionTask * task = [[KKLuaSessionTask alloc] initWithL:L];
        
        NSMutableURLRequest * r = [task request];
        
        if(r) {
            
            if(task.key && [v sessionTaskWithKey:task.key]) {
                
                KKLuaSessionTask * p = [v sessionTaskWithKey:task.key];
                [p addChildren:task];
                
            }
            else {
                
                NSURLSessionTask * t = [v.session dataTaskWithRequest:r];
                
                task.identifier = t.taskIdentifier;
                
                [v addSessionTask:task];
                
                [t resume];
                
            }
            
            lua_pushObject(L, task);
            
            return 1;
        } else {
            [task unref];
        }
    }
    
    return 0;
}
