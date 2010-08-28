// GestureSettings.h
// MobileTerminal

#import "GestureSettings.h"
#import "Settings.h"

NSString* kGestureSingleDoubleTap = @"Double Tap";
NSString* kGestureDoubleDoubleTap = @"Two Finger Double Tap";
NSString* kGestureSwipeUp = @"Swipe Up";
NSString* kGestureSwipeDown = @"Swipe Down";
NSString* kGestureSwipeLeft = @"Swipe Left";
NSString* kGestureSwipeRight = @"Swipe Right";
NSString* kGestureSwipeLeftUp = @"Swipe Up and Left";
NSString* kGestureSwipeLeftDown = @"Swipe Down and Left";
NSString* kGestureSwipeRightUp = @"Swipe Up and Right";
NSString* kGestureSwipeRightDown = @"Swipe Down and Right";

@interface NoneGestureAction : NSObject<GestureAction> {
}
- (NSString*)label;
- (void)performAction;
@end

@implementation NoneGestureAction

static NoneGestureAction* noneInstance;

+ (NoneGestureAction*)getInstance
{
  if (noneInstance == nil) {
    noneInstance = [[NoneGestureAction alloc] init];
  }
  return noneInstance;
}

- (NSString*)label
{
  return @"<Unassigned>";
}

- (void)performAction
{
  // Do nothing  
}

@end


@implementation SelectorGestureAction

- (id)initWithTarget:(id)aTarget action:(SEL)anAction label:(NSString*)aLabel;
{
  self = [super init];
  if (self != nil) {
    label = aLabel;
    target = aTarget;
    action = anAction;
  }
  return self;
}

- (NSString*)label
{
  return label;
}

- (void)performAction
{
  [target performSelector:action];
}

@end

@implementation GestureItem

@synthesize name;
@synthesize actionLabel;

- (id)initWithName:(NSString*)aName
{
  self = [super init];
  if (self != nil) {
    name = aName;
    actionLabel = [[NoneGestureAction getInstance] label];
  }
  return self;
}

@end


@implementation GestureSettings

- (id) init
{
  return [self initWithCoder:nil];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self != nil) {
    gestureItems = [[NSMutableArray alloc] init];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSingleDoubleTap]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureDoubleDoubleTap]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeUp]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeDown]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeLeft]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeRight]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeLeftUp]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeLeftDown]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeRightUp]];
    [gestureItems addObject:[[GestureItem alloc] initWithName:kGestureSwipeRightDown]];
    // This may load actions that are no longer valid.  Deal with that at
    // run time.
    for (int i = 0; i < [self gestureItemCount]; ++i) {
      GestureItem* item = [self gestureItemAtIndex: i];
      if ([decoder containsValueForKey:[item name]]) {
        item.actionLabel = [decoder decodeObjectForKey:[item name]];
      } else {
        item.actionLabel = [[NoneGestureAction getInstance] label];
      }
    }
    gestureActions = [[NSMutableArray alloc] init];
    [gestureActions addObject:[[NoneGestureAction alloc] init]];
  }
  return self;
}

- (void) dealloc
{
  [gestureItems release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  for (int i = 0; i < [self gestureItemCount]; ++i) {
    GestureItem* item = [self gestureItemAtIndex: i];
    [encoder encodeObject:[item actionLabel] forKey:[item name]];
  }
}

- (int)gestureItemCount
{
  return [gestureItems count];
}

- (GestureItem*)gestureItemAtIndex:(int)index
{
  return [gestureItems objectAtIndex:index];
}

- (GestureItem*)gestureItemForName:(NSString*)name;
{
  // Simply do a linear walk of these items.  Given there are only a limited
  // number of gestures this shouldn't be too inefficient.
  for (int i = 0; i < [self gestureItemCount]; ++i) {
    GestureItem* item = [self gestureItemAtIndex: i];
    if ([[item name] isEqualToString:name]) {
      return item;
    }
  }
  return NULL;
}

- (int)gestureActionCount
{
  return [gestureActions count];
}

- (id<GestureAction>)gestureActionAtIndex:(int)index
{
  return [gestureActions objectAtIndex:index];
}

- (void)addGestureAction:(id<GestureAction>)action
{
  [gestureActions addObject:action];
}

- (id<GestureAction>)gestureActionForLabel:(NSString*)label
{
  // Simply do a linear walk of these items.  Given there are only a limited
  // number of gestures this shouldn't be too inefficient.
  for (int i = 0; i < [self gestureActionCount]; ++i) {
    id<GestureAction> action = [self gestureActionAtIndex: i];
    if ([[action label] isEqualToString:label]) {
      return action;
    }
  }
  return [NoneGestureAction getInstance];
}

- (id<GestureAction>)gestureActionForItemName:(NSString*)name
{
  GestureItem* item = [self gestureItemForName:name];
  return [self gestureActionForLabel:[item actionLabel]];
}

@end
