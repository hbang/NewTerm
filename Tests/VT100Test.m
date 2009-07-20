// VT100Test.m
// MobileTerminal

#import "VT100Test.h"

#import "VT100.h"

@implementation VT100Test

- (void) setUp {
  ScreenSize size;
  size.width = 80;
  size.height = 25;
  vt100 = [[VT100 alloc] init];
  [vt100 setScreenSize:size];
}

- (void) tearDown {
  [vt100 release];
}

- (void) testMinSize
{
  // Set a 1x1 screen.  As soon as a character is inserted on to the screen, we
  // wrap and scroll down to the next line.
  ScreenSize size = [vt100 screenSize];
  size.width = 1;
  size.height = 1;
  [vt100 setScreenSize:size];

  screen_char_t* buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == '\0', @"expected NULL, got '%c'", buffer[0].ch);

  for (int i = 0; i < 10; i++) {
    char c = 'a' + i;
    [vt100 readInputStream:&c withLength:1];
    buffer = [vt100 bufferForRow:0];
    STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
  }
  
  [vt100 readInputStream:"abc" withLength:3];
  buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
}

- (void) testOneColTwoRows
{
  // Set a 1x2 screen.  As soon as a character is inserted on to the screen, we
  // wrap and scroll down to the next line.
  ScreenSize size = [vt100 screenSize];
  size.width = 1;
  size.height = 2;
  [vt100 setScreenSize:size];
  
  screen_char_t* buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == '\0', @"expected NULL, got '%c'", buffer[0].ch);
  
  for (int i = 0; i < 10; i++) {
    char c = 'a' + i;
   [vt100 readInputStream:&c withLength:1];
    buffer = [vt100 bufferForRow:0];
    STAssertTrue(buffer[0].ch == c, @"got '%c' ('%c')", buffer[0].ch, c);
    buffer = [vt100 bufferForRow:1];
    STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
  }
  
  [vt100 readInputStream:"xyz" withLength:3];
  buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == 'z', @"got '%c'", buffer[0].ch);
  buffer = [vt100 bufferForRow:1];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
}


- (void) testTwoColsOneRow
{
  // Set a 1x1 screen.  As soon as a character is inserted on to the screen, we
  // wrap and scroll down to the next line.
  ScreenSize size = [vt100 screenSize];
  size.width = 2;
  size.height = 1;
  [vt100 setScreenSize:size];
  
  screen_char_t* buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == '\0', @"expected NULL, got '%c'", buffer[0].ch);
  STAssertTrue(buffer[1].ch == '\0', @"expected NULL, got '%c'", buffer[0].ch);
  
  char c = 'a';
  [vt100 readInputStream:&c withLength:1];
  buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == 'a', @"got '%c'", buffer[0].ch);
  STAssertTrue(buffer[1].ch == '\0', @"got '%c'", buffer[1].ch);

  c = 'b';
  [vt100 readInputStream:&c withLength:1];
  buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
  STAssertTrue(buffer[1].ch == '\0', @"got '%c'", buffer[1].ch);

  c = 'c';
  [vt100 readInputStream:&c withLength:1];
  buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == 'c', @"got '%c'", buffer[0].ch);
  STAssertTrue(buffer[1].ch == '\0', @"got '%c'", buffer[1].ch);
  
  [vt100 readInputStream:"wxyz" withLength:4];
  buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == 'z', @"got '%c'", buffer[0].ch);
  STAssertTrue(buffer[1].ch == '\0', @"got '%c'", buffer[1].ch);
}

// Tests a basic case where a few leters are inserted into the terminals 
// input stream and read back
- (void) testBasicInput
{
  const char* text = "abc";
  [vt100 readInputStream:text withLength:strlen(text)];

  screen_char_t* buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == 'a', @"got '%c'", buffer[0].ch);
  STAssertTrue(buffer[1].ch == 'b', @"got '%c'", buffer[0].ch);
  STAssertTrue(buffer[2].ch == 'c', @"got '%c'", buffer[0].ch);
  STAssertTrue(buffer[3].ch == '\0', @"got '%c'", buffer[0].ch);
}

