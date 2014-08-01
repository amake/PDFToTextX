//
//  AMKPdfDumper.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import "AMKPdfDumper.h"
#import "AMKAppController.h"
#import "AMKKeys.h"
#import <Quartz/Quartz.h>

@implementation AMKPdfDumper


- (id)init {
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readData:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:nil];
    return self;
}


- (void)dumpPdfToText: (NSURL*)input {
	
	if (AMKDebug) NSLog(@"Starting PDF dump");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *pdftotext;
	if ([defaults boolForKey:AMKUseCustomBinaryKey]) {
		pdftotext = [[defaults stringForKey:AMKCustomBinaryPathKey]
					 stringByExpandingTildeInPath];
	} else {
		pdftotext = [[NSBundle mainBundle] pathForResource:@"pdftotext" ofType:nil];
	}
	
//	NSString *pdftotext = @"/opt/local/bin/pdftotext";
	
	NSMutableArray *args = [NSMutableArray array];
	
	// Set encoding
	if (AMKDebug) NSLog(@"Setting encoding");
	[args addObject:@"-enc"];
	[args addObject:@"UTF-8"];
	
	// Set line endings
	if (AMKDebug) NSLog(@"Setting line endings");
	[args addObject:@"-eol"];
	[args addObject:[defaults stringForKey:AMKLineEndingsKey]];
	
	// Optionally enable "layout" mode
	if ([defaults boolForKey:AMKLayoutKey]) {
		if (AMKDebug) NSLog(@"Setting layout mode");
		[args addObject:@"-layout"];	
	}
	
	// Optionally insert page breaks corresponding to PDF pages
	if (![defaults boolForKey:AMKPageBreaksKey]) {
		if (AMKDebug) NSLog(@"Setting no page break mode");
		[args addObject:@"-nopgbrk"];	
	}
	
	// Optionally restrict conversion to user-specified page range
	NSInteger startPage = [defaults integerForKey:AMKStartPageKey];
	NSInteger endPage = [defaults integerForKey:AMKEndPageKey];
			
	if ((startPage > 0 && endPage > 0) && endPage >= startPage) {
		if (AMKDebug) NSLog(@"Valid page range given: %lu to %lu", startPage, endPage);
		PDFDocument *pdfDoc;
		pdfDoc = [[PDFDocument alloc] initWithURL:input];
		if (endPage <= [pdfDoc pageCount]) {
			if (AMKDebug) NSLog(@"PDF contains %lu pages", [pdfDoc pageCount]);
			[args addObject:@"-f"];
			[args addObject:[NSString stringWithFormat:@"%lu", startPage]];
			[args addObject:@"-l"];
			[args addObject:[NSString stringWithFormat:@"%lu", endPage]];
		}
	}
	
	// Optionally set raw output mode
	if ([defaults boolForKey:AMKRawKey]) {
		if (AMKDebug) NSLog(@"Setting raw output mode");
		[args addObject:@"-raw"];	
	}
	
	// Optionally include password
	if ([defaults boolForKey:AMKUsePasswordKey]) {
		if (AMKDebug) NSLog(@"Using user-supplied password");
		
		if ([defaults boolForKey:AMKOwnerPasswordTypeKey]) {
			if (AMKDebug) NSLog(@"User supplied an owner password");
			[args addObject:@"-opw"];
		} else {
			if (AMKDebug) NSLog(@"User supplied a user password");
			[args addObject:@"-upw"];
		}

		[args addObject:[defaults stringForKey:AMKPasswordKey]];
	}
	
	// Indicate custom configuration file
	if (![defaults boolForKey:AMKUseCustomBinaryKey]) {
		if (AMKDebug) NSLog(@"Setting config file");
		[args addObject:@"-cfg"];
		[args addObject:[[NSBundle mainBundle] pathForResource:@"xpdfrc"
														ofType:nil]];	
	}
	
	// Indicate input file
	if (AMKDebug) NSLog(@"Setting input file");
	[args addObject:[input path]];
    
    // Output to stdout
    [args addObject:@"-"];
	
	task = [[NSTask alloc] init];
	
	// At some point pdftotext started reporting an error if the
	// PAPERSIZE environment variable was not set. Default to A4.
	[task setEnvironment:@{@"PAPERSIZE": @"A4"}];
	
	if (AMKDebug) NSLog(@"Setting current path to: %@", [[NSBundle mainBundle] resourcePath]);
	[task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	
	if (AMKDebug) NSLog(@"Setting launch path: %@", pdftotext);
	[task setLaunchPath:pdftotext];
	
	if (AMKDebug) NSLog(@"Setting arguments");
	[task setArguments:args];
	
//	NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/error.txt"];

	NSPipe *errorPipe = [NSPipe pipe];
	[task setStandardError:errorPipe];
	
	NSPipe *standardPipe = [NSPipe pipe];
	[task setStandardOutput:standardPipe];

	if (AMKDebug) NSLog(@"Ready to launch task %@ with args: %@", [task launchPath], [task arguments]);
	[task launch];
    [[standardPipe fileHandleForReading] readInBackgroundAndNotify];
    //[task waitUntilExit];
}
     
- (void)readData: (NSNotification*)notification {
    AMKAppController *controller = [NSApp delegate];
    
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if ([data length]) {
        [controller appendText:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    }
    if ([task isRunning] || [data length]) {
        [[notification object] readInBackgroundAndNotify];
        return;
    }
    
    if (AMKDebug && ![task isRunning]) NSLog(@"Task ended with code: %d", [task terminationStatus]);
    
    // Read standard error and save it
    NSData *errorData = [[[task standardError] fileHandleForReading] availableData];
    if ((errorData != nil) && [errorData length]) {
        if (AMKDebug) NSLog(@"Task reported an error.");
        [controller setErrorText:[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]];
    } else {
        if (AMKDebug) NSLog(@"Task reported no errors.");
        NSString *message = NSLocalizedString(@"doneStatus", @"Done");
        [controller setErrorText:message];
    }
    [controller dumpDidFinish];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
