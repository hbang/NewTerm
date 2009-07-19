// ColorMapTest.m
// MobileTerminal

#import "ColorMapTest.h"
#import "ColorMap.h"

@implementation ColorMapTest


- (void) setUp
{
  colorMap = [[ColorMap alloc] init];
}

- (void) tearDown
{
  [colorMap release];
}

- (void) testBlack
{
  UIColor* color = [colorMap color:0];
  STAssertTrue(4 == CGColorGetNumberOfComponents([color CGColor]),
                 @"Color match failed");
  const CGFloat* components =  CGColorGetComponents([color CGColor]);
  STAssertEqualsWithAccuracy(0.0f, components[0], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[0]);
  STAssertEqualsWithAccuracy(0.0f, components[1], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[1]);
  STAssertEqualsWithAccuracy(0.0f, components[2], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[2]);
  STAssertEqualsWithAccuracy(1.0f, components[3], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[3]);
}

- (void) testWhite
{
  UIColor* color = [colorMap color:0xff];
  STAssertTrue(4 == CGColorGetNumberOfComponents([color CGColor]),
               @"Color match failed");
  const CGFloat* components =  CGColorGetComponents([color CGColor]);
  STAssertEqualsWithAccuracy(1.0f, components[0], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[0]);
  STAssertEqualsWithAccuracy(1.0f, components[1], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[1]);
  STAssertEqualsWithAccuracy(1.0f, components[2], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[2]);
  STAssertEqualsWithAccuracy(0.95f, components[3], 0.0001,
                             @"colors are not equal, 0.0 != %f", components[3]);
}

@end
