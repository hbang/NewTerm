// UITextInputBase.m
// MobileTerminal

#import "TextInputBase.h"

@implementation TextPosition

@end

@implementation TextInputBase

- (BOOL)hasText {
	return NO;
}

- (void)insertText:(NSString *)text {}

- (void)deleteBackward {}

- (NSString *)textInRange:(UITextRange *)range {
	return nil;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange {}

- (void)unmarkText {}

/* Methods for creating ranges and positions. */
- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {
	return nil;
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset {
	return nil;
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
	return nil;
}

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other {
	return [((TextPosition *)position).position compare:((TextPosition *)other).position];
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition {
	return 0;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
	return nil;
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction {
	return nil;
}

- (NSWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
	return NSWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(NSWritingDirection)writingDirection forRange:(UITextRange *)range {}

- (CGRect)firstRectForRange:(UITextRange *)range {
	return CGRectZero;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
	return CGRectZero;
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range {
	return nil;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
	TextPosition *position = [[TextPosition alloc] init];
	position.position = @(point.x);
	return position;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range {
	TextPosition *position = [[TextPosition alloc] init];
	position.position = @(point.x);
	return position;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point {
	return nil;
}

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
	return nil;
}

/* To be implemented if there is not a one-to-one correspondence between text positions within range and character offsets into the associated string. */
- (UITextPosition *)positionWithinRange:(UITextRange *)range atCharacterOffset:(NSInteger)offset {
	return nil;
}

- (NSInteger)characterOffsetOfPosition:(UITextPosition *)position withinRange:(UITextRange *)range {
	return 0;
}

@end
