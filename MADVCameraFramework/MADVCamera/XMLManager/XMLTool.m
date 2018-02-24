//
//  XMLTool.m
//  01-xml文件解析
//
//  Created by 哲 肖 on 15/10/29.
//  Copyright (c) 2015年 肖喆. All rights reserved.
//

#import "XMLTool.h"
#import "GDataXMLNode.h"

@implementation XMLTool

+(NSArray *)xmlToolWithXMLData:(NSData *)xmlData
{
    GDataXMLDocument * document = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil];
    
    GDataXMLElement * rootElement = document.rootElement;
    
    
    return [self arrWithElement:rootElement];
}
+ (NSArray *)arrWithElement:(GDataXMLElement *)rootElement
{
    NSMutableArray * groupArr=[[NSMutableArray alloc] init];
    for(GDataXMLElement * tmp in rootElement.children)
    {
        NSDictionary * dict=[self dictWithElement:tmp];
        [groupArr addObject:dict];
    }
    return groupArr;
}


+ (NSDictionary *)dictWithElement:(GDataXMLElement *)element
{
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    NSArray * xmlNodes= element.attributes;
    
    id value = element.stringValue;
    NSString * key = element.name;
    if(xmlNodes.count>0)
    {
        for(GDataXMLNode * node in xmlNodes)
        {
            value=node.stringValue;
            key=node.name;
            [dict setObject:value forKey:key];
        }
    }
    
    if(element.children.count > 0)
    {
        NSMutableArray * array = [NSMutableArray array];
        
        for(GDataXMLElement * childrenElement in element.children)
        {
            NSDictionary * dict = [self dictWithElement:childrenElement];
            [array addObject:dict];
        }
        
        value = array;
        key = element.name;
        
        
        [dict setObject:value forKey:key];
    }
    

    
    return dict;
}

@end
