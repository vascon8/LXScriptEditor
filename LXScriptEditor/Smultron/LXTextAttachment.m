//
//  LXTextAttachment.m
//  LXScriptEditor
//
//  Created by xin liu on 16/3/19.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "LXTextAttachment.h"

#import "SMLTextView.h"

#define HorizonPadding 6.0f
#define TokenInRectPadding 0.0f
#define TokenFontDelta 1.0f

@implementation LXTextAttachment
- (id)initWithName:(NSString *)name font:(NSFont*)font
{
//    NSFileWrapper *fw = [[NSFileWrapper alloc] init];
//    [fw setPreferredFilename:@"lxtokenattachment"];
    self = [super init];
    if (self) {
        LXTextAttachmentCell *aCell = [[LXTextAttachmentCell alloc] initTextCell:name font:font];
        [self setAttachmentCell:aCell];
    }
    
    return self;
    
}

+ (NSAttributedString *)placeholderAsAttributedStringWithName:(NSString *)name font:(NSFont *)font
{
    LXTextAttachment *attachment = [[LXTextAttachment alloc] initWithName:name font:font];
    return [NSAttributedString attributedStringWithAttachment:attachment];
}
@end


@implementation LXTextAttachmentCell
- (id)initTextCell:(NSString *)aString font:(NSFont*)font
{
    self = [super initTextCell:aString];
    if (self) {
        NSAttributedString *str = [[NSAttributedString alloc] initWithString:aString attributes:@{NSForegroundColorAttributeName: [NSColor blackColor],NSFontAttributeName:font}];
        [self setAttributedStringValue:str];
        [self setEditable:NO];
        [self setSelectable:YES];
        [self setType:NSTextCellType];
        [self setStringValue:aString];
    }
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [super drawWithFrame:cellFrame inView:controlView];
    
    if (![controlView isKindOfClass:[NSTextView class]]) return;
        
    BOOL isSelected = [self isSelectedInRect:cellFrame ofView:controlView];
    
    NSColor *cellColor = [NSColor colorWithSRGBRed:228.0 / 255.0 green:235.0 / 255.0 blue:249.0 / 255.0 alpha:1.0];
    
    if (isSelected) {
        cellColor = [NSColor colorWithSRGBRed:133.0 / 255.0 green:163.0 / 255.0 blue:239.0 / 255.0 alpha:1.0];
    }
    [cellColor set];

    NSBezierPath *bp = [NSBezierPath bezierPath];
    NSRect irect = NSInsetRect(cellFrame, TokenInRectPadding, TokenInRectPadding);
    [bp appendBezierPathWithRoundedRect:NSMakeRect(irect.origin.x,
                                                   irect.origin.y,
                                                   irect.size.width,
                                                   irect.size.height)
                                xRadius:0.5 * irect.size.height
                                yRadius:0.5 * irect.size.height];
    
    [bp fill];

    //remove round line
//    [[NSColor colorWithSRGBRed:183.0 / 255.0 green:201.0 / 255.0 blue:239.0 / 255.0 alpha:1.0] set];
//    [bp setLineWidth:1.0];
//    [bp stroke];
    
    NSAttributedString *string = [self attributedStringValue];
    NSMutableAttributedString *smallerString = [[NSMutableAttributedString alloc] initWithAttributedString:string];

    NSTextView *tv = (NSTextView *) controlView;
    NSFont *f = tv.textStorage.font;
//    NSLog(@"==f:%@",f);
    f = [NSFont fontWithName:f.fontName size:f.pointSize-TokenFontDelta];
//    NSLog(@"==f:%@",f);
    [smallerString addAttribute:NSFontAttributeName
                          value:f
                          range:NSMakeRange(0, [string length])];
    NSColor *textColor;

    if (isSelected) {
        textColor = [NSColor whiteColor];
    } else {
        textColor = [NSColor blackColor];
    }
    [smallerString addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, string.length)];
    
    NSSize strSize = [smallerString size];
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [ps setAlignment:NSCenterTextAlignment];
    [smallerString addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, [smallerString length])];
    
//    NSLog(@"strS:%@,iR:%@,cellF:%@",NSStringFromSize(strSize),NSStringFromRect(irect),NSStringFromRect(cellFrame));
    NSRect r = NSMakeRect(irect.origin.x + (irect.size.width - strSize.width) /2.0 ,
                          irect.origin.y + (irect.size.height - strSize.height)/2.0 - 2.0 ,
                          strSize.width, strSize.height);
//    [[NSColor blackColor] set];
//    NSLog(@"rect:%@,strs:%@",NSStringFromRect(r),NSStringFromSize(strSize));
    [smallerString drawInRect:r];
}

- (NSSize)cellSize
{
    NSAttributedString *str = [self attributedStringValue];
    NSSize size = [str size];
    NSSize cellS = NSMakeSize(2.0*HorizonPadding+2.0*TokenInRectPadding + 2.0*TokenInRectPadding +size.width,size.height-2*TokenFontDelta);
//    NSLog(@"cellS:%@,size:%@",NSStringFromSize(cellS),NSStringFromSize(size));
    return cellS;
}

-(NSPoint)cellBaselineOffset{
    NSPoint superPoint = [super cellBaselineOffset];
    superPoint.y -= 4.0;
    return superPoint;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(NSUInteger)charIndex untilMouseUp:(BOOL)flag
{
    if ([controlView isKindOfClass:[NSTextView class]]) {
        NSTextView *tv = (NSTextView *) controlView;
        [tv setSelectedRange:NSMakeRange(charIndex, 1)];
    }
    
    return [super trackMouse:theEvent inRect:cellFrame ofView:controlView atCharacterIndex:charIndex untilMouseUp:flag];
}
- (BOOL)isSelectedInRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
    if ([controlView isKindOfClass:[NSTextView class]]) {
        NSTextView *tv = (NSTextView *) controlView;
        NSArray *ranges = [tv selectedRanges];
        for (id rangeObject in ranges) {
            NSRange range = [rangeObject rangeValue];
            NSRange glyphRange = [tv.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
            NSRect glyphRect = [tv.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:tv.textContainer];
            if (NSPointInRect(cellFrame.origin, glyphRect)) {
                return YES;
            }
        }
        
    }
    return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}
-(id)mutableCopy
{
    return [self retain];
}
@end