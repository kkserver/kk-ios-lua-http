//
//  KKLuaHttpData.m
//  KKLuaHttp
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import "KKLuaHttpData.h"

#define HTTP_MULTIPART_TOKEN            "8jej23fkdxxd"
#define HTTP_MULTIPART_TOKEN_SIZE       12
#define HTTP_MULTIPART_TOKEN_BEGIN      "--8jej23fkdxxd"
#define HTTP_MULTIPART_TOKEN_BEGIN_SIZE (HTTP_MULTIPART_TOKEN_SIZE + 2)
#define HTTP_MULTIPART_TOKEN_END        "--8jej23fkdxxd--"
#define HTTP_MULTIPART_TOKEN_END_SIZE   (HTTP_MULTIPART_TOKEN_SIZE + 4)
#define HTTP_MULTIPART_CONTENT_TYPE     @"multipart/form-data; boundary=8jej23fkdxxd"

@implementation KKLuaHttpDataItem

@synthesize key = _key;

@end

@implementation KKLuaHttpDataItemValue

@synthesize value = _value;

@end

@implementation KKLuaHttpDataItemBytes

@synthesize bytes = _bytes;
@synthesize name = _name;
@synthesize contentType = _contentType;

@end

@interface KKLuaHttpData(){
    NSMutableArray * _formItems;
}

@end

@implementation KKLuaHttpData

@synthesize contentType = _contentType;
@synthesize formItems = _formItems;

-(void) addFormItem:(KKLuaHttpDataItem *) item{
    if(_formItems == nil){
        _formItems = [[NSMutableArray alloc] initWithCapacity:4];
    }
    [_formItems addObject:item];
}

-(void) setFormItem:(KKLuaHttpDataItem *) item{
    if(_formItems == nil){
        _formItems = [[NSMutableArray alloc] initWithCapacity:4];
    }
    else{
        NSInteger c = [_formItems count];
        NSInteger i = 0;
        
        while(i <c){
            KKLuaHttpDataItem * ii = [_formItems objectAtIndex:i];
            
            if([ii.key isEqualToString:item.key]){
                
                [_formItems removeObjectAtIndex:i];
                c --;
                continue;
            }
            
            i ++;
            
        }
    }
    [_formItems addObject:item];
}

-(void) addItemValue:(NSString *) value forKey:(NSString *) key{
    KKLuaHttpDataItemValue * item = [[KKLuaHttpDataItemValue alloc] init];
    item.key = key;
    item.value = value;
    [self addFormItem:item];
}

-(void) setItemValue:(NSString *) value forKey:(NSString *) key{
    KKLuaHttpDataItemValue * item = [[KKLuaHttpDataItemValue alloc] init];
    item.key = key;
    item.value = value;
    [self setFormItem:item];
}

-(void) addItemBytes:(NSData *) bytesData contentType:(NSString *) contentType forKey:(NSString *) key{
    KKLuaHttpDataItemBytes * item = [[KKLuaHttpDataItemBytes alloc] init];
    item.key = key;
    item.contentType = contentType;
    item.bytes = bytesData;
    [self addFormItem:item];
}

-(void) setItemBytes:(NSData *) bytesData contentType:(NSString *) contentType forKey:(NSString *) key{
    KKLuaHttpDataItemBytes * item = [[KKLuaHttpDataItemBytes alloc] init];
    item.key = key;
    item.contentType = contentType;
    item.bytes = bytesData;
    [self setFormItem:item];
}

-(void) addItemBytes:(NSData *) bytesData contentType:(NSString *) contentType name:(NSString *) name forKey:(NSString *) key{
    KKLuaHttpDataItemBytes * item = [[KKLuaHttpDataItemBytes alloc] init];
    item.key = key;
    item.contentType = contentType;
    item.bytes = bytesData;
    item.name = name;
    [self addFormItem:item];
}