// Tests basic window resizing
- (void) testResize
{
  ScreenSize size = [vt100 screenSize];
  STAssertEquals(80, size.width, @"expected 80, got %d", size.width);
  STAssertEquals(25, size.height, @"expected 25, got %d", size.height);
  
  // Change the size of the screen
  size.width = 40;
  size.height = 20;
  [vt100 setScreenSize:size];
  
  // Verify that the size has been changed
  size = [vt100 screenSize];
  STAssertEquals(40, size.width, @"expected 40, got %d", size.width);
  STAssertEquals(20, size.height, @"expected 20, got %d", size.height);
}

static const int kLargeBufferSize = 8 * 1024;

// Tests the case where we input data into the terminal, then resize the
// window.  This causes some of the strings to change position.
- (void) testMultipleLinesWithResizing
{
  char data[kLargeBufferSize];
  
  // First row is entirely a's
  int i = 0;
  for (int j = 0; j < 79; ++j) {
    data[i++] = 'a';
  }
  data[i++] = '\r';
  data[i++] = '\n';
  // Second row is entirely b's
  for (int j = 0; j < 79; ++j) {
    data[i++] = 'b';
  }
  data[i++] = '\r';
  data[i++] = '\n';
  // Single c on the third row
  data[i++] = 'c';
  data[i++] = '\0';
  [vt100 readInputStream:data withLength:strlen(data)];
    
  // Verify the each row looks correct
  screen_char_t* buffer = [vt100 bufferForRow:0];
  for (int j = 0; j < 79; j++) {
    STAssertTrue('a' == buffer[j].ch, @"got '%c'", buffer[j].ch);
  }
  STAssertTrue('\0' == buffer[79].ch, @"got '%c'", buffer[79].ch);
  buffer = [vt100 bufferForRow:1];
  for (int j = 0; j < 79; j++) {
    STAssertTrue('b' == buffer[j].ch, @"got '%c'", buffer[j].ch);
  }
  STAssertTrue('\0' == buffer[79].ch, @"got '%c'", buffer[79].ch);
  buffer = [vt100 bufferForRow:2];
  STAssertTrue('c' == buffer[0].ch, @"got '%c'", buffer[0].ch);
  STAssertTrue('\0' == buffer[1].ch, @"got '%c'", buffer[1].ch);
  

  // Change the size of the screen, which causes the terminal to move
  // everything.
  ScreenSize size = [vt100 screenSize];
  size.width = 40;
  size.height = 25;
  [vt100 setScreenSize:size];
  
  // Now the first two (shorter) rows are a's
  buffer = [vt100 bufferForRow:0];
  for (int j = 0; j < 40; j++) {
    STAssertTrue('a' == buffer[j].ch, @"buffer[%d] was '%c'", j, buffer[j].ch);
  }
  buffer = [vt100 bufferForRow:1];
  for (int j = 0; j < 39; j++) {
    STAssertTrue('a' == buffer[j].ch, @"buffer[%d] was'%c'", j, buffer[j].ch);
  }
  STAssertTrue('\0' == buffer[39].ch, @"was '%c'", buffer[39].ch);
  
  // Next two rows are b's
  buffer = [vt100 bufferForRow:2];
  for (int j = 0; j < 40; j++) {
    STAssertTrue('b' == buffer[j].ch, @"buffer[%d] was '%c'", j, buffer[j].ch);
  }
  buffer = [vt100 bufferForRow:3];
  for (int j = 0; j < 39; j++) {
    STAssertTrue('b' == buffer[j].ch, @"buffer[%d] was'%c'", j, buffer[j].ch);
  }
  STAssertTrue('\0' == buffer[39].ch, @"was '%c'", buffer[39].ch);
  
  // Last row has a single c
  buffer = [vt100 bufferForRow:4];
  STAssertTrue('c' == buffer[0].ch, @"got '%c'", buffer[0].ch);
  STAssertTrue('\0' == buffer[1].ch, @"got '%c'", buffer[1].ch);
}

