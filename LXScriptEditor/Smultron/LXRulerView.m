//
//  LXRulerView.m
//  LXScriptEditor
//
//  Created by xinliu on 16-4-18.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "LXRulerView.h"
#import "MGSFragariaFramework.h"

static const NSUInteger kMinNumberOfDigits = 3;
static const CGFloat kMinVerticalThickness = 32.0;
static const CGFloat kMinHorizontalThickness = 20.0;
static const CGFloat kLineNumberPadding = 4.0;
static const CGFloat kFontSizeFactor = 0.9;

@interface LXRulerView ()
@property NSTimer *draggingTimer;
@property (nonatomic) BOOL needsRecountTotalNumberOfLines;
@property (nonatomic) NSUInteger totalNumberOfLines;
@end



@implementation LXRulerView
static CGFontRef LineNumberFont;
static CGFontRef BoldLineNumberFont;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFont *dFont = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]];
        CGFloat size = dFont.pointSize;
        if (size > 12.0) {
            size = 12.0;
        }
        
        NSFont *font = [NSFont fontWithName:@"Menlo" size:size-1];
        NSFont *boldF = [NSFont fontWithName:@"Menlo" size:size];
        NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:boldF toHaveTrait:NSBoldFontMask];
        
        LineNumberFont = CGFontCreateWithFontName((CFStringRef)[font fontName]);
        BoldLineNumberFont = CGFontCreateWithFontName((CFStringRef)[boldFont fontName]);
    });
}


// ------------------------------------------------------
/// initialize instance
- (id)initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation
{
    self = [super initWithScrollView:scrollView orientation:orientation];
    if (self) {
        [self setClientView:[scrollView documentView]];
//        NSLog(@"==client:%@",self.clientView);
    }
    return self;
}

// ------------------------------------------------------
/// setup initial size
- (void)viewDidMoveToSuperview
// ------------------------------------------------------
{
    [super viewDidMoveToSuperview];
    
    CGFloat thickness = [self orientation] == NSHorizontalRuler ? kMinHorizontalThickness : kMinVerticalThickness;
    [self setRuleThickness:thickness];
}


// ------------------------------------------------------
/// draw background
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
//    [self setBackgroundColor:[NSColor colorWithCalibratedWhite:0.94f alpha:1.0f]];]
    
//    NSLog(@"==ruler rect:%@",NSStringFromRect(dirtyRect));
    
    NSColor *counterColor = [NSColor whiteColor];
    NSColor *textColor = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsGutterTextColourWell]];
    
    // fill background
    [[counterColor colorWithAlphaComponent:0.08] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw frame border (1px)
    [[textColor colorWithAlphaComponent:0.3] set];
    switch ([self orientation]) {
        case NSVerticalRuler:
            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMaxY(dirtyRect))
                                      toPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMinY(dirtyRect))];
            break;
            
        case NSHorizontalRuler:
            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), NSMaxY(dirtyRect) - 0.5)
                                      toPoint:NSMakePoint(NSMaxX(dirtyRect), NSMaxY(dirtyRect) - 0.5)];
            break;
    }
    
    [self drawHashMarksAndLabelsInRect:dirtyRect];
}


