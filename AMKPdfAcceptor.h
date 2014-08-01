//
//  AMKPdfAcceptor.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 8/1/14.
//
//

#import <Foundation/Foundation.h>

@interface AMKPdfAcceptor : NSObject

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;

@end
