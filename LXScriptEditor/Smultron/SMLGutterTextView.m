/*
 
 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria
 
 Based on:
 
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "MGSFragaria.h"
#import "MGSFragariaFramework.h"
#import "SMLTextView.h"
#import "LXTypeSetter.h"
//
//@interface SMLGutterTextView ()
//@property  NSTimer *draggingTimer;
//@end
//
//@implementation SMLGutterTextView

//@synthesize fileName, breakpointLines;

//#pragma mark -
//- (id)initWithFrame:(NSRect)frame
//{
//	if ((self = [super initWithFrame:frame])) {
//        
//        [self.textContainer replaceLayoutManager:[LXGutterLayoutManager new]];
//        
//        imgBreakpoint0 = [MGSFragaria imageNamed:@"editor-breakpoint-0.png"];
//        [imgBreakpoint0 setFlipped:YES];
//
//        imgBreakpoint1 = [MGSFragaria imageNamed:@"editor-breakpoint-1.png"];
//        [imgBreakpoint1 setFlipped:YES];
//
//        imgBreakpoint2 = [MGSFragaria imageNamed:@"editor-breakpoint-2.png"];
//        [imgBreakpoint2 setFlipped:YES];
//
//
//		[self setContinuousSpellCheckingEnabled:NO];
//		[self setAllowsUndo:NO];
//		[self setAllowsDocumentBackgroundColorChange:NO];
//		[self setRichText:NO];
//		[self setUsesFindPanel:NO];
//		[self setUsesFontPanel:NO];
//		[self setAlignment:NSRightTextAlignment];
//		[self setEditable:NO];
//		[self setSelectable:NO];
//        
//		[[self textContainer] setContainerSize:NSMakeSize([[SMLDefaults valueForKey:MGSFragariaPrefsGutterWidth] integerValue], FLT_MAX)];
//        
//		[self setVerticallyResizable:YES];
//		[self setHorizontallyResizable:YES];
//		[self setAutoresizingMask:NSViewHeightSizable];
//        
//        NSFont *font = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]];
//		[self setFont:font];
//        
//		[self setTextColor:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsGutterTextColourWell]]];
//		[self setInsertionPointColor:[NSColor textColor]];
//
//		[self setBackgroundColor:[NSColor colorWithCalibratedWhite:0.94f alpha:1.0f]];
//
//		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
//		[defaultsController addObserver:self forKeyPath:@"values.FragariaTextFont" options:NSKeyValueObservingOptionNew context:@"TextFontChanged"];
//        
//        // TODO:
//        //        if (NO) {
//        /* vlidholt/fragaria adopts this approach to try and improve line number accuracy.
//         
//         Not sure if this the answer to the EOF line number alignment issue.
//         
//         These settings would need to respond to changes in font / size and be replicated in the SMLTextView.
//         
//         Think about it.
//         
//         The issue may be more to do with positioning the gutter scrcoll view.
//         Does line wrapping make the issue worse?
//         
//         */
//        NSMutableParagraphStyle * style = [self.defaultParagraphStyle mutableCopy];
//        [style setAlignment:NSRightTextAlignment];
//        
////        CGFloat fontH = self.font.pointSize;
////        CGFloat H = textView.lineSpacing + fontH;
//
////        [style setLineHeightMultiple:4.0];
////        [style setMinimumLineHeight:11.0];
////        [style setMaximumLineHeight:100.0];
//        //            [style setMinimumLineHeight:11.0];
//        //            [style setMaximumLineHeight:11.0];
//        
//        [self setDefaultParagraphStyle:style];
//        
////        NSLog(@"==h:%f,spac:%f",[self.layoutManager defaultLineHeightForFont:self.font],self.lineSpacing);
//        
////        [self  setTypingAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
////                                     [self defaultParagraphStyle], NSParagraphStyleAttributeName,
////                                     nil]];
//        //        }
//	}
//	return self;
//}
//- (CGFloat)lineSpacing
//{
//    SMLTextView *textView = [[MGSFragaria currentInstance] objectForKey:ro_MGSFOTextView];
////    self.lineSpacing = textView.lineSpacing;
//    return textView.lineSpacing;
//}
//#pragma mark -
//#pragma mark KVO
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//	if ([(__bridge NSString *)context isEqualToString:@"TextFontChanged"]) {
//        NSFont *font = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]];
//
////        CGFloat W = (font.pointSize + 2.0 ) * 2.0;
////        [[self textContainer] setContainerSize:NSMakeSize(W, FLT_MAX)];
//        
//		[self setFont:font];
//	} else {
//		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//	}
//}
//
//#pragma mark -
//#pragma mark Drawing
//
//- (void)drawRect:(NSRect)rect
//{
//	[super drawRect:rect];
//	
//	NSRect bounds = [self bounds]; 
//	if ([self needsToDrawRect:NSMakeRect(bounds.size.width - 1, 0, 1, bounds.size.height)] == YES) {
//		[[NSColor lightGrayColor] set];
//		NSBezierPath *dottedLine = [NSBezierPath bezierPathWithRect:NSMakeRect(bounds.size.width, 0, 0, bounds.size.height)];
//		CGFloat dash[2];
//		dash[0] = 1.0f;
//		dash[1] = 2.0f;
//		[dottedLine setLineDash:dash count:2 phase:1.0f];
//		[dottedLine stroke];
//	}
//    
//    // draw breakpoints
//    if (self.breakpointLines)
//    {
//        for (NSNumber* lineNumber in self.breakpointLines)
//        {
//            int line = [lineNumber intValue];
//            NSDrawThreePartImage(NSMakeRect(2, line * 13 - 12, bounds.size.width -4, 12), imgBreakpoint0, imgBreakpoint1, imgBreakpoint2, NO, NSCompositeSourceOver, 1, NO);
//        }
//    }
//}
//
///*
// 
// - mouseDown:
// 
// */
//- (void)mouseDown:(NSEvent *)theEvent
//{
//    NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//    
//    NSLayoutManager* lm = [self layoutManager];
//    NSUInteger glyphIdx = [lm glyphIndexForPoint:curPoint inTextContainer:self.textContainer];
//    
//    NSUInteger charIdx = [lm characterIndexForGlyphAtIndex:glyphIdx];
//    
//    NSString* text = [self string];
//    NSRange lineRange = [text lineRangeForRange:NSMakeRange(charIdx, 1)];
//    NSString* substring = [text substringWithRange:lineRange];
//    
//    int lineNum = [substring intValue];
//    
//    id delegate = [[MGSFragaria currentInstance] objectForKey:MGSFOBreakpointDelegate];
//    if (delegate && [delegate respondsToSelector:@selector(toggleBreakpointForFile:onLine:)])
//    {
//        [delegate toggleBreakpointForFile:self.fileName onLine:lineNum];
//    }
//    
//    SMLLineNumbers* lineNumbers = [[MGSFragaria currentInstance] objectForKey:ro_MGSFOLineNumbers];
//    
//    [lineNumbers updateLineNumbersCheckWidth:NO recolour:NO];
//    
//    [self setNeedsDisplay:YES];
//    
//    //for select line
//    // get start point
//    NSPoint point = [[self window] convertRectToScreen:NSMakeRect([theEvent locationInWindow].x,
//                                                                  [theEvent locationInWindow].y, 0, 0)].origin;
//    NSUInteger index = [self characterIndexForPoint:point];
//    
//    [self selectLines:nil];  // for single click event
//    
//    // repeat while dragging
//    [self setDraggingTimer:[NSTimer scheduledTimerWithTimeInterval:0.05
//                                                            target:self
//                                                          selector:@selector(selectLines:)
//                                                          userInfo:@(index)
//                                                           repeats:YES]];
//}
//- (void)mouseUp:(NSEvent *)theEvent
//// ------------------------------------------------------
//{
//    [[self draggingTimer] invalidate];
//    [self setDraggingTimer:nil];
//}
//- (void)setAttributeStr:(NSAttributedString*)attStr
//{
//    if(!attStr) return;
//    
//    [[self textStorage]setAttributedString:attStr];
//}
///*
//- (void)drawViewBackgroundInRect:(NSRect)rect
//{
//    [super drawViewBackgroundInRect:rect];
//    
//    //NSPoint containerOrigin = [self textContainerOrigin];
//    NSLayoutManager* layoutManager = [self layoutManager];
//    
//    NSUInteger glyphIndex = [layoutManager glyphIndexForCharacterAtIndex:8];
//    NSLog(@"glyphIndex: %d", (int)glyphIndex);
//    
//    //[layoutManager ch]
//    
//    NSPoint glyphLocation = [layoutManager locationForGlyphAtIndex:glyphIndex];
//    NSLog(@"glyphLocation: %f,%f", glyphLocation.x, glyphLocation.y);
//    
//    NSRect bounds = [self bounds];
//    
//    NSLog(@"bounds: %f,%f,%f,%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
//    
//    NSLog(@"img0: %@ img1: %@ img2: %@", imgBreakpoint0, imgBreakpoint1, imgBreakpoint2);
//    
//    //NSDrawThreePartImage(NSMakeRect(2, 110, bounds.size.width-4, 12), imgBreakpoint0, imgBreakpoint1, imgBreakpoint2, NO, NSCompositeSourceOver, 1, NO);
//    
//    [imgBreakpoint0 drawInRect:NSMakeRect(2, 110, 4, 12) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//    [imgBreakpoint2 drawInRect:NSMakeRect(bounds.size.width-11, 110, 8, 12) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//}*/
//
///*
// 
// - isOpaque
// 
// */
//- (BOOL)isOpaque
//{
//	return YES;
//}
//#pragma mark - select line
//- (void)selectLines:(NSTimer *)timer
//// ------------------------------------------------------
//{
//    if(!timer) return;
//    
//    NSTextView *textView = [[MGSFragaria currentInstance] objectForKey:ro_MGSFOTextView];
//    NSPoint point = [NSEvent mouseLocation];  // screen based point
//    
//    // scroll text view if needed
//    CGFloat y = [self convertPoint:[[self window] convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin
//                          fromView:nil].y;
//    if (y < 0) {
//        [textView scrollLineUp:nil];
//    } else if (y > NSHeight([self bounds])) {
//        [textView scrollLineDown:nil];
//    }
//    
//    // select lines
//    NSUInteger currentIndex = [textView characterIndexForPoint:point];
////    NSUInteger clickedIndex = timer ? [[timer userInfo] unsignedIntegerValue] : currentIndex;
//     NSUInteger clickedIndex = currentIndex;
//    NSRange currentLineRange = [[textView string] lineRangeForRange:NSMakeRange(currentIndex, 0)];
//    NSRange clickedLineRange = [[textView string] lineRangeForRange:NSMakeRange(clickedIndex, 0)];
//    NSRange range = NSUnionRange(currentLineRange, clickedLineRange);
//    
////    NSLog(@"==curr:%ld,click:%ld,currR:%@,clickR:%@,Range:%@",currentIndex,clickedIndex,NSStringFromRange(currentLineRange),NSStringFromRange(clickedLineRange),NSStringFromRange(range));
////    NSLog(@"==timer:%@",timer);
//    
//    // with Shift key
//    if ([NSEvent modifierFlags] & NSShiftKeyMask) {
//        NSRange selectedRange = [textView selectedRange];
//        if (NSLocationInRange(currentIndex, selectedRange)) {  // reduce
//            BOOL inUpperSection = (currentIndex - selectedRange.location) < selectedRange.length / 2;
//            if (inUpperSection) {  // clicked upper half section of selected range
//                range = NSMakeRange(currentIndex, NSMaxRange(selectedRange) - currentIndex);
//                
//            } else {
//                range = selectedRange;
//                range.length -= NSMaxRange(selectedRange) - NSMaxRange(currentLineRange);
//            }
//            
//        } else {  // expand
//            range = NSUnionRange(range, selectedRange);
//        }
//    }
////    NSLog(@"==range:%@",NSStringFromRange(range));
//    [textView setSelectedRange:range];
//}

//@end




@implementation LXGutterLayoutManager
//- (id)init{
//    if (self = [super init]) {
//        [self setTypesetter:[LXTypeSetter new]];
//    }
//    return self;
//}
//- (void)setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect
//{
//    CGFloat lineSpacing = [(SMLGutterTextView*)[self firstTextView] lineSpacing];
//    CGFloat Y = usedRect.origin.y - lineSpacing/2.0;
//    usedRect.origin.y = Y;
//    
////    NSLog(@"==usedR:%@,spac:%f",NSStringFromRect(usedRect),lineSpacing);
//    
//    [super setLineFragmentRect:fragmentRect forGlyphRange:glyphRange usedRect:usedRect];
//}
//
//- (void)setExtraLineFragmentRect:(NSRect)fragmentRect usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)container
//{
//    CGFloat lineSpacing = [(SMLGutterTextView*)[self firstTextView] lineSpacing];
//    CGFloat Y = usedRect.origin.y - lineSpacing/2.0;
//    usedRect.origin.y = Y;
//    
//    [super setExtraLineFragmentRect:fragmentRect usedRect:usedRect textContainer:container];
//}

@end
