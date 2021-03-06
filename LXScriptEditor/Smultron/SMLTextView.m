/*
 
 
 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria
 
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
#import "SMLAutoCompleteDelegate.h"

#import "LXTextAttachment.h"
#import "LXEditScrollView.h"

NSString *LXMarkupPboardType = @"xinliu.EditEXample.TemplateMarkup";

// class extension
@interface SMLTextView()
- (void)windowDidBecomeMainOrKey:(NSNotification *)note;

@property (retain) NSColor *pageGuideColour;

@property (nonatomic, copy) NSString *particalCompletionWord;

@end

@implementation SMLTextView

@synthesize colouredIBeamCursor, fragaria, pageGuideColour, lineWrap;

#pragma mark -
#pragma mark Instance methods
/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		SMLLayoutManager *layoutManager = [[SMLLayoutManager alloc] init];
		[[self textContainer] replaceLayoutManager:layoutManager];
		
		[self setDefaults];
        
        // set initial line wrapping
        lineWrap = YES;
        [self updateLineWrap];
	}
	return self;
}
//#pragma mark - LXTextAttachmentCell delegate
//NSString *LXMarkupPboardType = @"com.xinliuTemplateMarkup";
//
//- (NSArray *)textView:(NSTextView *)aTextView writablePasteboardTypesForCell:(id <NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex {
//    return [NSArray arrayWithObject:LXMarkupPboardType];
//}
//
//- (BOOL)textView:(NSTextView *)aTextView writeCell:(id <NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex toPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
//    if (type == LXMarkupPboardType) {
//		LXTextAttachment *attachment = ((LXTextAttachmentCell *)cell).attachment;
//        
//		NSAttributedString *s = [NSAttributedString attributedStringWithAttachment:attachment];
//        [pboard writeObjects:[NSArray arrayWithObject:s]];
//    }
//    
//    return YES;
//}

#pragma mark -
#pragma mark Accessors
/*
 
 - lineHeight
 
 */
- (NSInteger)lineHeight
{
    return lineHeight;
}


/*
 
 - setDefaults
 
 */
- (void)setDefaults
{

	[self setTabWidth];
	
	[self setVerticallyResizable:YES];
	[self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[self setAutoresizingMask:NSViewWidthSizable];
	[self setAllowsUndo:YES];
    if ([self respondsToSelector:@selector(setUsesFindBar:)]) {
        [self setUsesFindBar:YES];
        [self setIncrementalSearchingEnabled:NO];
    } else {
        [self setUsesFindPanel:YES];
    }
	[self setAllowsDocumentBackgroundColorChange:NO];
	[self setRichText:NO];
	[self setImportsGraphics:NO];
	[self setUsesFontPanel:NO];
	
	[self setContinuousSpellCheckingEnabled:[[SMLDefaults valueForKey:MGSFragariaPrefsAutoSpellCheck] boolValue]];
	[self setGrammarCheckingEnabled:[[SMLDefaults valueForKey:MGSFragariaPrefsAutoGrammarCheck] boolValue]];
	
	[self setSmartInsertDeleteEnabled:[[SMLDefaults valueForKey:MGSFragariaPrefsSmartInsertDelete] boolValue]];
	[self setAutomaticLinkDetectionEnabled:[[SMLDefaults valueForKey:MGSFragariaPrefsAutomaticLinkDetection] boolValue]];
	[self setAutomaticQuoteSubstitutionEnabled:[[SMLDefaults valueForKey:MGSFragariaPrefsAutomaticQuoteSubstitution] boolValue]];
	
	[self setTextDefaults];
	
	[self setAutomaticDataDetectionEnabled:YES];
	[self setAutomaticTextReplacementEnabled:YES];
	
	[self setPageGuideValues];
	
	[self updateIBeamCursor];	
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self frame] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder) owner:self userInfo:nil];
	[self addTrackingArea:trackingArea];
    
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaTextFont" options:NSKeyValueObservingOptionNew context:@"TextFontChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaTextColourWell" options:NSKeyValueObservingOptionNew context:@"TextColourChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaBackgroundColourWell" options:NSKeyValueObservingOptionNew context:@"BackgroundColourChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaSmartInsertDelete" options:NSKeyValueObservingOptionNew context:@"SmartInsertDeleteChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaTabWidth" options:NSKeyValueObservingOptionNew context:@"TabWidthChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaShowPageGuide" options:NSKeyValueObservingOptionNew context:@"PageGuideChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaShowPageGuideAtColumn" options:NSKeyValueObservingOptionNew context:@"PageGuideChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.FragariaSmartInsertDelete" options:NSKeyValueObservingOptionNew context:@"SmartInsertDeleteChanged"];
	
	lineHeight = [[[self textContainer] layoutManager] defaultLineHeightForFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]]];
    
    self.lineSpacing = self.font.pointSize / 2.0 * 0.618;
//    self.lineSpacing = 0;
    
//    NSScrollView *guttScrollView = [fragaria valueForKey:ro_MGSFOGutterScrollView];
//    SMLGutterTextView *guttView = guttScrollView.documentView;
//    guttView.lineSpacing = self.lineSpacing;
//    [defaultsController addObserver:self forKeyPath:@"lineSpacing" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:@"lineSpacingChanged"];
    
//    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
//    [style setLineSpacing:10.0];
//    [self setDefaultParagraphStyle:style];
}

/*
 
 - setTextDefaults
 
 */
- (void)setTextDefaults
{
	[self setFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]]];
	[self setTextColor:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextColourWell]]];
	[self setInsertionPointColor:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextColourWell]]];
	[self setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsBackgroundColourWell]]];
}

/*
 
 - setFrame:
 
 */
//- (void)setFrame:(NSRect)rect
//{
//	[super setFrame:rect];
//    
//    [self didChangeText];
////	[[fragaria objectForKey:ro_MGSFOLineNumbers] updateLineNumbersForClipView:[[self enclosingScrollView] contentView] checkWidth:NO recolour:YES];
//	
//}

#pragma mark -
#pragma mark Copy and paste

/*
 
 - paste
 
 */
