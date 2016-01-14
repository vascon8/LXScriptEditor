//
//  EditViewController.m
//  ScriptEditor
//
//  Created by xinliu on 16-1-13.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "EditViewController.h"

#import "MGSFragaria.h"
#import "MGSTextMenuController.h"

@interface EditViewController ()
@property MGSFragaria *fragaria;
@property MGSFragariaTextEditingPrefsViewController *editController;
//@property MGSFragariaPrefsViewController *prefController;
@property MGSTextMenuController *menuController;
@end

@implementation EditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.fragaria = [[MGSFragaria alloc]init];
        [self.fragaria setObject:self forKey:MGSFODelegate];
        
        [self.fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOShowLineNumberGutter];
        //        [self.fragaria setObject:[NSNumber numberWithInteger:20] forKey:MGSFOGutterWidth];
        
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsAutocompleteSuggestAutomatically];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:NO] forKey:MGSFragariaPrefsAutocompleteIncludeStandardWords];
        
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsHighlightCurrentLine];
        [[NSUserDefaults standardUserDefaults]setObject:[NSArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:MGSFragariaPrefsHighlightLineColourWell];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsAutoInsertAClosingBrace];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsAutoInsertAClosingParenthesis];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsAutomaticallyIndentBraces];
        
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsShowMatchingBraces];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsIndentNewLinesAutomatically];
        
        
        //        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithInteger:24] forKey:MGSFragariaPrefsGutterWidth];
        
        self.menuController = self.fragaria.textMenuController;
        
        [self.fragaria embedInView:self.view];
        self.editController = [MGSFragariaPreferences sharedInstance].textEditingPrefsViewController;
        
        NSString *path = @"/Users/xinliu/TestWA/abc/RecordScript/weibo_webView_iOS_12021612.py" ;
        NSString *str =  [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        [self.fragaria setObject:@"python" forKey:MGSFOSyntaxDefinitionName];
        [self.fragaria setString:str];
        [self.fragaria reloadString];
    }
    return self;
}
@end
