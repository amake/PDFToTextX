//
//  AMKDragWindow.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/13.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import "AMKDragWindow.h"
#import "AMKAppController.h"
#import "AMKKeys.h"

@implementation AMKDragWindow : NSWindow


/*
 *	Register to receive dragged files
 */
- (void)awakeFromNib {
	[self registerForDraggedTypes:@[NSFilenamesPboardType]];
    acceptor = [[AMKPdfAcceptor alloc] init];
}


/*
 *	Allow dragging if the user's dragging in files
 */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [acceptor draggingEntered:sender];
}


/*
 *	Allow drag if there is at least one PDF in the dragged files.
 */
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return [acceptor prepareForDragOperation:sender];
}


/*
 *	Accept and process the dragged files.
 */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return [acceptor performDragOperation:sender];
}

@end
