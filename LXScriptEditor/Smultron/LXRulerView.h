//
//  LXRulerView.h
//  LXScriptEditor
//
//  Created by xinliu on 16-4-18.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LXRulerView : NSRulerView

@end



@interface NSString (count)
- (NSUInteger)numberOfLinesInRange:(NSRange)range includingLastNewLine:(BOOL)includingLastNewLine;
@end