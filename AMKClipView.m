//
//  AMKClipView.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 8/1/14.
//
//

#import "AMKClipView.h"

@implementation AMKClipView

@synthesize noScroll;

- (BOOL) autoscroll:(NSEvent *)theEvent {
    if (noScroll) {
        return NO;
    }
    return [super autoscroll:theEvent];
}

- (void) scrollToPoint:(NSPoint)newOrigin {
    if (noScroll) {
        return;
    }
    [super scrollToPoint:newOrigin];
}

@end
