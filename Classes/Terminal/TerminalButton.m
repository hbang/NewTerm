//
//  TerminalButton.m
//  MobileTerminal
//
//  Created by Adam D on 27/11/2013.
//
//

#import "TerminalButton.h"

@interface UIImage (Private)

+ (UIImage *)kitImageNamed:(NSString *)name;

@end

@interface TerminalButton () {
	UIImageView *_selectedImageView;
}

@end

@implementation TerminalButton

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		if (YES/* || IS_IOS_7*/) {
			[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			[self setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
			[self setBackgroundImage:[self _imageWithColor:[UIColor colorWithWhite:0.3529411765f alpha:1]] forState:UIControlStateNormal];
			[self setBackgroundImage:[self _imageWithColor:[UIColor colorWithWhite:0.2078431373f alpha:1]] forState:UIControlStateHighlighted];
			[self setBackgroundImage:[self _imageWithColor:[UIColor colorWithWhite:0.6784313725f alpha:1]] forState:UIControlStateSelected];
			self.layer.cornerRadius = 6.f;
			self.clipsToBounds = YES;
		} else {
			_selectedImageView = [[UIImageView alloc] initWithImage:[UIImage kitImageNamed:@"kb-shift-halo.png"]];
			_selectedImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
			_selectedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			_selectedImageView.userInteractionEnabled = NO;
			_selectedImageView.hidden = YES;
			[self insertSubview:_selectedImageView atIndex:0];
		}
	}

	return self;
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	
	_selectedImageView.hidden = !selected;
}

// http://stackoverflow.com/a/14525049/709376
- (UIImage *)_imageWithColor:(UIColor *)color {
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