- (void) testCursorPosition
{
  // Set a small screen size to make testing a little simpler
  ScreenSize size;
  size.width = 10;
  size.height = 5;
  [vt100 setScreenSize:size];

  // Screen is empty, the cursor is in the top corner
  ScreenPosition pos = [vt100 cursorPosition];
  STAssertEquals(0, pos.x, @"got %d", pos.x);
  STAssertEquals(0, pos.y, @"got %d", pos.y);

  [vt100 readInputStream:"a" withLength:1];
  pos = [vt100 cursorPosition];
  STAssertEquals(1, pos.x, @"got %d", pos.x);
  STAssertEquals(0, pos.y, @"got %d", pos.y);

  [vt100 readInputStream:"a" withLength:1];
  pos = [vt100 cursorPosition];
  STAssertEquals(2, pos.x, @"got %d", pos.x);
  STAssertEquals(0, pos.y, @"got %d", pos.y);

  // newline moves the cursor to the next line
  [vt100 readInputStream:"\r\n" withLength:2];
  pos = [vt100 cursorPosition];
  STAssertEquals(0, pos.x, @"got %d", pos.x);
  STAssertEquals(1, pos.y, @"got %d", pos.y);
  
  // Insert enough characters to get us to the last column on the screen
  [vt100 readInputStream:"aaaaaaaaa" withLength:9];
  pos = [vt100 cursorPosition];
  STAssertEquals(9, pos.x, @"got %d", pos.x);
  STAssertEquals(1, pos.y, @"got %d", pos.y);
  
  // Inserting one more causes the screen to wrap
  [vt100 readInputStream:"a" withLength:1];
  pos = [vt100 cursorPosition];
  STAssertEquals(0, pos.x, @"got %d", pos.x);
  STAssertEquals(2, pos.y, @"got %d", pos.y);  

  // Drop down to the last line on screen
  [vt100 readInputStream:"\r\n\r\n" withLength:4];
  pos = [vt100 cursorPosition];
  STAssertEquals(0, pos.x, @"got %d", pos.x);
  STAssertEquals(4, pos.y, @"got %d", pos.y);  

  // One more causes scroll, but the cursor position (relative to the non-scroll
  // part of the screen) is still at the last position on the screen
  [vt100 readInputStream:"\r\n" withLength:2];
  pos = [vt100 cursorPosition];
  STAssertEquals(0, pos.x, @"got %d", pos.x);
  STAssertEquals(4, pos.y, @"got %d", pos.y);
}

- (void) testClearScreen
{
  // Set a 1x1 screen.  As soon as a character is inserted on to the screen, we
  // wrap and scroll down to the next line.
  ScreenSize size = [vt100 screenSize];
  size.width = 5;
  size.height = 5;
  [vt100 setScreenSize:size];
  
  screen_char_t* buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == '\0', @"expected NULL, got '%c'", buffer[0].ch);
  
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 5; j++) {
      char c = 'a' + j;
      [vt100 readInputStream:&c withLength:1];
    }
  }  
  ScreenPosition pos = [vt100 cursorPosition];
  STAssertEquals(0, pos.x, @"got %d", pos.x);
  STAssertEquals(4, pos.y, @"got %d", pos.y);
  
  [vt100 clearScreen];
  
  size = [vt100 screenSize];  
  STAssertTrue(size.width == 5, @"got %d", size.width);
  STAssertTrue(size.height == 5, @"got %d", size.height);

  pos = [vt100 cursorPosition];
  STAssertEquals(0, pos.x, @"got %d", pos.x);
  STAssertEquals(0, pos.y, @"got %d", pos.y);  
  
  buffer = [vt100 bufferForRow:0];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
  buffer = [vt100 bufferForRow:1];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
  buffer = [vt100 bufferForRow:1];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
  buffer = [vt100 bufferForRow:1];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
  buffer = [vt100 bufferForRow:1];
  STAssertTrue(buffer[0].ch == '\0', @"got '%c'", buffer[0].ch);
}


// TODO(allen): Tests for scroll back buffer

@end