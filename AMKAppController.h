//
//  AMKAppController.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "AMKPdfDumper.h"
#import "AMKClipView.h"

@interface AMKAppController : NSObject {
	IBOutlet NSTextField *inputFileNameField;
	IBOutlet NSTextView *textOutputPreview;
    IBOutlet AMKClipView *outputClipView;
	IBOutlet PDFView *pdfViewPane;
	IBOutlet NSImageView *inputFileIconWell;
	IBOutlet NSImageView *outputFolderIconWell;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextField *binaryPathField;
	IBOutlet NSTextField *startPageField;
	IBOutlet NSTextField *endPageField;
	IBOutlet NSTextField *statusMessageField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSWindow *mainWindow;
    IBOutlet NSButton *goButton;
	
	NSURL *inputFileURL, *outputFileURL;
    AMKPdfDumper *dumper;
    NSMutableString *buffer;
}

@property(readwrite,copy) NSURL *inputFileURL, *outputFileURL;

- (IBAction)processFile:(id)sender;
- (IBAction)selectInputFile:(id)sender;
- (IBAction)copyOutputText:(id)sender;
- (IBAction)saveFile:(id)sender;
- (IBAction)restoreDefaults:(id)sender;
- (IBAction)autoRefresh:(id)sender;
- (IBAction)selectDestinationFolder:(id)sender;
- (IBAction)enableAutoSave:(id)sender;

// Display documentation
- (IBAction)showLicense:(id)sender;
- (IBAction)showXpdfReadme:(id)sender;
- (IBAction)showXpdfCopying:(id)sender;
- (IBAction)showXpdfManPage:(id)sender;

- (void)updateFileDisplay;
- (void)appendText:(NSString*)text;
- (void)setErrorText:(NSString*)error;
- (void)dumpDidFinish;
+ (void)begForDonation;

@end
