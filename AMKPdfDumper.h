//
//  AMKPdfDumper.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AMKPdfDumper : NSObject {
	NSString *inputFile, *outputFile, *errorMessage;
}

@property(readwrite,copy) NSString *inputFile, *outputFile, *errorMessage;

- (void)dumpPdfToText;

@end
