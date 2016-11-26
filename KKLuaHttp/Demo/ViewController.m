//
//  ViewController.m
//  Demo
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import "ViewController.h"
#import <KKLuaHttp/KKLuaHttp.h>

@interface ViewController () {
    lua_State * _L;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _L = luaL_newstate();
    
    luaL_openlibs(_L);
    
    lua_pushObject(_L, [[KKLuaHttpSession alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]]);
    lua_setglobal(_L, "http");
    
    if(0 == luaL_loadfile(_L, [[[NSBundle mainBundle] pathForResource:@"main" ofType:@"lua"] UTF8String])) {
        
        if(0 != lua_pcall(_L, 0, 0, 0)) {
            NSLog(@"%s",lua_tostring(_L, -1));
            lua_pop(_L, 1);
        }
    }
    else {
        NSLog(@"%s",lua_tostring(_L, -1));
        lua_pop(_L, 1);
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
