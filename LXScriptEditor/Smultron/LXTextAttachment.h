//
//  LXTextAttachment.h
//  LXScriptEditor
//
//  Created by xin liu on 16/3/19.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LXTextAttachment : NSTextAttachment

@property (retain) id representedObject;
@property (copy) NSString * title;
@property (retain) NSColor * color;
//@property (assign) MTTokenStyle  style;

-(id)initWithTitle:(NSString*)aTitle;

@end



@interface LXTextAttachmentCell :NSTextAttachmentCell

@property (retain) NSString *tokenTitle;
@property (assign) BOOL selected;

@end