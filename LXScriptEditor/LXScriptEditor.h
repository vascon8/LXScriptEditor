//
//  LXScriptEditor.h
//  LXScriptEditor
//
//  Created by xinliu on 16-1-14.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const LXScriptSyntaxDefinitionName;
extern NSString * const LXScriptAutocomplete;

@interface LXScriptEditor : NSObject

- (NSString *)string;
- (void)setString:(NSString *)aString;
- (void)reloadString;
- (NSTextView *)textView;

//embend
- (void)embedInView:(NSView*)view;

//instance
+ (id)sharedInstance;

//comment
- (void)toggleComment:(id)sender;

//set property
- (void)setObject:(id)object forKey:(id)key;

@end
