//
//  KKLuaHttpData.h
//  KKLuaHttp
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KKLuaHttpDataItem : NSObject

@property(nonatomic,retain) NSString * key;

@end

@interface KKLuaHttpDataItemValue : KKLuaHttpDataItem

@property(nonatomic,retain) NSString * value;

@end

@interface KKLuaHttpDataItemBytes : KKLuaHttpDataItem

@property(nonatomic,retain) NSString * contentType;
@property(nonatomic,retain) NSData * bytes;
@property(nonatomic,retain) NSString * name;

@end

@interface VTHttpFormBody : NSObject


@property(nonatomic,readonly) NSArray * formItems;

@property(nonatomic,retain) NSString * contentType;

-(void) addItemValue:(NSString *) value forKey:(NSString *) key;

-(void) setItemValue:(NSString *) value forKey:(NSString *) key;

-(void) addItemBytes:(NSData *) bytesData contentType:(NSString *) contentType forKey:(NSString *) key;

-(void) setItemBytes:(NSData *) bytesData contentType:(NSString *) contentType forKey:(NSString *) key;

-(void) addItemBytes:(NSData *) bytesData contentType:(NSString *) contentType filename:(NSString *) filename forKey:(NSString *) key;

-(void) setItemBytes:(NSData *) bytesData contentType:(NSString *) contentType filename:(NSString *) filename forKey:(NSString *) key;

-(NSData *) bytesBody;

@end


@interface KKLuaHttpData : NSObject

@property(nonatomic,readonly) NSArray * formItems;

@property(nonatomic,retain) NSString * contentType;

@property(nonatomic,assign,getter=isMutilpart) BOOL mutilpart;

-(void) addItemValue:(NSString *) value forKey:(NSString *) key;

-(void) setItemValue:(NSString *) value forKey:(NSString *) key;

-(void) addItemBytes:(NSData *) bytesData contentType:(NSString *) contentType forKey:(NSString *) key;

-(void) setItemBytes:(NSData *) bytesData contentType:(NSString *) contentType forKey:(NSString *) key;

-(void) addItemBytes:(NSData *) bytesData contentType:(NSString *) contentType name:(NSString *) name forKey:(NSString *) key;

-(void) setItemBytes:(NSData *) bytesData contentType:(NSString *) contentType name:(NSString *) name forKey:(NSString *) key;

-(NSData *) bytesBody;

@end
