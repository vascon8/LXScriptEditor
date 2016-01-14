//
//  AppDelegate.h
//  EditEXample
//
//  Created by xinliu on 16-1-14.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EditViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property  EditViewController *editController;

@property (assign) IBOutlet NSView *contentView;
@end
