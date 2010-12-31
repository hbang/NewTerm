// MenuSettings.h
// MobileTerminal

#import <Foundation/Foundation.h>


// A single item in the menu
@interface MenuItem : NSObject <NSCoding> {
@private
  NSString* label;
  NSString* command;
}

+ (MenuItem*)newItemWithLabel:(NSString*)label andCommand:(NSString*)command;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@property(nonatomic, retain) NSString* label;
@property(nonatomic, retain) NSString* command;

@end


// Settings for the menu, which is a series of commands, with a label for each.
// MenuSettings implements the NSCoding protocol so that the settings can be
// read and written to the preferences store.
@interface MenuSettings : NSObject <NSCoding> {
@private
  NSMutableArray* menuItems;
}

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

// Number of menu items
- (int)menuItemCount;

// The label and command
- (MenuItem*)menuItemAtIndex:(int)index;

// Add a new item to the label
- (void)addMenuItem:(MenuItem*)menuItem;

// Remove the specified item
- (void)removeMenuItemAtIndex:(int)index;

@end
