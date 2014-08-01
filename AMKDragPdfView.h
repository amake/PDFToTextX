//
//  AMKDragPdfView.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 11/05/26.
//  Copyright 2011 Aaron Madlon-Kay. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "AMKPdfAcceptor.h"

@interface AMKDragPdfView : PDFView {
    AMKPdfAcceptor *acceptor;
}

@end