// ------------------------------------------------------
/// draw line numbers
- (void)drawHashMarksAndLabelsInRect1:(NSRect)rect
// ------------------------------------------------------
{
    NSString *string = [[self textView] string];
    NSUInteger length = [string length];
    
    if (length == 0) { return; }
    
    NSTextView *textView = [self textView];
    NSLayoutManager *layoutManager = [textView layoutManager];
    NSColor *textColor = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsGutterTextColourWell]];
    
    CGFloat scale = [textView convertSize:NSMakeSize(1.0, 1.0) toView:nil].width;
    
    // set graphics context
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    // setup font
    CGFloat masterFontSize = scale * [[[self textView] font] pointSize];
    CGFloat fontSize = MIN(round(kFontSizeFactor * masterFontSize), masterFontSize);
    CTFontRef font = CTFontCreateWithGraphicsFont(LineNumberFont, fontSize, nil, nil);
    CGFloat ascent = CTFontGetAscent(font);
    
    CGContextSetFont(context, LineNumberFont);
    CGContextSetFontSize(context, fontSize);
    CGContextSetFillColorWithColor(context, [textColor CGColor]);
    
    // prepare glyphs
    CGGlyph wrappedMarkGlyph;
    const unichar dash = '-';
    CTFontGetGlyphsForCharacters(font, &dash, &wrappedMarkGlyph, 1);
    
    CGGlyph digitGlyphs[10];
    const unichar numbers[10] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
    CTFontGetGlyphsForCharacters(font, numbers, digitGlyphs, 10);
    
    // calc character width as monospaced font
    CGSize advance;
    CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal, &digitGlyphs[8], &advance, 1);  // use '8' to get width
    CGFloat charWidth = advance.width;
    CFRelease(font);
    
    // prepare frame width
    CGFloat ruleThickness = [self ruleThickness];
    
    BOOL isVerticalText = [self orientation] == NSHorizontalRuler;
    CGFloat tickLength = ceil(fontSize / 3);
    
    // adjust text drawing coordinate
    NSPoint relativePoint = [self convertPoint:NSZeroPoint fromView:textView];
    NSPoint inset = [textView textContainerOrigin];
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0, -1.0);  // flip
    if (isVerticalText) {
        transform = CGAffineTransformTranslate(transform, round(relativePoint.x - inset.y - ascent / 2), -ruleThickness);
    } else {
        transform = CGAffineTransformTranslate(transform, -kLineNumberPadding, -relativePoint.y - inset.y - ascent);
    }
    CGContextSetTextMatrix(context, transform);
    
    // add enough buffer to avoid broken drawing on Mountain Lion (10.8) with scroller (2015-07)
    NSRect visibleRect = [[self scrollView] documentVisibleRect];
    visibleRect.size.height += fontSize;
    
    // get multiple selections
    NSMutableArray *selectedLineRanges = [NSMutableArray arrayWithCapacity:[[textView selectedRanges] count]];
    for (NSValue *rangeValue in [textView selectedRanges]) {
        NSRange selectedLineRange = [string lineRangeForRange:[rangeValue rangeValue]];
        [selectedLineRanges addObject:[NSValue valueWithRange:selectedLineRange]];
    }
    
    // draw line number block
    CGGlyph *digitGlyphsPtr = digitGlyphs;
    void (^draw_number)(NSUInteger, CGFloat, BOOL) = ^(NSUInteger lineNumber, CGFloat y, BOOL isBold)
    {
        NSUInteger digit = numberOfDigits((int)lineNumber);
        
        // calculate base position
        CGPoint position;
        if (isVerticalText) {
            position = CGPointMake(ceil(y + charWidth * digit / 2), 2 * tickLength);
        } else {
            position = CGPointMake(ruleThickness, y);
        }
        
        // get glyphs and positions
        CGGlyph glyphs[digit];
        CGPoint positions[digit];
        for (NSUInteger i = 0; i < digit; i++) {
            position.x -= charWidth;
            
            positions[i] = position;
            glyphs[i] = digitGlyphsPtr[numberAt((int)i, (int)lineNumber)];
        }
        
        if (isBold) {
            CGContextSetFont(context, BoldLineNumberFont);
        }
        
        // draw
        CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);
        
        if (isBold) {
            // back to the regular font
            CGContextSetFont(context, LineNumberFont);
        }
    };
    
    // draw ticks block for vertical text
    void (^draw_tick)(CGFloat) = ^(CGFloat y)
    {
        CGFloat x = round(y) + 0.5;
        
        CGMutablePathRef tick = CGPathCreateMutable();
        CGPathMoveToPoint(tick, &transform, x, 0);
        CGPathAddLineToPoint(tick, &transform, x, tickLength);
        CGContextAddPath(context, tick);
        CFRelease(tick);
    };
    
    // get glyph range of which line number should be drawn
    NSRange glyphRangeToDraw = [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:visibleRect
                                                                               inTextContainer:[textView textContainer]];
    
    // counters
    NSUInteger glyphCount = glyphRangeToDraw.location;
    NSUInteger lineNumber = 1;
    NSUInteger lastLineNumber = 0;
    
    // count lines until visible
    lineNumber = [string numberOfLinesInRange:NSMakeRange(0, [layoutManager characterIndexForGlyphAtIndex:glyphRangeToDraw.location])
                         includingLastNewLine:YES] ?: 1;  // start with 1
    
    // draw visible line numbers
    for (NSUInteger glyphIndex = glyphRangeToDraw.location; glyphIndex < NSMaxRange(glyphRangeToDraw); lineNumber++) { // count "real" lines
        NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        NSRange lineRange = [string lineRangeForRange:NSMakeRange(charIndex, 0)];
        glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL]);
        
        // check if line is selected
        BOOL isSelected = NO;
        for (NSValue *selectedLineValue in selectedLineRanges) {
            NSRange selectedRange = [selectedLineValue rangeValue];
            
            if (NSLocationInRange(lineRange.location, selectedRange) &&
                (isVerticalText && ((lineRange.location == selectedRange.location) ||
                                    (NSMaxRange(lineRange) == NSMaxRange(selectedRange)))))
            {
                isSelected = YES;
                break;
            }
        }
        
        while (glyphCount < glyphIndex) { // handle wrapped lines
            NSRange range;
            NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range withoutAdditionalLayout:YES];
            BOOL isWrappedLine = (lastLineNumber == lineNumber);
            lastLineNumber = lineNumber;
            glyphCount = NSMaxRange(range);
            
            if (isVerticalText && isWrappedLine) { continue; }
            
            CGFloat y = scale * -NSMinY(lineRect);
            
            if (isWrappedLine) {
                CGPoint position = CGPointMake(ruleThickness - charWidth, y);
                CGContextShowGlyphsAtPositions(context, &wrappedMarkGlyph, &position, 1);  // draw wrapped mark
                
            } else {  // new line
                if (isVerticalText) {
                    draw_tick(y);
                }
                if (!isVerticalText || lineNumber % 5 == 0 || lineNumber == 1 || isSelected ||
                    (NSMaxRange(lineRange) == length && ![layoutManager extraLineFragmentTextContainer]))  // last line for vertical text
                {
                    draw_number(lineNumber, y, isSelected);
                }
            }
        }
    }
    
    // draw the last "extra" line number
    if ([layoutManager extraLineFragmentTextContainer]) {
        NSRect lineRect = [layoutManager extraLineFragmentUsedRect];
        NSRange lastSelectedRange = [[selectedLineRanges lastObject] rangeValue];
        BOOL isSelected = (lastSelectedRange.length == 0) && (length == NSMaxRange(lastSelectedRange));
        CGFloat y = scale * -NSMinY(lineRect);
        
        if (isVerticalText) {
            draw_tick(y);
        }
        draw_number(lineNumber, y, isSelected);
    }
    
    // draw vertical text tics
    if (isVerticalText) {
        CGContextSetStrokeColorWithColor(context, [[textColor colorWithAlphaComponent:0.6] CGColor]);
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
    
    // adjust thickness
    CGFloat requiredThickness;
    if (isVerticalText) {
        requiredThickness = MAX(fontSize + 2.5 * tickLength, kMinHorizontalThickness);
        
    } else {
        if ([self needsRecountTotalNumberOfLines]) {
            // -> count only if really needed since the line counting is high workload, especially by large document
            [self setTotalNumberOfLines:[string numberOfLinesInRange:NSMakeRange(0, length) includingLastNewLine:YES]];
            [self setNeedsRecountTotalNumberOfLines:NO];
        }
        
        // use the line number of whole string, namely the possible largest line number
        // -> The view width depends on the number of digits of the total line numbers.
        //    It's quite dengerous to change width of line number view on scrolling dynamically.
        NSUInteger digits = MAX(numberOfDigits((int)[self totalNumberOfLines]), kMinNumberOfDigits);
        requiredThickness = MAX(digits * charWidth + 3 * kLineNumberPadding, kMinVerticalThickness);
    }
    [self setRuleThickness:ceil(requiredThickness)];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)rect