-(void) setItemBytes:(NSData *) bytesData contentType:(NSString *) contentType name:(NSString *) name forKey:(NSString *) key{
    KKLuaHttpDataItemBytes * item = [[KKLuaHttpDataItemBytes alloc] init];
    item.key = key;
    item.contentType = contentType;
    item.bytes = bytesData;
    [self setFormItem:item];
}

-(NSString *) contentType{
    return _contentType;
}

-(NSData *) bytesBody{
    
    NSMutableData * md = [NSMutableData data];
    
    BOOL hasBytesContent = NO;
    
    for(id item in _formItems){
        if([item isKindOfClass:[KKLuaHttpDataItemBytes class]]){
            hasBytesContent = YES;
            break;
        }
    }
    
    if(hasBytesContent){
        
        self.contentType = HTTP_MULTIPART_CONTENT_TYPE;
        
        for(id item in _formItems){
            if([item isKindOfClass:[KKLuaHttpDataItemBytes class]]){
                
                [md appendBytes:(void *)HTTP_MULTIPART_TOKEN_BEGIN length:HTTP_MULTIPART_TOKEN_BEGIN_SIZE];
                [md appendBytes:(void *)"\r\n" length:2];
                [md appendBytes:(void *)"Content-Disposition: form-data; name=\"" length:38];
                [md appendData:[[item key] dataUsingEncoding:NSUTF8StringEncoding]];
                [md appendBytes:(void *)"\"; filename=\"" length:13];
                if([item filename]){
                    [md appendData:[[item filename] dataUsingEncoding:NSUTF8StringEncoding]];
                }
                else{
                    [md appendData:[[item key] dataUsingEncoding:NSUTF8StringEncoding]];
                }
                [md appendBytes:(void *)"\"\r\n" length:3];
                
                [md appendBytes:(void *)"Content-Type: " length:14];
                [md appendData:[[item contentType] dataUsingEncoding:NSUTF8StringEncoding]];
                [md appendBytes:(void *)"\r\n" length:2];
                
                [md appendBytes:(void *)"Content-Transfer-Encoding: binary\r\n\r\n" length:37];
                
                [md appendData:[item bytes]];
                
                [md appendBytes:(void *)"\r\n" length:2];
                
            }
            else if([item isKindOfClass:[KKLuaHttpDataItemValue class]]) {
                
                [md appendBytes:(void *)HTTP_MULTIPART_TOKEN_BEGIN length:HTTP_MULTIPART_TOKEN_BEGIN_SIZE];
                [md appendBytes:(void *)"\r\n" length:2];
                [md appendBytes:(void *)"Content-Disposition: form-data; name=\"" length:38];
                [md appendData:[[item key] dataUsingEncoding:NSUTF8StringEncoding]];
                [md appendBytes:(void *)"\"\r\n\r\n" length:5];
                
                [md appendData:[[(KKLuaHttpDataItemValue *) item value] dataUsingEncoding:NSUTF8StringEncoding]];
                
                [md appendBytes:(void *)"\r\n" length:2];
            }
        }
        
        [md appendBytes:(void *)HTTP_MULTIPART_TOKEN_END length:HTTP_MULTIPART_TOKEN_END_SIZE];
        
    }
    else{
        self.contentType = @"application/x-www-form-urlencoded";
        
        int i = 0;
        
        for(id item in _formItems){
            
            if([item isKindOfClass:[KKLuaHttpDataItemValue class]]) {
                
                if( i != 0) {
                    [md appendBytes:(void *)"&" length:1];
                }
                
                [md appendData:[[item key] dataUsingEncoding:NSUTF8StringEncoding]];
                [md appendBytes:(void *)"=" length:1];
                [md appendData:[[[(KKLuaHttpDataItemValue *) item value] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] dataUsingEncoding:NSUTF8StringEncoding]];
                
                i ++ ;
            }
        }
        
    }
    
    return md;
}

-(BOOL) isMutilpart {
    return [self.contentType isEqualToString:HTTP_MULTIPART_CONTENT_TYPE];
}

@end
