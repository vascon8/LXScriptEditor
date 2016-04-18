//
//  LXTypeSetter.m
//  LXScriptEditor
//
//  Created by xinliu on 16-4-14.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "LXTypeSetter.h"
#import "SMLLayoutManager.h"
#import "SMLTextView.h"

@implementation LXTypeSetter
-(CGFloat)lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(NSRect)rect
{
//    SMLLayoutManager *manager = (SMLLayoutManager *)[self layoutManager];
    CGFloat lineSpacing = [(SMLTextView *)[[self currentTextContainer] textView] lineSpacing];
    
//    if (![manager fixesLineHeight]) {
//        CGFloat spacing = [super lineSpacingAfterGlyphAtIndex:glyphIndex withProposedLineFragmentRect:rect];
//        CGFloat fontSize = [[[[self currentTextContainer] textView] font] pointSize];
    
//        return (spacing + lineSpacing * fontSize);
    
    return lineSpacing;
//    }
}
@end