// ------------------------------------------------------
{
    NSString *string = [[self textView] string];
    
//    NSLog(@"==ruler string:%@,textV:%@",string,[self textView]);
    
    if ([string length] == 0) { return; }
    
    NSLayoutManager *layoutManager = [[self textView] layoutManager];
    NSColor *textColor = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsGutterTextColourWell]];
    
    // set graphics context
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    // setup font
    CGFloat masterFontSize = [[[[self textView] textStorage] font] pointSize];
    CGFloat fontSize = MIN(round(kFontSizeFactor * masterFontSize), masterFontSize);
    CTFontRef font = CTFontCreateWithGraphicsFont(LineNumberFont, fontSize, nil, nil);
    
    CGFloat tickLength = ceil(fontSize / 3);
    
    CGContextSetFont(context, LineNumberFont);
    CGContextSetFontSize(context, fontSize);
    CGContextSetFillColorWithColor(context, [textColor CGColor]);
    
    // prepare glyphs
    CGGlyph wrappedMarkGlyph;
    const unichar dash = '~';
    CTFontGetGlyphsForCharacters(font, &dash, &wrappedMarkGlyph, 1);
    
    CGGlyph digitGlyphs[10];
    const unichar numbers[10] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
    CTFontGetGlyphsForCharacters(font, numbers, digitGlyphs, 10);
    
    // calc character width as monospaced font
    CGSize advance;
    CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal, &digitGlyphs[8], &advance, 1);  // use '8' to get width
    CGFloat charWidth = advance.width;
    
    // prepare frame width
    CGFloat ruleThickness = [self ruleThickness];
    
    // adjust text drawing coordinate
    NSPoint relativePoint = [self convertPoint:NSZeroPoint fromView:[self textView]];
    NSPoint inset = [[self textView] textContainerOrigin];
    CGFloat diff = masterFontSize - fontSize;
    CGFloat ascent = CTFontGetAscent(font);
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1.0, -1.0);  // flip
    transform = CGAffineTransformTranslate(transform, -kLineNumberPadding, -relativePoint.y - inset.y - diff - ascent);
    CGContextSetTextMatrix(context, transform);
    CFRelease(font);
    
    // add enough buffer to avoid broken drawing on Mountain Lion (10.8) with scroller (2015-07)
    NSRect visibleRect = [[self scrollView] documentVisibleRect];
    visibleRect.size.height += fontSize;
    
    // get glyph range which line number should be drawn
    NSRange visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:visibleRect
                                                         inTextContainer:[[self textView] textContainer]];
