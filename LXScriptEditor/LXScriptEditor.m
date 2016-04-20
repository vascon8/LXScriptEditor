//
//  LXScriptEditor.m
//  LXScriptEditor
//
//  Created by xinliu on 15-1-14.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "LXScriptEditor.h"
#import "MGSTextMenuController.h"
#import "MGSFragaria.h"
#import "MGSFragariaFramework.h"

NSString * const LXScriptSyntaxDefinitionName = @"LXsyntaxDefinition";
NSString * const LXScriptAutocomplete = @"LXAutocompleteSuggest";

@interface LXScriptEditor ()
@property MGSTextMenuController *menuController;
@property MGSFragaria *fragaria;
@end

@implementation LXScriptEditor
#pragma mark - init
- (id)init
{
    if (self = [super init]) {
        self.fragaria = [[MGSFragaria alloc]init];
        [self.fragaria setObject:self forKey:MGSFODelegate];
        [SMLDefaults setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Menlo" size:12.0]] forKey:MGSFragariaPrefsTextFont];
        
        //        [self.fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOShowLineNumberGutter];
        //        [self.fragaria setObject:[NSNumber numberWithInteger:20] forKey:MGSFOGutterWidth];
        
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:NO] forKey:MGSFragariaPrefsAutocompleteSuggestAutomatically];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:NO] forKey:MGSFragariaPrefsAutocompleteIncludeStandardWords];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsColourAutocomplete];
        
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:NO] forKey:MGSFragariaPrefsHighlightCurrentLine];
        [[NSUserDefaults standardUserDefaults]setObject:[NSArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:MGSFragariaPrefsHighlightLineColourWell];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsAutoInsertAClosingBrace];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsAutoInsertAClosingParenthesis];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsAutomaticallyIndentBraces];
        
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsShowMatchingBraces];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:MGSFragariaPrefsIndentNewLinesAutomatically];
        
        
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithInteger:26] forKey:MGSFragariaPrefsGutterWidth];
        
        self.menuController = self.fragaria.textMenuController;
    }
    return self;
}
+ (id)sharedInstance
{
    LXScriptEditor *editor = [[LXScriptEditor alloc]init];
    return editor;
}
- (NSTextView *)textView
{
    return self.fragaria.textView;
}
- (void)setString:(NSString *)aString
{
    [self.fragaria setString:aString];
}
- (NSString *)string
{
    return self.fragaria.string;
}
- (void)reloadString
{
    [self.fragaria reloadString];
}
#pragma mark - set property
- (void)setObject:(id)object forKey:(id)key
{
    [self.fragaria setObject:object forKey:key];
}
#pragma mark - embend
- (void)embedInView:(NSView *)view
{
    [self.fragaria embedInView:view];
}
#pragma mark - comment
- (void)toggleComment:(id)sender
{
    [[self menuController] commentOrUncommentAction:sender];
}
@end
