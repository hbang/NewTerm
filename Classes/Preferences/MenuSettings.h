// MenuSettings.h
// MobileTerminal

#import <Foundation/Foundation.h>


// Settings for the menu, which is a series of commands, with a label for each.
// MenuSettings implements the NSCoding protocol so that the settings can be
// read and written to the preferences store.
@interface MenuSettings : NSObject <NSCoding> {
@private
  NSMutableArray* labels;
  NSMutableArray* commands;
}

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

// Number of menu items
- (int)count;

// The label and command
- (NSString*)itemLabelAtIndex:(int)index;
- (NSString*)itemCommandAtIndex:(int)index;

// Add a new item to the label
- (void)addItemWithLabel:(NSString*)label andCommand:(NSString*)command;

@end
