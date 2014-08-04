//
//  AMKPdfAcceptor.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 8/1/14.
//
//

#import "AMKPdfAcceptor.h"
#import "AMKKeys.h"
#import "AMKAppController.h"

@implementation AMKPdfAcceptor


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
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	
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
		
		if ([files count] == 1) {
			//NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(addFile:) object:files[0]];
            //[thread start];
            [self addFile:files[0]];
		} else {
			//NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(addFiles:) object:files];
            //[thread start];
            [self addFiles:files];
		}
		// Done with seeing how many files were dropped
    }
	
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    // Nothing
}

- (void) addFile: (NSString*)file {
    AMKAppController *controller = [NSApp delegate];
    [controller setInputFileURL:[NSURL fileURLWithPath:file]];
    [controller updateFileDisplay];
    [controller autoRefresh:nil];
}

- (void) addFiles: (NSArray*)files {
    AMKAppController *controller = [NSApp delegate];
    for (NSString *s in files) {
        NSString *extension = [s pathExtension];
        if ([extension caseInsensitiveCompare:@"pdf"] == NSOrderedSame) {
            [controller setInputFileURL:[NSURL fileURLWithPath:s]];
            [controller updateFileDisplay];
            [controller processFile:self];
        }
    }
}

@end
