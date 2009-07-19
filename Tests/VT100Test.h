// VT100Test.h
// MobileTerminal
//
// See Also: http://developer.apple.com/documentation/developertools/Conceptual/UnitTesting/UnitTesting.html
//           file:///Developer/Library/Frameworks/SenTestingKit.framework/Resources/IntroSenTestingKit.html


#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

@class VT100;

@interface VT100Test : SenTestCase {
@private
  VT100* vt100;
}

/*
- (void) setUp;
- (void) tearDown;

- (void) testBasicInput;
- (void) testResize;
- (void) testMultipleLinesWithResizing;
- (void) testCursorPosition;
 */

@end
