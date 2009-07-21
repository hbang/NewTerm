// FontDataSource.m
// MobileTerminal

#import "FontDataSource.h"


@implementation FontDataSource

- (id) init
{
  self = [super init];
  if (self != nil) {
    fontNames = [[NSMutableArray alloc] init];
    NSArray *familyNames = [UIFont familyNames];
    for (NSString *name in familyNames) {
      [fontNames addObjectsFromArray:[UIFont fontNamesForFamilyName:name]];
    }
    [fontNames sortUsingSelector:@selector(compare:)];
  }
  return self;
}

- (void) dealloc
{
  for (NSString *name in fontNames) {
    [name release];
  }
  [fontNames release];
  [super dealloc];
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
  return [fontNames objectAtIndex:row];
}

@end
