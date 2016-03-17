//
//  LanguageTool.h
//  LXScriptEditor
//
//  Created by xinliu on 16-3-14.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LanguageTool : NSObject
+ (NSArray*)analyLanguage:(NSString*)lang path:(NSArray*)pathArr;
@end
