//
//  AMKAppController.h
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface AMKAppController : NSObject {
	IBOutlet NSTextField *inputFileNameField;
	IBOutlet NSTextView *textOutputPreview;
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
	
	NSURL *inputFileURL, *outputFileURL;
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
+ (void)begForDonation;

@end
