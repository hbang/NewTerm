// UITextInputBase.m
// MobileTerminal

#import "UITextInputBase.h"

@implementation TextPosition
@synthesize position;
@end

@implementation UITextInputBase

@synthesize selectedTextRange;
@synthesize markedTextRange;
@synthesize markedTextStyle;
@synthesize beginningOfDocument;
@synthesize endOfDocument;
@synthesize textInputView;
@synthesize selectionAffinity;  
@synthesize inputDelegate;
@synthesize tokenizer;

- (BOOL)hasText
{
  return NO;
}

- (void)insertText:(NSString *)text
{
  
}

- (void)deleteBackward
{
  
}

- (NSString *)textInRange:(UITextRange *)range
{
  return nil;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text
{
  
}


- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{

}

- (void)unmarkText
{
}

/* Methods for creating ranges and positions. */
- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition
{
  return nil;
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset
{
  return nil;
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
  return nil;
}

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other
{
  TextPosition* p = (TextPosition*) position;
  TextPosition* o = (TextPosition*) other;
  return [[p position] compare: [o position]];
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition
{
  return 0;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction
{
  return nil;
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
  return nil;
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
  return UITextWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range
{
}

- (CGRect)firstRectForRange:(UITextRange *)range
{
  return CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
  return CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
  TextPosition* pos = [[[TextPosition alloc] init] autorelease];
  pos.position = [NSNumber numberWithInt:point.x];
  return pos;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range
{
  TextPosition* pos = [[[TextPosition alloc] init] autorelease];
  pos.position = [NSNumber numberWithInt:point.x];
  return pos;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
  return nil;
}

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
  return nil;
}

/* To be implemented if there is not a one-to-one correspondence between text positions within range and character offsets into the associated string. */
- (UITextPosition *)positionWithinRange:(UITextRange *)range atCharacterOffset:(NSInteger)offset
{
  return nil;
}

- (NSInteger)characterOffsetOfPosition:(UITextPosition *)position withinRange:(UITextRange *)range
{
  return 0;
}

@end