-(void)paste:(id)sender
{
    // let super paste
    [super paste:sender];

    // add the NSTextView  to the info dict
    NSDictionary *info = @{@"NSTextView": self};

    // send paste notification
    NSNotification *note = [NSNotification notificationWithName:@"MGSTextDidPasteNotification" object:self userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
    
    // inform delegate of Fragaria paste
    if ([self.delegate respondsToSelector:@selector(mgsTextDidPaste:)]) {
        [(id)self.delegate mgsTextDidPaste:note];
    }
}
- (NSArray *)writablePasteboardTypes
{
    return [[super writablePasteboardTypes] arrayByAddingObject:LXMarkupPboardType];
}
- (NSArray *)readablePasteboardTypes
{
    return [[super readablePasteboardTypes] arrayByAddingObject:LXMarkupPboardType];
}
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    if (type == LXMarkupPboardType)
    {
        NSAttributedString *selection;
        NSData *selectionAsData;
        BOOL result;
        
        selection = [[[[self textStorage] attributedSubstringFromRange:[self selectedRange]] copy] autorelease];
        
//        selectionAsData = [NSArchiver archivedDataWithRootObject:selection];
        selectionAsData = [NSKeyedArchiver archivedDataWithRootObject:selection];
        
        result = [pboard setData:selectionAsData forType:LXMarkupPboardType];
        
        return result;
    }
    return [super writeSelectionToPasteboard:pboard type:type];
}
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    if (type == NSStringPboardType) // resource fork and finder info if given
    {
        NSData* pasteboardData = [pboard dataForType:LXMarkupPboardType];
        
        if (pasteboardData) {
            id data = [NSKeyedUnarchiver unarchiveObjectWithData:pasteboardData];
//            data = [NSUnarchiver unarchiveObjectWithData:pasteboardData];
            
            if ([data isKindOfClass:[NSAttributedString class]]) {
                NSRange range = [self rangeForUserTextChange];
                
                NSMutableAttributedString *pbContent = [[NSMutableAttributedString alloc]initWithAttributedString:data];

//                NSLog(@"==pbcontent:%@,range:%@",pbContent,NSStringFromRange(range));
                
                __block BOOL hasCell = NO;
                [pbContent enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, pbContent.length) options:NSAttributedStringEnumerationReverse usingBlock:^(NSTextAttachment *value, NSRange range, BOOL *stop) {
                    if (value) {
                        hasCell = YES; *stop = YES;
                    }
                }];
                
                if (hasCell) {
//                    NSAttributedString *as = [LXTextAttachment placeholderAsAttributedStringWithName:pbContent.string font:self.textStorage.font textview:self];
                    [self shouldChangeTextInRange:range replacementString:pbContent.string];
                    [[self textStorage] beginEditing];
                    [[self textStorage] replaceCharactersInRange:range withAttributedString:pbContent];
                    [[self textStorage] endEditing];
                    
                    return YES;
                }

            }
        }
    }
    
    return [super readSelectionFromPasteboard:pboard type:type];
}
#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"TextFontChanged"]) {
		[self setFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]]];
		lineHeight = [[[self textContainer] layoutManager] defaultLineHeightForFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]]];
//		[[fragaria objectForKey:ro_MGSFOLineNumbers] updateLineNumbersForClipView:[[self enclosingScrollView] contentView] checkWidth:NO recolour:YES];
		[self setPageGuideValues];
	} else if ([(__bridge NSString *)context isEqualToString:@"TextColourChanged"]) {
		[self setTextColor:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextColourWell]]];
		[self setInsertionPointColor:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextColourWell]]];
		[self setPageGuideValues];
		[self updateIBeamCursor];
	} else if ([(__bridge NSString *)context isEqualToString:@"BackgroundColourChanged"]) {
		[self setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsBackgroundColourWell]]];
	} else if ([(__bridge NSString *)context isEqualToString:@"SmartInsertDeleteChanged"]) {
		[self setSmartInsertDeleteEnabled:[[SMLDefaults valueForKey:MGSFragariaPrefsSmartInsertDelete] boolValue]];
	} else if ([(__bridge NSString *)context isEqualToString:@"TabWidthChanged"]) {
		[self setTabWidth];
	} else if ([(__bridge NSString *)context isEqualToString:@"PageGuideChanged"]) {
		[self setPageGuideValues];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark -
#pragma mark Drawing
/*
 
 - isOpaque
 
 */
- (BOOL)isOpaque
{
	return YES;
}

/*
 
 - drawRect:
 
 */
- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	if (showPageGuide == YES) {
		NSRect bounds = [self bounds]; 
		if ([self needsToDrawRect:NSMakeRect(pageGuideX, 0, 1, bounds.size.height)] == YES) { // So that it doesn't draw the line if only e.g. the cursor updates
			[self.pageGuideColour set];
			[NSBezierPath strokeRect:NSMakeRect(pageGuideX, 0, 0, bounds.size.height)];
		}
	}
}

#pragma mark -
#pragma mark Mouse event handling
/*
 
 - mouseDown:
 
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	if (([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) { // If the option and command keys are pressed, change the cursor to grab-cursor
		startPoint = [theEvent locationInWindow];
		startOrigin = [[[self enclosingScrollView] contentView] documentVisibleRect].origin;
		[[self enclosingScrollView] setDocumentCursor:[NSCursor openHandCursor]];
	} else {
		[super mouseDown:theEvent];
	}
}


/*
 
 - mouseDragged:
 
 */
- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([[NSCursor currentCursor] isEqual:[NSCursor openHandCursor]]) {
		[self scrollPoint:NSMakePoint(startOrigin.x - ([theEvent locationInWindow].x - startPoint.x) * 3, startOrigin.y + ([theEvent locationInWindow].y - startPoint.y) * 3)];
	} else {
		[super mouseDragged:theEvent];
	}
}

/*
 
 - mouseUp:
 
 */
- (void)mouseUp:(NSEvent *)theEvent
{
#pragma unused(theEvent)
	[[self enclosingScrollView] setDocumentCursor:[NSCursor IBeamCursor]];
}

/*
 
 - mouseMoved:
 
 */
- (void)mouseMoved:(NSEvent *)theEvent
{
#pragma unused(theEvent)
	if ([NSCursor currentCursor] == [NSCursor IBeamCursor]) {
		[colouredIBeamCursor set];
	}
}

