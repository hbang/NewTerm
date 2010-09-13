// UITextInputBase.h
// MobileTerminal
//
// This file contains a base view for implementing keyboard handling routines
// via the UITextInput protocol.  That protocol is a grab bag of other protocols
// that are mostly unused by the terminal keyboard handling code.

#import <UIKit/UIKit.h>

@interface TextPosition : UITextPosition
{
@private
  NSNumber* position;
}
@property (nonatomic, retain) NSNumber* position;
@end

@interface UITextInputBase : UIView <UITextInput> {
@private
  UITextRange *selectedTextRange;
  UITextRange *markedTextRange;
  NSDictionary *markedTextStyle;
  UITextPosition *beginningOfDocument;
  UITextPosition *endOfDocument;
  id <UITextInputDelegate> inputDelegate;
  id <UITextInputTokenizer> tokenizer;
  UIView *textInputView;
  UITextStorageDirection selectionAffinity;  
}

// UIKeyInput
- (BOOL)hasText;
- (void)insertText:(NSString *)text;
- (void)deleteBackward;


/* Methods for manipulating text. */
- (NSString *)textInRange:(UITextRange *)range;
- (void)replaceRange:(UITextRange *)range withText:(NSString *)text;

/* Text may have a selection, either zero-length (a caret) or ranged.  Editing operations are
 * always performed on the text from this selection.  nil corresponds to no selection. */

@property (readwrite, copy) UITextRange *selectedTextRange;

/* If text can be selected, it can be marked. Marked text represents provisionally
 * inserted text that has yet to be confirmed by the user.  It requires unique visual
 * treatment in its display.  If there is any marked text, the selection, whether a
 * caret or an extended range, always resides witihin.
 *
 * Setting marked text either replaces the existing marked text or, if none is present,
 * inserts it from the current selection. */ 

@property (nonatomic, readonly) UITextRange *markedTextRange;                       // Nil if no marked text.
@property (nonatomic, copy) NSDictionary *markedTextStyle;                          // Describes how the marked text should be drawn.
- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange;  // selectedRange is a range within the markedText
- (void)unmarkText;

/* The end and beginning of the the text document. */
@property (nonatomic, readonly) UITextPosition *beginningOfDocument;
@property (nonatomic, readonly) UITextPosition *endOfDocument;

/* Methods for creating ranges and positions. */
- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition;
- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset;
- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset;

/* Simple evaluation of positions */
- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other;
- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition;

/* A system-provied input delegate is assigned when the system is interested in input changes. */
@property (nonatomic, assign) id <UITextInputDelegate> inputDelegate;

/* A tokenizer must be provided to inform the text input system about text units of varying granularity. */
@property (nonatomic, readonly) id <UITextInputTokenizer> tokenizer;

/* Layout questions. */
- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction;
- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction;

/* Writing direction */
- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction;
- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range;

/* Geometry used to provide, for example, a correction rect. */
- (CGRect)firstRectForRange:(UITextRange *)range;
- (CGRect)caretRectForPosition:(UITextPosition *)position;

/* Hit testing. */
- (UITextPosition *)closestPositionToPoint:(CGPoint)point;
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range;
- (UITextRange *)characterRangeAtPoint:(CGPoint)point;

/* Text styling information can affect, for example, the appearance of a correction rect. */
- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction;

/* To be implemented if there is not a one-to-one correspondence between text positions within range and character offsets into the associated string. */
- (UITextPosition *)positionWithinRange:(UITextRange *)range atCharacterOffset:(NSInteger)offset;
- (NSInteger)characterOffsetOfPosition:(UITextPosition *)position withinRange:(UITextRange *)range;

/* An affiliated view that provides a coordinate system for all geometric values in this protocol.
 * If unimplmeented, the first view in the responder chain will be selected. */
@property (nonatomic, readonly) UIView *textInputView;

/* Selection affinity determines whether, for example, the insertion point appears after the last
 * character on a line or before the first character on the following line in cases where text
 * wraps across line boundaries. */
@property (nonatomic) UITextStorageDirection selectionAffinity;  

@end
