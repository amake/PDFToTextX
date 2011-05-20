//
//  AMKPathToIconTransformer.m
//  PDFtoText X
//
//  Created by Aaron Madlon-Kay on 09/04/14.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AMKPathToIconTransformer.h"


@implementation AMKPathToIconTransformer : NSValueTransformer

+ (Class)transformedValueClass {
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(id)value {
	if (value) {
		NSString *fullPath = [value stringByExpandingTildeInPath];
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:fullPath];
		return icon;
	}
	return nil;
}

@end