/*
 
 - menuForEvent:
 
 */
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	
	NSMenu *menu = [super menuForEvent:theEvent];
	
	return menu;
	
	// TODO: consider what menu behaviour is appropriate
	/*
	 NSArray *array = [menu itemArray];
	 for (id oldMenuItem in array) {
	 if ([oldMenuItem tag] == -123457) {
	 [menu removeItem:oldMenuItem];
	 }		
	 }
	 
	 [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
	 
	 NSEnumerator *collectionEnumerator = [[SMLBasic fetchAll:@"SnippetCollectionSortKeyName"] reverseObjectEnumerator];
	 for (id collection in collectionEnumerator) {
	 if ([collection valueForKey:@"name"] == nil) {
	 continue;
	 }
	 NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[collection valueForKey:@"name"] action:nil keyEquivalent:@""];
	 [menuItem setTag:-123457];
	 NSMenu *subMenu = [[NSMenu alloc] init];
	 
	 NSMutableArray *array = [NSMutableArray arrayWithArray:[[collection mutableSetValueForKey:@"snippets"] allObjects]];
	 [array sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	 for (id snippet in array) {
	 if ([snippet valueForKey:@"name"] == nil) {
	 continue;
	 }
	 NSString *keyString;
	 if ([snippet valueForKey:@"shortcutMenuItemKeyString"] != nil) {
	 keyString = [snippet valueForKey:@"shortcutMenuItemKeyString"];
	 } else {
	 keyString = @"";
	 }
	 NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[snippet valueForKey:@"name"] action:@selector(snippetShortcutFired:) keyEquivalent:@""];
	 [subMenuItem setTarget:[SMLToolsMenuController sharedInstance]];			
	 [subMenuItem setRepresentedObject:snippet];
	 [subMenu insertItem:subMenuItem atIndex:0];
	 }
	 
	 [menuItem setSubmenu:subMenu];
	 [menu insertItem:menuItem atIndex:0];
	 }
	 
	 return menu;
	 */
}

#pragma mark -
#pragma mark Tab and page guide handling
/*
 
 - insertTab:
 
 */
- (void)insertTab:(id)sender
{	
	BOOL shouldShiftText = NO;
	
	if ([self selectedRange].length > 0) { // Check to see if the selection is in the text or if it's at the beginning of a line or in whitespace; if one doesn't do this one shifts the line if there's only one suggestion in the auto-complete
		NSRange rangeOfFirstLine = [[self string] lineRangeForRange:NSMakeRange([self selectedRange].location, 0)];
		NSUInteger firstCharacterOfFirstLine = rangeOfFirstLine.location;
		while ([[self string] characterAtIndex:firstCharacterOfFirstLine] == ' ' || [[self string] characterAtIndex:firstCharacterOfFirstLine] == '\t') {
			firstCharacterOfFirstLine++;
		}
		if ([self selectedRange].location <= firstCharacterOfFirstLine) {
			shouldShiftText = YES;
		}
	}
	
	if (shouldShiftText) {
		[[MGSTextMenuController sharedInstance] shiftRightAction:nil];
	} else if ([[SMLDefaults valueForKey:MGSFragariaPrefsIndentWithSpaces] boolValue] == YES) {
		NSMutableString *spacesString = [NSMutableString string];
		NSInteger numberOfSpacesPerTab = [[SMLDefaults valueForKey:MGSFragariaPrefsTabWidth] integerValue];
		if ([[SMLDefaults valueForKey:MGSFragariaPrefsUseTabStops] boolValue] == YES) {
			NSInteger locationOnLine = [self selectedRange].location - [[self string] lineRangeForRange:[self selectedRange]].location;
			if (numberOfSpacesPerTab != 0) {
				NSInteger numberOfSpacesLess = locationOnLine % numberOfSpacesPerTab;
				numberOfSpacesPerTab = numberOfSpacesPerTab - numberOfSpacesLess;
			}
		}
		while (numberOfSpacesPerTab--) {
			[spacesString appendString:@" "];
		}
		
		[self insertText:spacesString];
	} else if ([self selectedRange].length > 0) { // If there's only one word matching in auto-complete there's no list but just the rest of the word inserted and selected; and if you do a normal tab then the text is removed so this will put the cursor at the end of that word
		[self setSelectedRange:NSMakeRange(NSMaxRange([self selectedRange]), 0)];
	} else {
		[super insertTab:sender];
	}
}

/*
 
 - setTabWidth
 
 */
- (void)setTabWidth
{
	// Set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
	NSMutableString *sizeString = [NSMutableString string];
	NSInteger numberOfSpaces = [[SMLDefaults valueForKey:MGSFragariaPrefsTabWidth] integerValue];
	while (numberOfSpaces--) {
		[sizeString appendString:@" "];
	}
	NSDictionary *sizeAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]], NSFontAttributeName, nil];
	CGFloat sizeOfTab = [sizeString sizeWithAttributes:sizeAttribute].width;
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	
	NSArray *array = [style tabStops];
	for (id item in array) {
		[style removeTabStop:item];
	}
	[style setDefaultTabInterval:sizeOfTab];
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:style, NSParagraphStyleAttributeName, nil];
	[self setTypingAttributes:attributes];
}

/*
 
 - setPageGuideValues
 
 */
- (void)setPageGuideValues
{
	NSDictionary *sizeAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]], NSFontAttributeName, nil];
	NSString *sizeString = @" ";
	CGFloat sizeOfCharacter = [sizeString sizeWithAttributes:sizeAttribute].width;
	pageGuideX = (sizeOfCharacter * ([[SMLDefaults valueForKey:MGSFragariaPrefsShowPageGuideAtColumn] integerValue] + 1)) - 1.5f; // -1.5 to put it between the two characters and draw only on one pixel and not two (as the system draws it in a special way), and that's also why the width above is set to zero 
	
	NSColor *color = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextColourWell]];
	self.pageGuideColour = [color colorWithAlphaComponent:([color alphaComponent] / 4)]; // Use the same colour as the text but with more transparency
	
	showPageGuide = [[SMLDefaults valueForKey:MGSFragariaPrefsShowPageGuide] boolValue];
	
	[self display]; // To reflect the new values in the view
}

#pragma mark -
#pragma mark Text handling
/*
 
 - insertText:
 
 */
