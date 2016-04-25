//
//  LXEditScrollView.m
//  LXScriptEditor
//
//  Created by xinliu on 16-4-18.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "LXEditScrollView.h"
#import "LXRulerView.h"

@implementation LXEditScrollView

+ (Class)rulerViewClass
{
    return [LXRulerView class];
}
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setHasVerticalRuler:YES];
        [self setHasHorizontalRuler:NO];
    }
    return self;
}
/// update line numbers
- (void)invalidateLineNumber
// ------------------------------------------------------
{
    [[self verticalRulerView] setNeedsDisplay:YES];
}
- (void)setDocumentView:(NSView *)aView
{
    [super setDocumentView:aView];
    LXRulerView *rulerV = (LXRulerView*)self.verticalRulerView;
    [rulerV setScrollView:self];
    [rulerV setClientView:aView];
}
//- (void)viewBoundsDidChange:(NSNotification *)notify
//{
//    LXRulerView *rulerV = (LXRulerView*)self.verticalRulerView;
//    [rulerV invalidateLineNumberWithRecolor:YES];
//}
@end
