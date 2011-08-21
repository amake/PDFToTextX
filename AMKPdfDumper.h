//
//  AMKPdfDumper.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AMKPdfDumper : NSObject {
	NSURL *inputFile, *outputFile;
    NSString *errorMessage;
}

@property(readwrite,copy) NSURL *inputFile, *outputFile;
@property(readwrite,copy) NSString *errorMessage;

- (void)dumpPdfToText;

@end
