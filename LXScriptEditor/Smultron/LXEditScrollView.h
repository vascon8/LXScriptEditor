//
//  LXEditScrollView.h
//  LXScriptEditor
//
//  Created by xinliu on 16-4-18.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LXEditScrollView : NSScrollView
- (void)invalidateLineNumber;
- (void)viewBoundsDidChange:(NSNotification*)notify;
@end
