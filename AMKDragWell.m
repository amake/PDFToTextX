//
//  AMKDragWindow.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/13.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import "AMKDragWell.h"
#import "AMKKeys.h"


@implementation AMKDragWell : NSImageView


/*
 *	Register to receive dragged files
 */
- (void)awakeFromNib {
	[self registerForDraggedTypes:[NSArray arrayWithObjects:
								   NSFilenamesPboardType,
								   nil]];
}


/*
 *	Allow dragging if the user is dragging in files
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
 *	Allow drag if the dragged item is a folder.
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
	
	if (AMKDebug) NSLog(@"User dropped item(s)");
	
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		
		if (AMKDebug) NSLog(@"Inspecting dropped item(s)...");

        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		// Allow only one item to be dropped
		if ([files count] > 1) {
			NSLog(@"User dragged in too many files.  Rejecting drop.");
			return NO;
		}
		
		NSString *file = [files objectAtIndex:0];
		
		BOOL isDir;
		if ([[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir] && isDir) {
			if (AMKDebug) NSLog(@"Received directory: %@", file);
			return YES;
		} else {
			if (AMKDebug) NSLog(@"Received non-directory: %@", file);
		}
		
		if (AMKDebug) NSLog(@"Done inspecting dropped item(s)");
    }
	
	return NO;
}


/*
 *	Accept and process the dragged folder.
 */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	
	if (AMKDebug) NSLog(@"Processing dropped item");
	
    NSPasteboard *pboard = [sender draggingPasteboard];
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		if (AMKDebug) NSLog(@"Received file: %@", [files objectAtIndex:0]);
		
		[[NSUserDefaults standardUserDefaults] setObject:[files objectAtIndex:0] forKey:AMKOutputFolderKey];
    }
	
    return YES;
}

@end
