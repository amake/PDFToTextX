//
//  AMKAppController.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/11.
//  Copyright 2009 Aaron Madlon-Kay. All rights reserved.
//

#import "AMKAppController.h"
#import "AMKPdfDumper.h"
#import "AMKKeys.h"
#import "AMKPathToIconTransformer.h"

@implementation AMKAppController

@synthesize inputFileURL, outputFileURL;


//////////	Initialization & delegate methods


/*
 *	Class initialization method.  Gets called very early.  Cannot use any instance methods in here,
 *	as individual instance of AMKAppController does not exist yet.
 *
 *	Sets user preferences, registers the value transformer for displaying the icon of the output
 *	file path.
 */
+ (void)initialize
{
	// Get shared user defaults instance
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// Load Defaults.plist from within the app bundle
	NSString *defaultsFile = [[NSBundle mainBundle] pathForResource:@"Defaults"
															 ofType:@"plist"];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:defaultsFile];
	
	// Register first-run default settings
	[defaults registerDefaults:dict];
	
	// Don't let user batch-reset these items
	[dict removeObjectForKey:AMKAutoRefreshKey];
	[dict removeObjectForKey:AMKDisplayPDFKey];
	[dict removeObjectForKey:AMKOutputFolderKey];
	[dict removeObjectForKey:AMKAutoSaveKey];
	[dict removeObjectForKey:AMKCustomBinaryPathKey];
	[dict removeObjectForKey:AMKUseCustomBinaryKey];
	[dict removeObjectForKey:AMKDonationKey];
	[dict removeObjectForKey:AMKOutputToPDFFolderKey];
	
	// Register user-resettable settings
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:dict];
	
	// Register value transformer
	AMKPathToIconTransformer *transformer = [[AMKPathToIconTransformer alloc] init];
	[NSValueTransformer setValueTransformer:transformer
									forName:@"AMKPathToIconTransformer"];
	
}


/*
 *	Delegate method called when application is mostly done loading.  Since instance is initialized
 *	at this point, we can use instance-specific methods in here.
 *
 *	Deal with begging for money here.
 *	Also load explanatory PDF/text.
 */
- (void)awakeFromNib {
	
	if (AMKDebug) NSLog(@"App awoke from nib");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// Keep track of number of launches
	int launches = [defaults integerForKey:AMKLaunchesKey];
	if (launches % 10 == 0 && launches > 0 && ![defaults boolForKey:AMKDonationKey]) {
		[AMKAppController begForDonation];
	}
	launches++;
	[defaults setInteger:launches forKey:AMKLaunchesKey];
	
	// Focus not restored after begging for money, so re-focus main window
	[mainWindow makeKeyAndOrderFront:self];
	
	// Load default PDF and text
	PDFDocument *pdfDoc;
	pdfDoc = [[PDFDocument alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"defaultPdf"
																	   withExtension:@"pdf"]];
	[pdfViewPane setDocument:pdfDoc];
	[textOutputPreview setString:NSLocalizedString(@"defaultTextPreview", @"...the output will be displayed here.")];
}


/*
 *	Delegate method to support dragging-and-dropping of files onto the dock icon.
 *
 *	When multiple files are dropped, this function is called separately for each one
 *	so we don't need to bother recursing through multiple files.
 */
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	
	NSString *extension = [filename pathExtension];
	
	// Only accept file if it's a PDF.  May need better (UTI) validation here.
	if ([extension caseInsensitiveCompare:@"pdf"] == NSOrderedSame) {
		[self setInputFileURL:[NSURL fileURLWithPath:filename]];
		[self updateFileDisplay];
		[self autoRefresh:nil];
		return YES;
	}
	
	return NO;
}


/*
 *	Delegate method for NSTextField.  Asks for confirmation before finalizing an edit.
 *	Input validation is performed here.
 *
 *	Make sure start and end pages are valid numbers.  Make sure custom binary path is
 *	a path to an executable file.
 */
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	
	// Separate treatment for each textfield
	if ([control isEqual:binaryPathField]) {
		
		NSFileManager *manager = [NSFileManager defaultManager];
		
		NSString *binaryPath = [[control stringValue] stringByExpandingTildeInPath];
		
		BOOL isDir;
		
		// Make sure custom binary path points to an executable file (not a directory)
		if ([[control stringValue] length] == 0 ||
			([manager isExecutableFileAtPath:binaryPath] &&
			 [manager fileExistsAtPath:binaryPath isDirectory:&isDir] && !isDir)) {
			
			if (AMKDebug) NSLog(@"Custom binary path changed: %@", binaryPath);
			return YES;
		}
		
	} else if ([control isEqual:startPageField] || [control isEqual:endPageField]) {
		
		// Make sure start and end pages are sane
		if ([control integerValue] > 0 || [[control stringValue] length] == 0) {
			return YES;
		}
	}
	
	return NO;
}

/*
 *	Make app quit when last window is closed.
 */
-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


//////////	IBActions


