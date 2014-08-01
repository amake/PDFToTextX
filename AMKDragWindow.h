//
//  AMKDragWindow.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/13.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMKPdfAcceptor.h"


@interface AMKDragWindow : NSWindow {
    AMKPdfAcceptor *acceptor;
}

@end
