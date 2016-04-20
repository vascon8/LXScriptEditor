//
//  EditViewController.m
//  ScriptEditor
//
//  Created by xinliu on 16-1-13.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "EditViewController.h"

#import "LXScriptEditor.h"
//#import "MGSTextMenuController.h"

@interface EditViewController ()
@property LXScriptEditor *editor;
@end

@implementation EditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.editor = [[LXScriptEditor alloc]init];
        
        [self.editor embedInView:self.view];
        
        NSString *path = @"/Users/xinliu/TestWA/ni好喔9个99/RecordScript/优酷视频_Android_11082241.py" ;
        NSString *str =  [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        [self.editor setObject:@"Python" forKey:LXScriptSyntaxDefinitionName];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:LXScriptAutocomplete];
        
        [self.editor setString:str];
        [self.editor reloadString];
    }
    return self;
}
@end
