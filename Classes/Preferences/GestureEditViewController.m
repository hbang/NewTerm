// GestureEditViewController.m
// MobileTerminal

#import "GestureEditViewController.h"
#import "Settings.h"

@implementation GestureEditViewController

@synthesize gestureLabel;
@synthesize actionPicker;
@synthesize editingGestureItem;
@synthesize gestureEditDelegate;

- (void)awakeFromNib
{
  [super awakeFromNib];
  
  UIBarButtonItem *cancelButtonItem =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing:)];
  self.navigationItem.leftBarButtonItem = cancelButtonItem;
  [cancelButtonItem release];
  
  UIBarButtonItem *doneButtonItem =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishEditing:)];
  self.navigationItem.rightBarButtonItem = doneButtonItem;
  [doneButtonItem release];
  
  settings = [[Settings sharedInstance] gestureSettings];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  gestureLabel.text = editingGestureItem.name;
  selectedRow = 0;
  for (int i = 0; i < [settings gestureActionCount]; ++i) {
    id<GestureAction> action = [settings gestureActionAtIndex:i];
    if ([editingGestureItem actionLabel] == [action label]) {
      selectedRow = i;
      break;
    }
  }
  [actionPicker selectRow:selectedRow inComponent:0 animated:NO];  
}

- (void)cancelEditing:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)finishEditing:(id)sender
{
  id<GestureAction> action = [settings gestureActionAtIndex:selectedRow];
  editingGestureItem.actionLabel = action.label;
  [self.navigationController popViewControllerAnimated:YES];
  [gestureEditDelegate finishEditing:self];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
  selectedRow = row;
}

- (NSInteger)selectedRowInComponent:(NSInteger)component
{
  return selectedRow;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
  return [settings gestureActionCount];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
  id<GestureAction> action = [settings gestureActionAtIndex:row];
  return [action label];
}

@end
