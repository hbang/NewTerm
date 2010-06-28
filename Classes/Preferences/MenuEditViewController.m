// MenuItemEditor.m
// MobileTerminal

#import "MenuEditViewController.h"

#import "MenuSettings.h"

@implementation MenuEditViewController

@synthesize menuEditDelegate;
@synthesize editingMenuItem;
@synthesize labelTextField;
@synthesize commandTextView;

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
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  labelTextField.text = editingMenuItem.label;
  // TODO(allen): This currently does not handle control character conversion
  // like when you press the dot key on the keyboard.
  commandTextView.text = editingMenuItem.command;
}

- (void)cancelEditing:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)finishEditing:(id)sender
{
  editingMenuItem.label = labelTextField.text;
  editingMenuItem.command = commandTextView.text;  
  [self.navigationController popViewControllerAnimated:YES];
  [menuEditDelegate finishEditing:self];
}

@end
