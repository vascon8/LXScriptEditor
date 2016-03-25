//
//  LXTextAttachment.h
//  LXScriptEditor
//
//  Created by xin liu on 16/3/19.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LXTextAttachment : NSTextAttachment
+ (NSAttributedString *)placeholderAsAttributedStringWithName:(NSString *)name font:(NSFont*)font;
@end



@interface LXTextAttachmentCell :NSTextAttachmentCell
- (id)initTextCell:(NSString *)aString font:(NSFont*)font;
@end