- (void)insertText:(NSString *)aString
{
//    NSLog(@"==insert:%@",aString);
    
	if ([aString isEqualToString:@"}"] && [[SMLDefaults valueForKey:MGSFragariaPrefsIndentNewLinesAutomatically] boolValue] == YES && [[SMLDefaults valueForKey:MGSFragariaPrefsAutomaticallyIndentBraces] boolValue] == YES) {
		unichar characterToCheck;
		NSInteger location = [self selectedRange].location;
		NSString *completeString = [self string];
		NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
		NSRange currentLineRange = [completeString lineRangeForRange:NSMakeRange([self selectedRange].location, 0)];
		NSInteger lineLocation = location;
		NSInteger lineStart = currentLineRange.location;
		while (--lineLocation >= lineStart) { // If there are any characters before } on the line skip indenting
			if ([whitespaceCharacterSet characterIsMember:[completeString characterAtIndex:lineLocation]]) {
				continue;
			}
			[super insertText:aString];
			return;
		}
		
		BOOL hasInsertedBrace = NO;
		NSUInteger skipMatchingBrace = 0;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '{') {
				if (skipMatchingBrace == 0) { // If we have found the opening brace check first how much space is in front of that line so the same amount can be inserted in front of the new line
					NSString *openingBraceLineWhitespaceString;
					NSScanner *openingLineScanner = [[NSScanner alloc] initWithString:[completeString substringWithRange:[completeString lineRangeForRange:NSMakeRange(location, 0)]]];
					[openingLineScanner setCharactersToBeSkipped:nil];
					BOOL foundOpeningBraceWhitespace = [openingLineScanner scanCharactersFromSet:whitespaceCharacterSet intoString:&openingBraceLineWhitespaceString];
					
					if (foundOpeningBraceWhitespace == YES) {
						NSMutableString *newLineString = [NSMutableString stringWithString:openingBraceLineWhitespaceString];
						[newLineString appendString:@"}"];
						[newLineString appendString:[completeString substringWithRange:NSMakeRange([self selectedRange].location, NSMaxRange(currentLineRange) - [self selectedRange].location)]];
						if ([self shouldChangeTextInRange:currentLineRange replacementString:newLineString]) {
							[self replaceCharactersInRange:currentLineRange withString:newLineString];
							[self didChangeText];
						}
						hasInsertedBrace = YES;
						[self setSelectedRange:NSMakeRange(currentLineRange.location + [openingBraceLineWhitespaceString length] + 1, 0)]; // +1 because we have inserted a character
					} else {
						NSString *restOfLineString = [completeString substringWithRange:NSMakeRange([self selectedRange].location, NSMaxRange(currentLineRange) - [self selectedRange].location)];
						if ([restOfLineString length] != 0) { // To fix a bug where text after the } can be deleted
							NSMutableString *replaceString = [NSMutableString stringWithString:@"}"];
							[replaceString appendString:restOfLineString];
							hasInsertedBrace = YES;
							NSInteger lengthOfWhiteSpace = 0;
							if (foundOpeningBraceWhitespace == YES) {
								lengthOfWhiteSpace = [openingBraceLineWhitespaceString length];
							}
							if ([self shouldChangeTextInRange:currentLineRange replacementString:replaceString]) {
								[self replaceCharactersInRange:[completeString lineRangeForRange:currentLineRange] withString:replaceString];
								[self didChangeText];
							}
							[self setSelectedRange:NSMakeRange(currentLineRange.location + lengthOfWhiteSpace + 1, 0)]; // +1 because we have inserted a character
						} else {
							[self replaceCharactersInRange:[completeString lineRangeForRange:currentLineRange] withString:@""]; // Remove whitespace before }
						}
				
					}
					break;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '}') {
				skipMatchingBrace++;
			}
		}
		if (hasInsertedBrace == NO) {
			[super insertText:aString];
		}
	} else if ([aString isEqualToString:@"("] && [[SMLDefaults valueForKey:MGSFragariaPrefsAutoInsertAClosingParenthesis] boolValue] == YES) {
		[super insertText:aString];
		NSRange selectedRange = [self selectedRange];
		if ([self shouldChangeTextInRange:selectedRange replacementString:@")"]) {
			[self replaceCharactersInRange:selectedRange withString:@")"];
			[self didChangeText];
			[self setSelectedRange:NSMakeRange(selectedRange.location - 0, 0)];
		}
	} else if ([aString isEqualToString:@"{"] && [[SMLDefaults valueForKey:MGSFragariaPrefsAutoInsertAClosingBrace] boolValue] == YES) {
		[super insertText:aString];
		NSRange selectedRange = [self selectedRange];
		if ([self shouldChangeTextInRange:selectedRange replacementString:@"}"]) {
			[self replaceCharactersInRange:selectedRange withString:@"}"];
			[self didChangeText];
			[self setSelectedRange:NSMakeRange(selectedRange.location - 0, 0)];
		}
	} else {
		[super insertText:aString];
	}
}

/*
 
 - insertNewline:
 
 */
- (void)insertNewline:(id)sender
{
	[super insertNewline:sender];
	
	// If we should indent automatically, check the previous line and scan all the whitespace at the beginning of the line into a string and insert that string into the new line
	NSString *lastLineString = [[self string] substringWithRange:[[self string] lineRangeForRange:NSMakeRange([self selectedRange].location - 1, 0)]];
	if ([[SMLDefaults valueForKey:MGSFragariaPrefsIndentNewLinesAutomatically] boolValue] == YES) {
		NSString *previousLineWhitespaceString;
		NSScanner *previousLineScanner = [[NSScanner alloc] initWithString:[[self string] substringWithRange:[[self string] lineRangeForRange:NSMakeRange([self selectedRange].location - 1, 0)]]];
		[previousLineScanner setCharactersToBeSkipped:nil];		
		if ([previousLineScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&previousLineWhitespaceString]) {
			[self insertText:previousLineWhitespaceString];
		}
		
		if ([[SMLDefaults valueForKey:MGSFragariaPrefsAutomaticallyIndentBraces] boolValue] == YES) {
			NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
			NSInteger idx = [lastLineString length];
			while (idx--) {
				if ([characterSet characterIsMember:[lastLineString characterAtIndex:idx]]) {
					continue;
				}
				if ([lastLineString characterAtIndex:idx] == '{') {
					[self insertTab:nil];
				}
				break;
			}
		}
	}
}

/*
 
 - setString:
 
 */
- (void)setString:(NSString *)aString
{
//    NSLog(@"===setstring=");
	[super setString:aString];
//	[[fragaria objectForKey:ro_MGSFOLineNumbers] updateLineNumbersCheckWidth:YES recolour:YES];
    
    [self didChangeText];
    
//    [(LXEditScrollView*)[self enclosingScrollView] invalidateLineNumber];
}

/*
 
 - setString:options:
 
 */
