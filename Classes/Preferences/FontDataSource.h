// FontDataSource.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// FontDataSource is the delegate for the font picker that provides the list of
// fonts to display on screen.
@interface FontDataSource : NSObject <UIPickerViewDelegate> {
@private
  NSMutableArray *fontNames;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component;


@end