//    NSRange typeR = [layoutManager.typesetter paragraphGlyphRange];
//    NSLog(@"visibleGlyphRange:%@,rect:%@,typesetterR:%@",NSStringFromRange(visibleGlyphRange),NSStringFromRect(visibleRect),NSStringFromRange(typeR));
    BOOL isVerticalText = [self orientation] == NSHorizontalRuler;
    NSUInteger tailGlyphIndex = [layoutManager glyphIndexForCharacterAtIndex:[string length]];
    NSRange selectedLineRange = [string lineRangeForRange:[[self textView] selectedRange]];
    
    // draw line number block
    CGGlyph *digitGlyphsPtr = digitGlyphs;
    void (^draw_number)(NSUInteger, NSUInteger, CGFloat, BOOL, BOOL) = ^(NSUInteger lineNumber, NSUInteger lastLineNumber, CGFloat y, BOOL drawsNumber, BOOL isBold)
    {
        if (isVerticalText) {
            // translate y position to horizontal axis
            y += relativePoint.x - masterFontSize / 2 - inset.y;
            
            // draw ticks on vertical text
            CGFloat x = round(y) - 0.5;
            CGContextMoveToPoint(context, x, ruleThickness);
            CGContextAddLineToPoint(context, x, ruleThickness - tickLength);
        }
        
        // draw line number
        if (drawsNumber) {
            NSUInteger digit = numberOfDigits((int)lineNumber);
            
            // calculate base position
            CGPoint position;
            if (isVerticalText) {
                position = CGPointMake(ceil(y + charWidth * (digit + 1) / 2), ruleThickness + tickLength - 2);
            } else {
                position = CGPointMake(ruleThickness, y);
            }
            
            // get glyphs and positions
            CGGlyph glyphs[digit];
            CGPoint positions[digit];
            for (NSUInteger i = 0; i < digit; i++) {
                position.x -= charWidth;
                
                positions[i] = position;
                glyphs[i] = digitGlyphsPtr[numberAt((int)i, (int)lineNumber)];
            }

            CGContextSetAlpha(context, 1.0);
            if (isBold) {
                CGContextSetFillColorWithColor(context, [NSColor blackColor].CGColor);
                CGContextSetFont(context, BoldLineNumberFont);
            }
            
            CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);  // draw line number
            
            if (isBold) {
                // back to the regular font
                CGContextSetFont(context, LineNumberFont);
                CGContextSetFillColorWithColor(context, [textColor CGColor]);
            }
        }
    };
    
    // counters
    NSUInteger glyphCount = visibleGlyphRange.location;
    NSUInteger lineNumber = 1;
    NSUInteger lastLineNumber = 0;
    
    // count lines until visible
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\n" options:0 error:nil];
    lineNumber += [regex numberOfMatchesInString:string options:0
                                           range:NSMakeRange(0, [layoutManager characterIndexForGlyphAtIndex:visibleGlyphRange.location])];
    
    // draw visible line numbers
    for (NSUInteger glyphIndex = visibleGlyphRange.location; glyphIndex < NSMaxRange(visibleGlyphRange); lineNumber++) { // count "real" lines
        NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        NSRange lineRange = [string lineRangeForRange:NSMakeRange(charIndex, 0)];
        glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL]);
        BOOL isSelected = NSLocationInRange(lineRange.location, selectedLineRange);
        
        while (glyphCount < glyphIndex) { // handle wrapped lines
            NSRange range;
            NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range withoutAdditionalLayout:YES];
            CGFloat y = -NSMinY(lineRect);
            //adjust line spacing
            y -= [(SMLTextView*)[self textView] lineSpacing]/2.0;
            
            if (lastLineNumber == lineNumber) {  // wrapped line
                if (!isVerticalText) {
                    CGPoint position = CGPointMake(ruleThickness - charWidth, y);
                    if (isSelected) {
                        CGContextSetFillColorWithColor(context, [NSColor blackColor].CGColor);
                        CGContextSetFont(context, BoldLineNumberFont);
                    }
                    CGContextShowGlyphsAtPositions(context, &wrappedMarkGlyph, &position, 1);  // draw wrapped mark
                    if (isSelected) {
                        CGContextSetFont(context, LineNumberFont);
                        CGContextSetFillColorWithColor(context, [textColor CGColor]);
                    }
                }
                
            } else {  // new line
                BOOL drawsNumber = (isSelected || !isVerticalText || lineNumber % 5 == 0 || lineNumber == 1);
                draw_number(lineNumber, lastLineNumber, y, drawsNumber, isSelected);
            }
            
            glyphCount = NSMaxRange(range);
            
            // draw last line number on vertical text anyway
            if (isVerticalText &&  // vertical text
                lastLineNumber != lineNumber &&  // new line
                isVerticalText && lineNumber != 1 && lineNumber % 5 != 0 &&  // not yet drawn
                tailGlyphIndex == glyphIndex &&  // last line
                ![layoutManager extraLineFragmentTextContainer])  // no extra number
            {
                draw_number(lineNumber, lastLineNumber, y, YES, isSelected);
            }
            
            lastLineNumber = lineNumber;
        }
    }
    
    // draw the last "extra" line number
    if ([layoutManager extraLineFragmentTextContainer]) {
        NSRect lineRect = [layoutManager extraLineFragmentUsedRect];
        BOOL isSelected = (selectedLineRange.length == 0) && ([string length] == NSMaxRange(selectedLineRange));
        CGFloat y = -NSMinY(lineRect);
        
        draw_number(lineNumber, lastLineNumber, y, YES, isSelected);
    }
    
    // draw vertical text tics
    if (isVerticalText) {
        CGContextSetStrokeColorWithColor(context, [[textColor colorWithAlphaComponent:0.6] CGColor]);
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
    
    // adjust thickness
    CGFloat requiredThickness;
    if (isVerticalText) {
        requiredThickness = MAX(fontSize + tickLength + 2 * kLineNumberPadding, kMinHorizontalThickness);
    } else {
        // count rest invisible lines
        // -> The view width depends on the number of digits of the total line numbers.
        //    As it's quite dengerous to change width of line number view on scrolling dynamically.
        NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:NSMaxRange(visibleGlyphRange)];
        if ([string length] > charIndex) {
            lineNumber += [regex numberOfMatchesInString:string options:0
                                                   range:NSMakeRange(charIndex,
                                                                     [string length] - charIndex)];
            // -> This number can be one greater than the true line number. But it's not a problem.
        }
        
        NSUInteger length = MAX(numberOfDigits((int)lineNumber), kMinNumberOfDigits);
        requiredThickness = MAX(length * charWidth + 3 * kLineNumberPadding, kMinVerticalThickness);
    }
    [self setRuleThickness:ceil(requiredThickness)];
}
- (void)invalidateLineNumberWithRecolor:(BOOL)recolor
{
//    [self needsDisplay];
    if (recolor) {
        [(SMLTextView*)[self textView] pageRecolor];
    }
}