- (void)setString:(NSString *)text options:(NSDictionary *)options
{
    NSRange all = NSMakeRange(0, [self.textStorage length]);
    [self replaceCharactersInRange:all withString:text options:options];
}
/*
 
 - replaceCharactersInRange:withString:options
 
 */
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)text options:(NSDictionary *)options
{
	BOOL undo = [[options objectForKey:@"undo"] boolValue];
    BOOL textViewWasEmpty = ([self.textStorage length] == 0 ? YES : NO);
    NSLog(@"==undo");

	if ([self isEditable] && undo) {

        // this sequence will be registered with the undo manager
		if ([self shouldChangeTextInRange:range replacementString:text]) {
            
            // modify he text storage
			[self.textStorage beginEditing];
			[self.textStorage replaceCharactersInRange:range withString:text];
			[self.textStorage endEditing];
            
            // reset the default font if text was empty as the font gets reset to system default.
            if (textViewWasEmpty) {
                [self setFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]]];
            }

			// TODO: this doesn't seem to be having the desired effect
            NSUndoManager *undoManager = [self undoManager];
			[undoManager setActionName:NSLocalizedString(@"Content Change", @"undo content change")];

            // complete the text change operation
			[self didChangeText];
		}
	} else if (textViewWasEmpty) {
        // this operation will not be registered with the undo manager
        [self setString:text];
    } else {
        // this operation will not be registered with the undo manager
		[self.textStorage replaceCharactersInRange:range withString:text];;
	}	
}

/*
 
 - setAttributedString:
 
 */
- (void)setAttributedString:(NSAttributedString *)text
{
    NSLog(@"==setAttrstr==");
    NSTextStorage *textStorage = [self textStorage];
    [textStorage setAttributedString:text];
    
//    [[fragaria objectForKey:ro_MGSFOLineNumbers] updateLineNumbersCheckWidth:YES recolour:YES];
    
    [self didChangeText];
}

/*
 
 - setAttributedString:options:
 
 */
- (void)setAttributedString:(NSAttributedString *)text options:(NSDictionary *)options
{
	BOOL undo = [[options objectForKey:@"undo"] boolValue];

    NSTextStorage *textStorage = [self textStorage];
    NSLog(@"==setattr undo");
	if ([self isEditable] && undo) {
		
        /*
		 
		 see http://www.cocoabuilder.com/archive/cocoa/179875-exponent-action-in-nstextview-subclass.html
		 entitled: Re: "exponent" action in NSTextView subclass (SOLVED)
		 
		 This details how to make programatic changes to the textStorage object.
		 
		 */
        
        /*
         
         code here reflects what occurs in - setString:options:
         
         may be over complicated
         
         */
		NSRange all = NSMakeRange(0, [textStorage length]);
        BOOL textIsEmpty = ([textStorage length] == 0 ? YES : NO);
        
		if ([self shouldChangeTextInRange:all replacementString:[text string]]) {
			[textStorage beginEditing];
			[textStorage setAttributedString:text];
			[textStorage endEditing];
            
            // reset the default font if text was empty as the font gets reset to system default.
            if (textIsEmpty) {
                [self setFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextFont]]];
            }
            
			[self didChangeText];
            
			NSUndoManager *undoManager = [self undoManager];
			
			// TODO: this doesn't seem to be having the desired effect
			[undoManager setActionName:NSLocalizedString(@"Content Change", @"undo content change")];
			
		}
	} else {
        [self setAttributedString:text];
	}
	
}

/*

 - appendString:
 
 */
- (void)appendString:(NSString *)aString
{
    NSLog(@"===appendstr==");
    NSMutableString * string = [NSMutableString stringWithString:[super string]];
    [string appendString:aString];
    [self setString:string];
}

#pragma mark -
#pragma mark Selection handling
/*
 
 - selectionRangeForProposedRange:granularity:
 
 */
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
	// If it's not a mouse event return unchanged
	NSEventType eventType = [[NSApp currentEvent] type];
	if (eventType != NSLeftMouseDown && eventType != NSLeftMouseUp) {
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	}
	
	if (granularity != NSSelectByWord || [[self string] length] == proposedSelRange.location || [[NSApp currentEvent] clickCount] != 2) { // If it's not a double-click return unchanged
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	}
	
	NSUInteger location = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByCharacter].location;
	NSInteger originalLocation = location;
	
	NSString *completeString = [self string];
	unichar characterToCheck = [completeString characterAtIndex:location];
	NSInteger skipMatchingBrace = 0;
	NSUInteger lengthOfString = [completeString length];
	if (lengthOfString == proposedSelRange.location) { // To avoid crash if a double-click occurs after any text
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	}
	
	BOOL triedToMatchBrace = NO;
	
	if (characterToCheck == ')') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '(') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ')') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '}') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '{') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '}') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == ']') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '[') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ']') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '>') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '<') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '>') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '(') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == ')') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '(') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '{') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '}') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '{') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '[') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == ']') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '[') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '<') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '>') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '<') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	}
	
	// If it has a found a "starting" brace but not found a match, a double-click should only select the "starting" brace and not what it usually would select at a double-click
	if (triedToMatchBrace) {
		return [super selectionRangeForProposedRange:NSMakeRange(proposedSelRange.location, 1) granularity:NSSelectByCharacter];
	} else {
		
		NSInteger startLocation = originalLocation;
		NSInteger stopLocation = originalLocation;
		NSInteger minLocation = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByWord].location;
		NSInteger maxLocation = NSMaxRange([super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByWord]);
		
		BOOL hasFoundSomething = NO;
		while (--startLocation >= minLocation) {
			if ([completeString characterAtIndex:startLocation] == '.' || [completeString characterAtIndex:startLocation] == ':') {
				hasFoundSomething = YES;
				break;
			}
		}
		
		while (++stopLocation < maxLocation) {
			if ([completeString characterAtIndex:stopLocation] == '.' || [completeString characterAtIndex:stopLocation] == ':') {
				hasFoundSomething = YES;
				break;
			}
		}
		
		if (hasFoundSomething == YES) {
			return NSMakeRange(startLocation + 1, stopLocation - startLocation - 1);
		} else {
			return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
		}
	}
}


#pragma mark -
#pragma mark Persistence
/*
 
 - save:
 
 */
- (IBAction)save:(id)sender
{
#pragma unused(sender)
	// no implicit save functionality
}

#pragma mark -
#pragma mark Cursor handling
/*
 
 - updateIBeamCursor:
 
 */
- (void)updateIBeamCursor
{
	NSColor *textColour = [[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextColourWell]] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
	
	if (textColour != nil && [textColour whiteComponent] < 0.01 && [textColour alphaComponent] > 0.990) { // Keep the original cursor if it's black
		[self setColouredIBeamCursor:[NSCursor IBeamCursor]];
	} else {
		NSImage *cursorImage = [[NSCursor IBeamCursor] image];
		[cursorImage lockFocus];
		[(NSColor *)[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsTextColourWell]] set];
		NSRectFillUsingOperation(NSMakeRect(0, 0, [cursorImage size].width, [cursorImage size].height), NSCompositeSourceAtop);
		[cursorImage unlockFocus];
        NSCursor *cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[NSCursor IBeamCursor] hotSpot]];
		[self setColouredIBeamCursor:cursor];
	}
}