/*
 *	Prompt user to select an input file.  This is the only non-drag-and-drop way to specify an
 *	input file.
 */
- (IBAction)selectInputFile:(id)sender {
	
	// Open file dialog
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:@[@"pdf"]];

	// Proceed if user pressed "OK"
	if ( [openPanel runModal] == NSOKButton )
	{

		// Get filename from array returned by panel
		NSArray *files = [openPanel URLs];
		NSURL *fileURL = files[0];
		
		[self setInputFileURL:fileURL];
		
		[self updateFileDisplay];
		
		// Automatically move to process inputfile
		[self autoRefresh:nil];
	}
	
}


/*
 *	Alternative to -processFile: that only runs when user has set "Refresh automatically."
 */
- (IBAction)autoRefresh:(id)sender {
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:AMKAutoRefreshKey]) {
		if ([sender isEqual:passwordField]) {
			[self updateFileDisplay];
		}
		[self processFile:nil];
	}
}


/*
 *	When user enables autosave but no folder is set yet, prompt user to choose a destination folder.
 */
- (IBAction)enableAutoSave:(id)sender {
	
	// Return immediately if there's already a destination folder.
	if ([[NSUserDefaults standardUserDefaults] stringForKey:AMKOutputFolderKey]) {
		return;
	}
	
	[self selectDestinationFolder:nil];
}


/*
 *	Prompt user to choose a destination folder in which to auto-save the dumped text.
 */
- (IBAction)selectDestinationFolder:(id)sender {
	
	// Open file dialog
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	
	// Set open dialog options
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	// Proceed if user pressed "OK"
	if ( [openPanel runModal] == NSOKButton )
	{
		// Get filename from array returned by panel
		NSArray *files = [openPanel URLs];
		NSURL *folderPath = files[0];
		
		[[NSUserDefaults standardUserDefaults] setObject:[folderPath path] forKey:AMKOutputFolderKey];
	}
	
}


/*
 *	Process the input file.  Creates an AMKPdfDumper and runs it.
 */
- (IBAction)processFile:(id)sender {
	
	// Don't proceed if input file is not set yet
	if (!inputFileURL) {
		if (AMKDebug) NSLog(@"No file to process");
		return;
	}
	
	// Initialize and execute the PDF dumping object
	AMKPdfDumper *dumper = [[AMKPdfDumper alloc] init];
	
	[progressIndicator startAnimation:nil];
	NSString *status = NSLocalizedString(@"processingStatus", @"Processing...");
	[statusMessageField setStringValue:status];
	NSString *outputText = [dumper dumpPdfToText:inputFileURL];
	
    // Indicate output file
	if (AMKDebug) NSLog(@"Setting output file");
	
    // User-defined output folder
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:AMKAutoSaveKey]) {
        NSString *outputPath = [defaults objectForKey:AMKOutputFolderKey];
        if (![defaults boolForKey:AMKOutputToPDFFolderKey] && outputPath) {
            // Save in user-specified folder
            NSURL *outputFolder = [NSURL fileURLWithPath:[outputPath stringByExpandingTildeInPath]];
            // Get original filename
            NSString *filename = [[inputFileURL lastPathComponent] stringByDeletingPathExtension];
            // Put original filename in output folder, add .txt
            outputFileURL = [[outputFolder URLByAppendingPathComponent:filename]
                             URLByAppendingPathExtension:@"txt"];
        } else if ([defaults boolForKey:AMKOutputToPDFFolderKey])  {
            // Save in same folder as input PDF (pdftotext default behavior).  No output path needed.
            outputFileURL = [[inputFileURL URLByDeletingPathExtension]
                             URLByAppendingPathExtension:@"txt"];
        }
        [outputText writeToURL:outputFileURL atomically:true encoding:NSUTF8StringEncoding error:nil];
	}
	
    [textOutputPreview setString:outputText ? outputText : @""];
    
    [progressIndicator stopAnimation:nil];
	
	[statusMessageField setStringValue:[dumper errorMessage]];
	
}


/*
 *	Gets the text in the output text pane, and puts it on the pasteboard in both plaintext and
 *	rich text formats.
 */
- (IBAction)copyOutputText:(id)sender {
	
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	
	// Register supported types with the pasteboard server
	NSArray *types = @[NSStringPboardType, NSRTFPboardType];
	[pb declareTypes:types owner:self];
	
	// Copy plain text to pasteboard
	NSString *outputText = [textOutputPreview string];
	[pb setString:outputText forType:NSStringPboardType];
	
	// Copy rich text to pasteboard
	NSRange all = NSMakeRange(0, [outputText length]);
	[pb setData:[textOutputPreview RTFFromRange:all] forType:NSRTFPboardType];
	
	// Set selection to cover entire text field
	[textOutputPreview setSelectedRange:all];
}


/*
 *	Prompt user to choose a filename and destination with which to save the output text.
 */
