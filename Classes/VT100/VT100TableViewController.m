// VT100TableViewController.m
// MobileTerminal

#import "VT100TableViewController.h"

#import "ColorMap.h"
#import "FontMetrics.h"
#import "VT100.h"
#import "VT100RowView.h"
#import "VT100Types.h"
#import "VT100StringSupplier.h"
#import "TerminalController.h"

@interface VT100TableViewController	() <ScreenBufferRefreshDelegate>

@end

@implementation VT100TableViewController

- (void)loadView {
	[super loadView];
	
	_buffer = [[VT100 alloc] init];
	_buffer.refreshDelegate = self;
	_colorMap = [[ColorMap alloc] init];
	_fontMetrics = [[FontMetrics alloc] initWithFont:[UIFont systemFontOfSize:14.f]];
	
	_stringSupplier = [[VT100StringSupplier alloc] init];
	((VT100StringSupplier *)_stringSupplier).colorMap = _colorMap;
	((VT100StringSupplier *)_stringSupplier).screenBuffer = _buffer;
	
	self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	self.tableView.backgroundColor = _colorMap.background;
	self.tableView.allowsSelection = NO;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.rowHeight = [_fontMetrics boundingBox].height;
	
	[self clearSelection];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	
	CGSize glyphSize = [_fontMetrics boundingBox];
	
	// Determine the screen size based on the font size
	CGSize frameSize = self.tableView.frame.size;
	CGFloat height = frameSize.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom;
	
	ScreenSize size;
	size.width = (int)(frameSize.width / glyphSize.width);
	size.height = (int)(height / glyphSize.height);
	// The font size should not be too small that it overflows the glyph buffers.
	// It is not worth the effort to fail gracefully (increasing the buffer size would
	// be better).
	NSParameterAssert(size.width < kMaxRowBufferSize);
	[_buffer setScreenSize:size];
}

- (void)dealloc {
	[_colorMap release];
	[super dealloc];
}

// Computes the size of a single row
- (CGRect)cellFrame {
	return CGRectMake(0, 0, self.tableView.frame.size.width, _fontMetrics.boundingBox.height);
}
	
- (void)scrollToBottomAnimated:(BOOL)animated {
	CGPoint offset = self.tableView.contentOffset;
	offset.y = _buffer.scrollbackLines == 0 ? 0 : self.tableView.contentInset.top + self.tableView.contentInset.bottom + self.tableView.contentSize.height - self.tableView.frame.size.height;
	
	if (animated) {
		[UIView animateWithDuration:animated ? 0.2f : 0 animations:^{
			self.tableView.contentOffset = offset;
		}];
	} else {
		self.tableView.contentOffset = offset;
	}
}
	
- (void)refresh {
	UITableView *tableView = [self tableView];
	[tableView reloadData];
	[tableView setNeedsDisplay];
	// Scrolling to the bottom with animations looks much nicer, but will not
	// work if the table cells have not finished loading yet.
	[self scrollToBottomAnimated:YES];
}
	
- (void)setFont:(UIFont *)font {
	[_fontMetrics release];
	_fontMetrics = [[FontMetrics alloc] initWithFont:font];
	
	self.tableView.rowHeight = _fontMetrics.boundingBox.height;
	[self refresh];
}
	
- (int)adjacentCharactersWithSameColor:(screen_char_t*)data withSize:(int)length {
	int i = 1;
	for (i = 1; i < length; ++i) {
		if (data[0].fg_color != data[i].fg_color) {
			break;
		}
	}
	return i;
}

- (ScreenPosition)positionFromPoint:(CGPoint)point {
	CGSize glyphSize = [_fontMetrics boundingBox];
	
	ScreenPosition pos;
	pos.x = point.x / glyphSize.width;
	pos.y = (point.y - (glyphSize.height / 2)) / glyphSize.height;
	return pos;
}

- (void)readInputStream:(NSData *)data {
	// Simply forward the input stream down the VT100 processor.	When it notices
	// changes to the screen, it should invoke our refresh delegate below.
	[_buffer readInputStream:data];
}

- (void)clearScreen {
	[_buffer clearScreen];
}

#pragma mark - Selection

- (void)clearSelection {
	[_buffer clearSelection];
	[self refresh];
}

- (void)setSelectionStart:(CGPoint)point {
	[_buffer setSelectionStart:[self positionFromPoint:point]];
}

- (void)setSelectionEnd:(CGPoint)point {
	[_buffer setSelectionEnd:[self positionFromPoint:point]];
	[self refresh];
}
	
