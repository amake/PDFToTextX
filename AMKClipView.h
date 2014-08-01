//
//  AMKClipView.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 8/1/14.
//
//

#import <Cocoa/Cocoa.h>

@interface AMKClipView : NSClipView {
    BOOL noScroll;
}

@property BOOL noScroll;

@end