/*
 
 - cursorUpdate:
 
 */
- (void)cursorUpdate:(NSEvent *)event
{
#pragma unused(event)
	[colouredIBeamCursor set];
}
	
#pragma mark -
#pragma mark Find
/*
 
 - performFindPanelAction:
 
 */
- (void)performFindPanelAction:(id)sender
{
	[super performFindPanelAction:sender];
}

#pragma mark -
#pragma mark Auto Completion


/*
 
 - rangeForUserCompletion
 */
- (NSRange)rangeForUserCompletion
{
    NSRange cursor = [self selectedRange];
    NSUInteger loc = cursor.location;
    
    // Check for selections (can only autocomplete when nothing is selected)
    if (cursor.length > 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    // Cannot autocomplete on first character
    if (loc == 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    // Create char set with characters valid for variables
    NSCharacterSet* variableChars = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVXYZ0123456789_"];
    
    NSString* text = [self string];
    
    // Can only autocomplete on variable names
    if (![variableChars characterIsMember:[text characterAtIndex:loc-1]])
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    // TODO: Check if we are in a string
    
    // Search backwards in string until we hit a non-variable char
    NSUInteger numChars = 1;
    NSUInteger searchLoc = loc - 1;
    while (searchLoc > 0)
    {
        if ([variableChars characterIsMember:[text characterAtIndex:searchLoc-1]])
        {
            numChars += 1;
            searchLoc -= 1;
        }
        else
        {
            break;
        }
    }
    NSRange resultRange = NSMakeRange(loc-numChars, numChars);
//    NSLog(@"rangeForUsercompletaion===%@",NSStringFromRange(resultRange));
    return resultRange;
}

/*
 
 - completionsForPartialWordRange:indexOfSelectedItem;
 
 */
- (NSArray*)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
#pragma unused(index, charRange)
    // get completion handler
    NSMutableArray* matchArray = [NSMutableArray array];
    
    id<SMLAutoCompleteDelegate> completeHandler = [fragaria.docSpec valueForKey:MGSFOAutoCompleteDelegate];

    // get string to match
    NSString *matchString = [[self string] substringWithRange:charRange];
//    NSLog(@"==comple:%@",matchString);
    // use handler
    if (completeHandler) {
        
        // get all completions
        NSArray* allCompletions = [completeHandler completions];
        
        //add to avoid replace the current input string
//        [matchArray addObject:matchString];
        
        // build array of suitable suggestions
        for (NSString* completeWord in allCompletions)
        {
            if ([completeWord rangeOfString:matchString options:NSLiteralSearch range:NSMakeRange(0, [completeWord length])].location == 0)
            {
                [matchArray addObject:completeWord];
            }
        }
    }
    
    // extract words in document and set to candidateWords
    if (matchString.length>0) {
 
        if (charRange.length == 1 && ![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[matchString characterAtIndex:0]]) {
            // do nothing if the particle word is an symbol
            
        } else {
            NSString *documentString = [self string];
            NSString *pattern = [NSString stringWithFormat:@"(?:^|\\b|(?<=\\W))%@\\w+?(?:$|\\b)",
                                 [NSRegularExpression escapedPatternForString:matchString]];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
            [regex enumerateMatchesInString:documentString options:0
                                      range:NSMakeRange(0, [documentString length])
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
             {
                 NSString *matchResultInDocument = [documentString substringWithRange:[result range]];
                 if(![matchArray containsObject:matchResultInDocument])[matchArray addObject:matchResultInDocument];
             }];
        }
    }
    
//    NSLog(@"completion==range:%@,matchArr:%@",NSStringFromRange(charRange),matchArray);
    return matchArray;
}
- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag
{
//    if (movement == NSReturnTextMovement || movement == NSTabTextMovement) {
//        [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
//        [self addToken:word];
//    }
    
    NSEvent *event = [[self window] currentEvent];
    BOOL didComplete = NO;
    
//    [[self completionTimer] invalidate];
    
//    NSLog(@"==word:%@,charRange:%@,str:%@",word,NSStringFromRange(charRange),[[self string] substringWithRange:charRange]);
    
    if (![self particalCompletionWord]) {
        [self setParticalCompletionWord:[[self string] substringWithRange:charRange]];
    }
    
    if (flag && ([event type] == NSKeyDown) && !([event modifierFlags] & NSCommandKeyMask)) {
        NSString *inputChar = [event charactersIgnoringModifiers];
        unichar theUnichar = [inputChar characterAtIndex:0];
        
        if ([inputChar isEqualToString:[event characters]]) {
            if (([inputChar isEqualToString:@"_"]) && (movement == NSRightTextMovement)) {
                movement = NSIllegalTextMovement;
//                flag = NO;
            }
            if ((movement == NSIllegalTextMovement) &&
                (theUnichar < 0xF700) && (theUnichar != NSDeleteCharacter)) {
//                [self setNeedsRecompletion:YES];
            }
        }
    }
    
    if (flag) {
        if ((movement == NSIllegalTextMovement) || (movement == NSRightTextMovement)) {
            word = [self particalCompletionWord];
        } else {
            didComplete = YES;
        }
        
        [self setParticalCompletionWord:nil];
    }
    
    [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
//       NSLog(@"after word:%@,charRange:%@,str:%@",word,NSStringFromRange(charRange),[[self string] substringWithRange:charRange]);
    BOOL isAddToken = NO;
    if(didComplete) isAddToken = [self addToken:word charRange:charRange];
    
    if (didComplete) {
        NSRange rangeToSelect = [word rangeOfString:@"(?<=\\().*(?=\\))" options:NSRegularExpressionSearch];
        if (rangeToSelect.location != NSNotFound && rangeToSelect.length>1) {
            rangeToSelect.location += charRange.location;
            if(isAddToken) rangeToSelect.length = 1;
//            NSLog(@"charR:%@,selectR:%@",NSStringFromRange(charRange),NSStringFromRange(rangeToSelect));
            [self setSelectedRange:rangeToSelect];
        }
    }
}
#pragma mark - token
- (BOOL)addToken:(NSString*)word charRange:(NSRange)charRange
{
    if(charRange.location == NSNotFound) return NO;
    NSString *lang = [fragaria.docSpec valueForKey:MGSFOSyntaxDefinitionName];
    lang = [lang lowercaseString];
    if(![lang isEqualToString:@"python"] && ![lang isEqualToString:@"java"]) return NO;
    
    NSRange bR = [word rangeOfString:@"("];
    NSRange fR = [word rangeOfString:@")" options:NSBackwardsSearch];
//    NSLog(@"==br:%@,fr:%@",NSStringFromRange(bR),NSStringFromRange(fR));
    if (bR.location != NSNotFound && fR.location != NSNotFound && bR.location+bR.length<fR.location) {
        NSUInteger subLoc = bR.location+1;
        NSString *subStr = [word substringWithRange:NSMakeRange(subLoc, fR.location-bR.location-1)];
//        NSLog(@"=substr:%@",subStr);
        if (subStr.length>0)
        {
            NSArray *comps = [subStr componentsSeparatedByString:@","];
            if (comps && comps.count>0) {
                NSUInteger count = comps.count;
                for (NSInteger j=count-1;j>=0;j--) {
                    NSString *compStr = comps[j];
                    NSInteger i = 0;
                    while ((i < compStr.length)
                           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[compStr characterAtIndex:i]]) {
                        i++;
                    }
                    NSString *finalStr = [compStr substringFromIndex:i];
                    
                    NSRange compRange = [subStr rangeOfString:finalStr];
                    if(compRange.location==NSNotFound) continue;
                    NSRange tokenEffecRange = NSMakeRange(charRange.location+compRange.location+subLoc, finalStr.length);
//                    NSLog(@"==finalstr:%@,compR:%@,tokenR:%@",finalStr,NSStringFromRange(compRange),NSStringFromRange(tokenEffecRange));
                    NSAttributedString*  as = [LXTextAttachment placeholderAsAttributedStringWithName:finalStr font:self.textStorage.font];
                    if(![[self.textStorage.string substringWithRange:tokenEffecRange] isEqualToString:finalStr]) continue;
                    if (tokenEffecRange.location!=NSNotFound && as.length>0 && NSMaxRange(tokenEffecRange)<[self.textStorage length]) {
                        [self shouldChangeTextInRange:tokenEffecRange replacementString:as.string];
                        [[self textStorage] beginEditing];
                        [[self textStorage] replaceCharactersInRange:tokenEffecRange withAttributedString:as];
                        [[self textStorage] endEditing];
                    }
                    
                }
            }
            return YES;
        }
        
    }
    
    //<!#TokenStr#!>
//    if ([word hasSuffix:@"#!>)"]) {
//        NSRange tokenBRange = [word rangeOfString:@"(<!#"];
//        if (tokenBRange.location!=NSNotFound) {
////            NSRange selectedRange = self.selectedRange;
//            
//            NSRange tokenStrRange = NSMakeRange(tokenBRange.location+1, word.length-tokenBRange.location-2);
//            NSString *tokenStr = [word substringWithRange:tokenStrRange];
//            
//            NSRange tokenEffecRange = NSMakeRange(charRange.location+tokenBRange.location+1, tokenStr.length);
//            
////            NSLog(@"selectRange:%@,tokenStrRange:%@,str:%@,tokenEffect:%@",NSStringFromRange(selectedRange),NSStringFromRange(tokenStrRange),tokenStr,NSStringFromRange(tokenEffecRange));
//            
//            NSAttributedString *insertionText = [self tokenForString:tokenStr range:tokenEffecRange];
////            NSLog(@"==inseText:%@",insertionText);
//            [[self textStorage] replaceCharactersInRange:tokenEffecRange withAttributedString:insertionText];
//            return YES;
//        }
//    }
    
    return NO;
}
//-(NSAttributedString*)tokenForString:(NSString*)aString range:(NSRange)range
//{
//    
//    NSAttributedString*  as = [LXTextAttachment placeholderAsAttributedStringWithName:aString font:self.textStorage.font;
//	return as;
//}
/*
- (void)textStorageWillProcessEditing:(NSNotification *)notification
{
    NSRange range = [self.textStorage editedRange];
    //FLOG(@"     editRange is %lu, %lu", range.location, range.length);
    
    [self.textStorage enumerateAttributesInRange:range options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:
     ^(NSDictionary *attributes, NSRange range, BOOL *stop) {
         
         // Iterate over each attribute and look for a Font Size
         [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
             if ([[key description] isEqualToString:NSAttachmentAttributeName]) {
                 //FLOG(@" attachment of class %@ found", [obj class]);
                 
                 NSTextAttachment *attachment = (NSTextAttachment *)obj;
                 NSLog(@" attachment found");
                 
                 //Replace the default attachment cell with our own
                 [self replaceAttachmentCell:attachment];
             }
             
         }];
     }];
}
- (void)replaceAttachmentCell:(NSTextAttachment*)attachment {
    
    // If its one we have already replaced then return
    if ([attachment.attachmentCell isKindOfClass:[LXTextAttachmentCell class]]) {
        //LOG(@" attachmentCell is already an OSTextAttachmentCell so do nothing");
        return;
    }
    
    //LOG(@" attachmentCell is NOT OSTextAttachmentCell so replace it");
    
    // Get the current attachment cell
    NSTextAttachmentCell *cell = (NSTextAttachmentCell *)[attachment attachmentCell] ;
    
    // Get the image from it
    NSImage * image = [cell image];
    
    // Create a new one with the image
    LXTextAttachmentCell *newCell = [[LXTextAttachmentCell alloc] initImageCell:image];
    
    // Now replace the attachment cell
    [attachment setAttachmentCell:newCell];
    
    return;
}
 */
- (void)keyDown:(NSEvent *)theEvent
{
//    NSLog(@"range:%@",NSStringFromRange(self.selectedRange));
    
    unsigned short keyCode = [theEvent keyCode];
    if (keyCode == 48) {
        
        NSTextStorage *storage = self.textStorage;
        NSRange scanRange = self.selectedRange;
        __block BOOL fond = NO;
        
        if (scanRange.location!=NSNotFound && NSMaxRange(scanRange) < storage.string.length) {
            scanRange.location += scanRange.length;
            scanRange.length = storage.length - scanRange.location;
            
            [storage enumerateAttribute:NSAttachmentAttributeName inRange:scanRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (range.location && [self validateComment:range] && value) {
//                    NSLog(@"range:%@,va:%@",NSStringFromRange(range),value);
                    [self setSelectedRange:range];
                    [self scrollRangeToVisible:range];
                    fond = YES;
                    *stop = YES;
                }
            }];
        }
        if (!fond) {
            NSRange scanR;
            if(scanRange.location==NSNotFound) scanR = NSMakeRange(0, storage.length-1);
            else scanR = NSMakeRange(0, self.selectedRange.location+self.selectedRange.length);
            
            [storage enumerateAttribute:NSAttachmentAttributeName inRange:scanR	 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (range.location && [self validateComment:range] && value) {
//                    NSLog(@"range:%@,va:%@",NSStringFromRange(range),value);
                    [self setSelectedRange:range];
                    [self scrollRangeToVisible:range];
                    fond = YES;
                    *stop = YES;
                }
            }];
        }

        if(!fond) [super keyDown:theEvent];
    }
    else
    {
        [super keyDown:theEvent];
    }
}
- (BOOL)validateComment:(NSRange)tokenRange
{
    BOOL validate = YES;
    
    NSRange lineRange = [self.textStorage.string lineRangeForRange:tokenRange];
    NSRange checkRange = NSMakeRange(lineRange.location, tokenRange.location-lineRange.location);
    
//    NSLog(@"==range:%@",NSStringFromRange(checkRange));
    if (checkRange.location != NSNotFound) {
        NSString *commentString = [[SMLCurrentDocument valueForKey:ro_MGSFOSyntaxColouring] valueForKey:@"firstSingleLineComment"];
        NSString *restStr = [self.textStorage.string substringWithRange:checkRange];
        NSRange commentR = [restStr rangeOfString:commentString];
//        NSLog(@"==reststr:%@,comm:%@",restStr,commentString);
        if(commentR.location != NSNotFound) validate = NO;
    }
    
    return validate;
}
//- (void)deleteBackward:(id)sender
//{
//    NSRange selectedRange = self.selectedRange;
//    NSLog(@"==delete:%@,range:%@",sender,NSStringFromRange(selectedRange));
//    
//    NSArray *temp = [NSArray arrayWithArray:self.tokenArr];
//    if (selectedRange.location!=NSNotFound) {
//        if (selectedRange.length == 0 || selectedRange.length == 1) {
//            for (LXTextAttachment *at in temp) {
//                if(at.range.location == selectedRange.location) {[self.tokenArr removeObject:at];break;}
//            }
//        }
//        else if(selectedRange.length > 0){
//            for (LXTextAttachment *at in temp) {
//                if (at.range.location==selectedRange.location || (at.range.location>selectedRange.location&&at.range.location<selectedRange.location+selectedRange.length)) {
//                    [self.tokenArr removeObject:at];
//                }
//            }
//        }
//    }
//    NSLog(@"==after delete tokenArr:%@",self.tokenArr);
//    [super deleteBackward:sender];
//}

