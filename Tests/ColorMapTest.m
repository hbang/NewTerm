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

- (void) assertColorsEquals:(UIColor*)expectedColor got:(UIColor*)gotColor
{

  const CGFloat* expectedComponents =  CGColorGetComponents([expectedColor CGColor]);
  const CGFloat* gotComponents =  CGColorGetComponents([gotColor CGColor]);
  STAssertEqualsWithAccuracy(expectedComponents[0], gotComponents[0], 0.0001,
                             @"colors are not equal (%@, %@)",
                             expectedColor, gotColor);
  STAssertEqualsWithAccuracy(expectedComponents[1], gotComponents[1], 0.0001,
                             @"colors are not equal (%@, %@)",
                             expectedColor, gotColor);
  STAssertEqualsWithAccuracy(expectedComponents[2], gotComponents[2], 0.0001,
                             @"colors are not equal (%@, %@)",
                             expectedColor, gotColor);
  STAssertEqualsWithAccuracy(expectedComponents[3], gotComponents[3], 0.0001,
                             @"colors are not equal (%@, %@)",
                             expectedColor, gotColor);
}

- (void) testNSCoding
{
  // Initialize the color map with some non-default values
  [colorMap setForeground:[UIColor redColor]];
  [colorMap setBackground:[UIColor yellowColor]];
  [colorMap setForegroundBold:[UIColor blueColor]];
  [colorMap setForegroundCursor:[UIColor orangeColor]];
  [colorMap setBackgroundCursor:[UIColor purpleColor]];
  
  // Serialize the color map, then unserialize it and test that all of the
  // original properties were adjusted.
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:colorMap]; 
  ColorMap* newColorMap = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];

  [self assertColorsEquals:[UIColor redColor] got:[newColorMap foreground]];
  [self assertColorsEquals:[UIColor yellowColor] got:[newColorMap background]];
  [self assertColorsEquals:[UIColor blueColor] got:[newColorMap foregroundBold]];
  [self assertColorsEquals:[UIColor orangeColor] got:[newColorMap foregroundCursor]];
  [self assertColorsEquals:[UIColor purpleColor] got:[newColorMap backgroundCursor]];
  
  [newColorMap release];  
  newColorMap = nil;
}

@end