- (void)fillDataWithSelection:(NSMutableData *)data {
	NSMutableString *s = [[NSMutableString alloc] initWithString:@""];
	
	ScreenPosition startPos = [_buffer selectionStart];
	ScreenPosition endPos = [_buffer selectionEnd];
	if (startPos.x >= endPos.x &&
		startPos.y >= endPos.y) {
		ScreenPosition tmp = startPos;
		startPos = endPos;
		endPos = tmp;
	}
	
	int currentY = startPos.y;
	int maxX = [self width];
	while (currentY <= endPos.y) {
		int startX = (currentY == startPos.y) ? startPos.x : 0;
		int endX = (currentY == endPos.y) ? endPos.x : maxX;
		int width = endX - startX;
		if (width > 0) {
			screen_char_t *row = [_buffer bufferForRow:currentY];
			screen_char_t *col = &row[startX];
			unichar buf[kMaxRowBufferSize];
			for (int i = 0; i < width; ++i) {
				if (col->ch == '\0') {
					buf[i] = ' ';
				} else {
					buf[i] = col->ch;
				}
				++col;
			}
			[s appendString:[NSString stringWithCharacters:buf length:width]];
		}
		++currentY;
	}
	[data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
	[s release];
}
	
- (BOOL)hasSelection {
	return [_buffer hasSelection];
}

#pragma mark - Calculations
	
- (int)width {
	return _buffer.screenSize.width;
}
	
- (int)height {
	return _buffer.screenSize.height;
}
	
- (CGRect)scaleRect:(CGRect)rect {
	CGSize glyphSize = [_fontMetrics boundingBox];
	rect.origin.x *= glyphSize.width;
	rect.origin.y *= glyphSize.height;
	rect.size.width *= glyphSize.width;
	rect.size.height *= glyphSize.height;
	return rect;
}
	
- (CGRect)cursorRegion {
	ScreenPosition cursorPosition = [_buffer cursorPosition];
	CGRect rect = CGRectMake(cursorPosition.x, cursorPosition.y, 1, 1);
	return [self scaleRect:rect];
}
	
- (CGRect)selectionRegion {
	ScreenPosition selectionStart = [_buffer selectionStart];
	ScreenPosition selectionEnd = [_buffer selectionEnd];
	CGRect rect;
	if (selectionStart.x >= selectionEnd.x &&
		selectionStart.y >= selectionEnd.y) {
		rect = CGRectMake(selectionEnd.x,
						  selectionEnd.y,
						  selectionStart.x - selectionEnd.x,
						  selectionStart.y - selectionEnd.y);
	} else {
		rect = CGRectMake(selectionStart.x,
						  selectionStart.y,
						  selectionEnd.x - selectionStart.x,
						  selectionEnd.y - selectionStart.y);
	}
	return [self scaleRect:rect];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_stringSupplier rowCount];
}

- (UITableViewCell *)tableViewCell:(UITableView *)tableView {
	static NSString * kCellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier] autorelease];
		VT100RowView *rowView = [[VT100RowView alloc] initWithFrame:[self cellFrame]];
		rowView.stringSupplier = _stringSupplier;
		[cell.contentView addSubview:rowView];
		[rowView release];
	}
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSAssert(_fontMetrics != nil, @"fontMetrics not initialized");
	NSAssert(_stringSupplier != nil, @"stringSupplier not initialized");
		
	// Ignore position 0 since it should always be 0.	 The row number here is not
	// just the row on the screen -- it also includes rows in the scrollback
	// buffer.
	NSAssert([indexPath indexAtPosition:0] == 0, @"Invalid index");
	NSUInteger tableRow = [indexPath indexAtPosition:1];
	NSAssert(tableRow < [_stringSupplier rowCount], @"Invalid table row index");
	
	// This table has a single type of row that represents a line of text.	The
	// actual row object is configured once, but the text is replaced every time
	// we return a new cell object.
	UITableViewCell *cell = [self tableViewCell:tableView];
	// Update the line of text (via row number) associated with this cell
	NSArray *subviews = [cell.contentView subviews];
	NSAssert([subviews count] == 1, @"Invalid contentView size");
	VT100RowView *rowView = [subviews objectAtIndex:0];
	rowView.rowIndex = tableRow;
	rowView.fontMetrics = _fontMetrics;
	// resize the row in case the table has changed size
	cell.frame = [self cellFrame];
	rowView.frame = [self cellFrame];	 
	[cell setNeedsDisplay];
	[rowView setNeedsDisplay];
	return cell;	
}

@end

