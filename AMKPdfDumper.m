//
//  AMKPdfDumper.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import "AMKPdfDumper.h"
#import "AMKKeys.h"
#import <Quartz/Quartz.h>

@implementation AMKPdfDumper

@synthesize inputFile, outputFile, errorMessage;

- (id)init {
	
	if (self = [super init]) {
		
		// Use mktemp to create a safe temp file
		NSString *td = NSTemporaryDirectory();
		NSString *suffix = @".txt";
		NSString *templateString = [NSString stringWithFormat:@"%@%@%@", td ? td : @"/tmp/",
									@"pdftotextx.XXXXXX", suffix];
		CFStringRef templateStringRef = (CFStringRef)templateString;
		BOOL success = NO;
		int fd = -1;
		
		// Create an NSData to hold the template
		// See: http://www.cocoadev.com/index.pl?UniqueFileName
		unsigned templateDataLength = (unsigned)CFStringGetMaximumSizeOfFileSystemRepresentation(templateStringRef);
		NSMutableData *templateData = [NSMutableData dataWithLength:templateDataLength];
		char *template = (char*)[templateData mutableBytes];
		if (templateData != nil)
		{
			// Fetch the template into the buffer
			if ([templateString getFileSystemRepresentation:template maxLength:templateDataLength])
			{
				// Create the file. This modifies the template (XXXXXX is replaced by a random string)
				fd = mkstemps(template, (int)[suffix length]);
				if (close(fd) == 0) {
					success = YES;
				}
			}
		}
		
		if (!success && template != nil)
			unlink(template);
		if (fd >= 0)
			close(fd);
        
		NSString *path = [[NSString alloc] initWithData:templateData encoding:NSUTF8StringEncoding];
		[self setOutputFile:[NSURL fileURLWithPath:path]];
	}
	
	return self;
}

- (void)dumpPdfToText {
	
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
	[args addObject:[defaults stringForKey:AMKEncodingKey]];
	
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
		pdfDoc = [[[PDFDocument alloc] initWithURL:[self inputFile]] autorelease];
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
	[args addObject:[[self inputFile] path]];
	
	// Indicate output file
	if (AMKDebug) NSLog(@"Setting output file");
	// User-defined output folder
	NSURL *outputFolder = [NSURL fileURLWithPath:[[defaults objectForKey:AMKOutputFolderKey] stringByExpandingTildeInPath]];
	
	if ([defaults boolForKey:AMKAutoSaveKey] && ![defaults boolForKey:AMKOutputToPDFFolderKey]
		&& outputFolder) {
		// Save in user-specified folder
		
		// Get original filename
		NSString *filename = [[[self inputFile] lastPathComponent] stringByDeletingPathExtension];
		// Put original filename in output folder, add .txt
		[self setOutputFile:[[outputFolder URLByAppendingPathComponent:filename]
							 URLByAppendingPathExtension:@"txt"]];
		[args addObject:[[self outputFile] path]];
	} else if ([defaults boolForKey:AMKAutoSaveKey] && [defaults boolForKey:AMKOutputToPDFFolderKey])  {
		// Save in same folder as input PDF (pdftotext default behavior).  No output path needed.
		[self setOutputFile:[[[self inputFile] URLByDeletingPathExtension]
							 URLByAppendingPathExtension:@"txt"]];
	} else {
		// Save to temp folder
		[args addObject:[[self outputFile] path]];
	}
	
	NSTask *theTask = [[[NSTask alloc] init] autorelease];
	
	// At some point pdftotext started reporting an error if the
	// PAPERSIZE environment variable was not set. Default to A4.
	[theTask setEnvironment:[[NSDictionary dictionaryWithObject:@"A4" forKey:@"PAPERSIZE"] autorelease]];
	
	if (AMKDebug) NSLog(@"Setting current path to: %@", [[NSBundle mainBundle] resourcePath]);
	[theTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	
	if (AMKDebug) NSLog(@"Setting launch path: %@", pdftotext);
	[theTask setLaunchPath:pdftotext];
	
	if (AMKDebug) NSLog(@"Setting arguments");
	[theTask setArguments:args];
	
//	NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/error.txt"];

	NSPipe *errorPipe = [NSPipe pipe];
	[theTask setStandardError:errorPipe];
	
	NSPipe *standardPipe = [NSPipe pipe];
	[theTask setStandardOutput:standardPipe];

	if (AMKDebug) NSLog(@"Ready to launch task %@ with args: %@", [theTask launchPath], [theTask arguments]);
	[theTask launch];
	[theTask waitUntilExit];
		
	if (AMKDebug && ![theTask isRunning]) NSLog(@"Task ended with code: %d", [theTask terminationStatus]);
	
	// Read standard output and log it
	NSData *outputData = [[standardPipe fileHandleForReading] availableData];
	if (AMKDebug) NSLog(@"Task output: %@", [[[NSString alloc] initWithData:outputData
																   encoding:NSUTF8StringEncoding] autorelease]);
	
	// Read standard error and save it
	NSData *errorData = [[errorPipe fileHandleForReading] availableData];
	NSString *error;
	if ((errorData != nil) && [errorData length]) {
		if (AMKDebug) NSLog(@"Task reported an error.");
		error = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
		[self setErrorMessage:error];
	} else {
		if (AMKDebug) NSLog(@"Task reported no errors.");
		NSString *message = NSLocalizedString(@"doneStatus", @"Done");
		[self setErrorMessage:message];
	}
	
	
}

@end
