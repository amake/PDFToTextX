//
//  AMKPdfDumper.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AMKPdfDumper : NSObject {
    NSTask *task;
}

- (void)dumpPdfToText: (NSURL*)input;

@end
