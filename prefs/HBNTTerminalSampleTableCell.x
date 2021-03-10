#import "HBNTTerminalSampleTableCell.h"

@interface VT100ColorMap : NSObject
@property (nonatomic, strong) UIColor *background;
@end

@interface Preferences : NSObject
+ (instancetype)shared;
+ (NSNotificationName)didChangeNotification;
- (VT100ColorMap *)colorMap;
@end

@interface TerminalSampleView : UIView

@end

@implementation HBNTTerminalSampleTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.textLabel.hidden = YES;
		self.selectedBackgroundView = [[UIView alloc] init];
		
		TerminalSampleView *sampleView = [[%c(TerminalSampleView) alloc] initWithFrame:self.contentView.bounds];
		sampleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		sampleView.userInteractionEnabled = NO;
		[self.contentView addSubview:sampleView];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdated) name:[%c(Preferences) didChangeNotification] object:nil];
		[self preferencesUpdated];
	}

	return self;
}

- (void)preferencesUpdated {
	Preferences *preferences = [%c(Preferences) shared];
	self.backgroundColor = preferences.colorMap.background;
}

@end
