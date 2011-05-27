//
//  AMKDragPdfView.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 11/05/26.
//  Copyright 2011 Aaron Madlon-Kay. All rights reserved.
//

#import "AMKDragPdfView.h"
#import "AMKAppController.h"
#import "AMKKeys.h"


@implementation AMKDragPdfView : PDFView

/*
 *	Register to receive dragged files
 */
- (void)awakeFromNib {
	[self registerForDraggedTypes:[NSArray arrayWithObjects:
								   NSFilenamesPboardType,
								   nil]];
}


/*
 *	Allow dragging if the user's dragging in files
 */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	
	if (AMKDebug) NSLog(@"User initiated dragging");
    NSPasteboard *pboard = [sender draggingPasteboard];
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		if (AMKDebug) NSLog(@"User is dragging files");
		return NSDragOperationCopy;
    }
	
    return NSDragOperationNone;
}


/*
 *	Allow drag if there is at least one PDF in the dragged files.
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
	
	if (AMKDebug) NSLog(@"User dropped item(s)");
	
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		
		if (AMKDebug) NSLog(@"Inspecting dropped item(s)...");
		
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		// See if any dropped files are PDFs
		NSEnumerator *e = [files objectEnumerator];
		id file;
		while ((file = [e nextObject])) {
			NSString *extension = [file pathExtension];
			if ([extension caseInsensitiveCompare:@"pdf"] == NSOrderedSame) {
				if (AMKDebug) NSLog(@"Received PDF: %@", file);
				return YES;
			} else {
				if (AMKDebug) NSLog(@"Received non-PDF file: %@", file);
			}
		}
		
		if (AMKDebug) NSLog(@"Done inspecting dropped item(s)");
    }
	
	return NO;
}


/*
 *	Accept and process the dragged files.
 */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	
	if (AMKDebug) NSLog(@"Processing dropped item(s)");
	
    NSPasteboard *pboard = [sender draggingPasteboard];
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		if (AMKDebug) NSLog(@"Received files: %@", files);
		
		AMKAppController *controller = [NSApp delegate];
		
		if ([files count] == 1) {
			[controller setInputFilePath:[files objectAtIndex:0]];
			[controller updateFileDisplay];
			[controller autoRefresh:self];
		} else {
			NSEnumerator *e = [files objectEnumerator];
			id file;
			while ((file = [e nextObject])) {
				// Process only PDFs
				NSString *extension = [file pathExtension];
				if ([extension caseInsensitiveCompare:@"pdf"] == NSOrderedSame) {
					[controller setInputFilePath:file];
					[controller updateFileDisplay];
					[controller processFile:self];
				}
				// Done processing the PDFs
			}
			// Done iterating through dropped files
		}
		// Done with seeing how many files were dropped
    }
	
    return YES;
}

@end