#pragma mark -
#pragma mark NSView

/*
 
 - viewWillMoveToWindow:
 
 */
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	[super viewWillMoveToWindow:newWindow];
}

/*
 
 - viewDidMoveToWindow
 
 */
- (void)viewDidMoveToWindow
{
	if ([self window]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMainOrKey:) name:NSWindowDidBecomeKeyNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMainOrKey:) name:NSWindowDidBecomeMainNotification object:[self window]];
	}
	
	[super viewDidMoveToWindow];
}

/*
 
 - becomeFirstResponder
 
 */
- (BOOL)becomeFirstResponder
{
	[MGSFragaria setCurrentInstance:self.fragaria];
	
	return [super becomeFirstResponder];
}

#pragma mark -
#pragma mark Notification methods

/*
 
 - windowDidBecomeMainOrKey:
 
 */
- (void)windowDidBecomeMainOrKey:(NSNotification *)note
{
	#pragma unused(note)
	
	[MGSFragaria setCurrentInstance:self.fragaria];
}

/*
 
 - setLineWrap:
 
 see /developer/examples/appkit/TextSizingExample
 
 */
- (void)setLineWrap:(BOOL)value
{
    if (value == lineWrap) return;
    lineWrap = value;
    [self updateLineWrap];
}

/*
 
 - updateLineWrap
 
 see http://developer.apple.com/library/mac/#samplecode/TextSizingExample
 
 The readme file in the above example has very good info on how to configure NSTextView instances.
 */
