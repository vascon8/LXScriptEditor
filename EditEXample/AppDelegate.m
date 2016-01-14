//
//  AppDelegate.m
//  EditEXample
//
//  Created by xinliu on 16-1-14.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.editController = [[EditViewController alloc]initWithNibName:@"EditView" bundle:nil];
    [self.editController.view setFrame:self.contentView.bounds];
    
    [self.contentView addSubview:self.editController.view];
}

@end
