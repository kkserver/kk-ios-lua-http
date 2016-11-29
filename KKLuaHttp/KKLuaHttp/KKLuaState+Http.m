//
//  KKLuaState+Http.m
//  KKLuaHttp
//
//  Created by zhanghailong on 2016/11/29.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import "KKLuaState+Http.h"
#import <KKHttp/KKHttp.h>

@implementation KKLuaState (Http)

-(void) openhttplibs {
    
    lua_pushObject(self.L, [KKHttp main]);
    lua_setglobal(self.L, "http");
    
}

@end