- (void)updateLineWrap {
        
    // get control properties
	NSScrollView *textScrollView = [self enclosingScrollView];
	NSTextContainer *textContainer = [self textContainer];
    
    // content view is clipview
	NSSize contentSize = [textScrollView contentSize];
    
    if (self.lineWrap) {
        
        // setup text container
        [textContainer setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];
        [textContainer setWidthTracksTextView:YES];
        [textContainer setHeightTracksTextView:NO];
        
        // setup text view
        [self setFrameSize:contentSize];
        [self setHorizontallyResizable: NO];
        [self setVerticallyResizable: YES];
        [self setMinSize:NSMakeSize(10, contentSize.height)];
        [self setMaxSize:NSMakeSize(10, CGFLOAT_MAX)];

        // setup scroll view
        [textScrollView setHasHorizontalScroller:NO];
        [textScrollView setHasVerticalScroller:YES];
    } else {

        // setup text container
        [textContainer setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        [textContainer setWidthTracksTextView:NO];
        [textContainer setHeightTracksTextView:NO];
        
        // setup text view
        [self setFrameSize:contentSize];
        [self setHorizontallyResizable: YES];
        [self setVerticallyResizable: YES];
        [self setMinSize:contentSize];
        [self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        
        // setup scroll view
        [textScrollView setHasHorizontalScroller:YES];
        [textScrollView setHasVerticalScroller:YES];
    }
        
    
    // invalidate the glyph layout
	[[self layoutManager] textContainerChangedGeometry:textContainer];

    // redraw the line numbers
//    [[fragaria objectForKey:ro_MGSFOLineNumbers] updateLineNumbersForClipView:[[self enclosingScrollView] contentView] checkWidth:NO recolour:YES];

    // redraw the display and reposition scrollers
    NSDisableScreenUpdates();
    [textScrollView display];
    [textScrollView reflectScrolledClipView:textScrollView.contentView];
    [textScrollView display];
    NSEnableScreenUpdates();
    
}
#pragma mark - recolor
- (void)pageRecolor
{
    [[fragaria objectForKey:ro_MGSFOSyntaxColouring] pageRecolourTextView:self];
}
- (void)updateLineNumber
{
    [(LXEditScrollView*)[self enclosingScrollView] invalidateLineNumber];
}
@end
