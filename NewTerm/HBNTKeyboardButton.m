#import "HBNTKeyboardButton.h"

@implementation HBNTKeyboardButton

+ (instancetype)buttonWithTitle:(NSString *)title {
	HBNTKeyboardButton *button = [[self alloc] initWithFrame:CGRectZero];
	[button setTitle:title forState:UIControlStateNormal];
	return button;
}

+ (instancetype)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
	HBNTKeyboardButton *button = [[self alloc] initWithFrame:CGRectZero];
	[button setTitle:title forState:UIControlStateNormal];
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	return button;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
 
	if (self) {
		self.titleLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 18.f : 15.f];
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[self setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
		[self setBackgroundImage:[self _imageWithColor:[UIColor colorWithWhite:0.3529411765f alpha:1]] forState:UIControlStateNormal];
		[self setBackgroundImage:[self _imageWithColor:[UIColor colorWithWhite:0.2078431373f alpha:1]] forState:UIControlStateHighlighted];
		[self setBackgroundImage:[self _imageWithColor:[UIColor colorWithWhite:0.6784313725f alpha:1]] forState:UIControlStateSelected];
		self.layer.cornerRadius = IS_IPAD ? 6.f : 4.f;
		self.clipsToBounds = YES;
	}
 
	return self;
}

- (CGSize)intrinsicContentSize {
	return CGSizeMake(IS_IPAD ? 79.f : 44.f, IS_IPAD ? 40.f : UIViewNoIntrinsicMetric);
}
 
- (UIImage *)_imageWithColor:(UIColor *)color {
	// https://stackoverflow.com/a/14525049/709376
	CGRect rect = CGRectMake(0, 0, 1.f, 1.f);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextFillRect(context, rect);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}
 
@end
