// ColorMapTest.h
// MobileTerminal

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

@class ColorMap;

@interface ColorMapTest : SenTestCase {
@private
  ColorMap* colorMap;
}

- (void) setUp;
- (void) tearDown;
- (void) testNSCoding;

@end