- (IBAction)saveFile:(id)sender {
	
	NSString *outputText = [textOutputPreview string];
	
	// Die if there's nothing in the text field to save
	if ([outputText length] < 1) {
		return;
	}
	
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	// Save in same folder as input file by default
    [panel setDirectoryURL:[[self inputFileURL] URLByDeletingLastPathComponent]];
	
	// Keep original filename by default
	NSString *outputFileName = [[[[self inputFileURL]
								  lastPathComponent]
								 stringByDeletingPathExtension]
								stringByAppendingPathExtension:@"txt"];
	if ([outputFileName length]) [panel setNameFieldStringValue:outputFileName];
	// Run panel
	if ([panel runModal] == NSFileHandlingPanelOKButton) {
		
		[outputText writeToURL:[panel URL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
}


/*
 *	Reset a subset of user-specified preferences to the defaults in Defaults.plist.
 */
- (IBAction)restoreDefaults:(id)sender {
	if (AMKDebug) NSLog(@"Restoring defaults");
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:self];
	[self autoRefresh:nil];
}


/*
 *	Open license file
 */
- (IBAction)showLicense:(id)sender {
	NSString *licenseFile = [[NSBundle mainBundle] pathForResource:@"LICENSE"
															ofType:@"rtf"];
	[[NSWorkspace sharedWorkspace] openFile:licenseFile withApplication:@"TextEdit"];
}


/*
 *	Open xpdf documentation (README)
 */
- (IBAction)showXpdfReadme:(id)sender {
	NSString *readme = [[NSBundle mainBundle] pathForResource:@"README"
															ofType:@"rtf"
													   inDirectory:@"xpdf"];
	[[NSWorkspace sharedWorkspace] openFile:readme withApplication:@"TextEdit"];
}


/*
 *	Open xpdf documentation (COPYING)
 */
- (IBAction)showXpdfCopying:(id)sender {
	NSString *copying = [[NSBundle mainBundle] pathForResource:@"COPYING"
															ofType:@"rtf"
													   inDirectory:@"xpdf"];
	[[NSWorkspace sharedWorkspace] openFile:copying withApplication:@"TextEdit"];
}


/*
 *	Open xpdf documentation (man page)
 */
- (IBAction)showXpdfManPage:(id)sender {
	NSString *manPage = [[NSBundle mainBundle] pathForResource:@"pdftotext"
														ofType:@"cat" 
												   inDirectory:@"xpdf"];
	[[NSWorkspace sharedWorkspace] openFile:manPage withApplication:@"TextEdit"];
}

//////////	Instance methods


/*
 *	Puts information about the input file into the appropriate interface elements.
 */
- (void)updateFileDisplay {
	
	// Update icon and filename display in window
	[inputFileNameField setStringValue:[[self inputFileURL] lastPathComponent]];
	[inputFileIconWell setImage:[[NSWorkspace sharedWorkspace] iconForFile:[[self inputFileURL] absoluteString]]];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:AMKDisplayPDFKey]) {
		
		// Display PDF in window
		PDFDocument *pdfDoc;
		pdfDoc = [[PDFDocument alloc] initWithURL:[self inputFileURL]];
		
		// If PDF is locked, use user-specified password to unlock it.
		NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:AMKPasswordKey];
		if (([pdfDoc isLocked] || [pdfDoc isEncrypted]) && password) {
			[pdfDoc unlockWithPassword:password];
		}
		
		[pdfViewPane setDocument:pdfDoc];
	}
}


/*
 *	Prompts user to make a donation.  Called after every n uses (see -awakeFromNib:).
 */
+ (void)begForDonation {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	int launches = [defaults integerForKey:AMKLaunchesKey];
	
	NSAlert *alert = [[NSAlert alloc] init];
	NSString *title = NSLocalizedString(@"donateTitle", @"Please donate!");
	[alert setMessageText:title];
	
	NSString *button1 = NSLocalizedString(@"donateButton1", @"Donate");
	[alert addButtonWithTitle:button1];
	
	NSString *button2 = NSLocalizedString(@"donateButton2", @"Not now");
	[alert addButtonWithTitle:button2];
	
	NSString *button3 = NSLocalizedString(@"donateButton3", @"Don't ask again");
	[alert addButtonWithTitle:button3];
	
	// Get display name of app
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:bundlePath];
	NSString *text = NSLocalizedString(@"donateText", @"You have used %@ a total of %d times.  Please consider donating even a small amount to support its development.");
	text = [NSString stringWithFormat:text, appName, launches];
	[alert setInformativeText:text];
	
	switch ([alert runModal]) {
		case NSAlertFirstButtonReturn: // "Donate" button
			[[NSWorkspace sharedWorkspace] openURL:
			 [NSURL URLWithString:@"http://aaron.madlon-kay.com/donate"]];
			break;
		case NSAlertSecondButtonReturn: // "Not now" button
			break;
		case NSAlertThirdButtonReturn:
			[defaults setBool:TRUE forKey:AMKDonationKey];
			break;
	}
}

@end