// ------------------------------------------------------
/// make background transparent
- (BOOL)isOpaque
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
/// remove extra thickness
- (CGFloat)requiredThickness
// ------------------------------------------------------
{
    if ([self orientation] == NSHorizontalRuler) {
        return [self ruleThickness];
    }
    return MAX(kMinVerticalThickness, [self ruleThickness]);
}


// ------------------------------------------------------
/// start selecting correspondent lines in text view with drag / click event
- (void)mouseDown:(NSEvent *)theEvent
// ------------------------------------------------------
{
    // get start point
    NSPoint point = [[self window] convertRectToScreen:NSMakeRect([theEvent locationInWindow].x,
                                                                  [theEvent locationInWindow].y, 0, 0)].origin;
    NSUInteger index = [[self textView] characterIndexForPoint:point];
    
    [self selectLines:nil];  // for single click event
    
    // repeat while dragging
    [self setDraggingTimer:[NSTimer scheduledTimerWithTimeInterval:0.05
                                                            target:self
                                                          selector:@selector(selectLines:)
                                                          userInfo:@(index)
                                                           repeats:YES]];
}


// ------------------------------------------------------
/// end selecting correspondent lines in text view with drag event
- (void)mouseUp:(NSEvent *)theEvent
// ------------------------------------------------------
{
    [[self draggingTimer] invalidate];
    [self setDraggingTimer:nil];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return client view casting to textView
- (NSTextView *)textView
// ------------------------------------------------------
{
    return (NSTextView*)[self clientView];
}


// ------------------------------------------------------
/// select lines while dragging event
- (void)selectLines:(NSTimer *)timer
// ------------------------------------------------------
{
    NSTextView *textView = [self textView];
    NSPoint point = [NSEvent mouseLocation];  // screen based point
    
    // scroll text view if needed
    CGFloat y = [self convertPoint:[[self window] convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin
                          fromView:nil].y;
    if (y < 0) {
        [textView scrollLineUp:nil];
    } else if (y > NSHeight([self bounds])) {
        [textView scrollLineDown:nil];
    }
    
    // select lines
    NSUInteger currentIndex = [textView characterIndexForPoint:point];
    NSUInteger clickedIndex = timer ? [[timer userInfo] unsignedIntegerValue] : currentIndex;
    NSRange currentLineRange = [[textView string] lineRangeForRange:NSMakeRange(currentIndex, 0)];
    NSRange clickedLineRange = [[textView string] lineRangeForRange:NSMakeRange(clickedIndex, 0)];
    NSRange range = NSUnionRange(currentLineRange, clickedLineRange);
    
    // with Shift key
    if ([NSEvent modifierFlags] & NSShiftKeyMask) {
        NSRange selectedRange = [textView selectedRange];
        if (NSLocationInRange(currentIndex, selectedRange)) {  // reduce
            BOOL inUpperSection = (currentIndex - selectedRange.location) < selectedRange.length / 2;
            if (inUpperSection) {  // clicked upper half section of selected range
                range = NSMakeRange(currentIndex, NSMaxRange(selectedRange) - currentIndex);
                
            } else {
                range = selectedRange;
                range.length -= NSMaxRange(selectedRange) - NSMaxRange(currentLineRange);
            }
            
        } else {  // expand
            range = NSUnionRange(range, selectedRange);
        }
    }
    
    [textView setSelectedRange:range];
}



#pragma mark Private C Functions
/// digits of input number
unsigned int numberOfDigits(int number) { return (unsigned int)log10(number) + 1; }

/// number at the desired place of input number
unsigned int numberAt(int place, int number) { return (number % (int)pow(10, place + 1)) / pow(10, place); }

@end


@implementation NSString (count)

- (NSUInteger)numberOfLinesInRange:(NSRange)range includingLastNewLine:(BOOL)includingLastNewLine
// ------------------------------------------------------
{
    if ([self length] == 0 || range.length == 0) { return 0; }
    
    __block NSUInteger count = 0;
    
    [self enumerateSubstringsInRange:range
                             options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
     {
         count++;
     }];
    
    if (includingLastNewLine && [[NSCharacterSet newlineCharacterSet] characterIsMember:[self characterAtIndex:NSMaxRange(range) - 1]]) {
        count++;
    }
    
    return count;
}

@end
