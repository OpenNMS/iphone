/*******************************************************************************
 * This file is part of the OpenNMS(R) iPhone Application.
 * OpenNMS(R) is a registered trademark of The OpenNMS Group, Inc.
 *
 * Copyright (C) 2009 The OpenNMS Group, Inc.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc.:
 *
 *      51 Franklin Street
 *      5th Floor
 *      Boston, MA 02110-1301
 *      USA
 *
 * For more information contact:
 *
 *      OpenNMS Licensing <license@opennms.org>
 *      http://www.opennms.org/
 *      http://www.opennms.com/
 *
 *******************************************************************************/

#import "UpdateHandler.h"
#import "OpenNMSAppDelegate.h"

@implementation UpdateHandler

@synthesize spinner;
@synthesize contextService;
@synthesize method;
@synthesize methodTarget;
@synthesize clearOldObjects;

static NSOperationQueue* operationQueue;

-(id) init
{
	if (self = [super init]) {
		spinner = nil;
		contextService = [[ContextService alloc] init];
		clearOldObjects = NO;
		
		if (!operationQueue) {
			operationQueue = [[NSOperationQueue alloc] init];
			[operationQueue setMaxConcurrentOperationCount:1];
		}
	}
	return self;
}

-(id) initWithMethod:(SEL)selector target:(NSObject*)target
{
	if (self = [self init]) {
		self.method = selector;
		self.methodTarget = target;
	}
	return self;
}

-(void) dealloc
{
	spinner = nil;
	contextService = nil;
	methodTarget = nil;

	[super dealloc];
}

- (NSString *)flattenHTML:(NSString *)html {
	
    NSScanner *theScanner;
    NSString *text = nil;
	
    theScanner = [NSScanner scannerWithString:html];
	
    while ([theScanner isAtEnd] == NO) {
		
        // find start of tag
        [theScanner scanUpToString:@"<" intoString:NULL] ; 
		
        // find end of tag
        [theScanner scanUpToString:@">" intoString:&text] ;
		
        // replace the found tag with a space
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
		
    }
    
    return html;
}

-(NSString *) cleanUpString:(NSString *)html
{
	NSString* cleaned = [[self flattenHTML:html] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return cleaned;
}

-(NSString*) stringForDate:(NSString*)dateString
{
	NSString* date;
	NSString* time;
	NSString* zoneHour;
	NSString* zoneMinute;

	NSScanner *scanner = [NSScanner scannerWithString:dateString];
	scanner.caseSensitive = YES;
	if (![scanner scanUpToString:@"T" intoString:&date]) {
#if DEBUG
		NSLog(@"%@: unable to scan date portion of %@", self, dateString);
#endif
		return dateString;
	}
	if (![scanner scanString:@"T" intoString:NULL]) {
#if DEBUG
		NSLog(@"%@: unable to scan T separator of %@", self, dateString);
#endif
		return dateString;
	}
	if (![scanner scanUpToString:@"-" intoString:&time]) {
#if DEBUG
		NSLog(@"%@: unable to scan time portion of %@", self, dateString);
#endif
		return dateString;
	}
	if (![scanner scanString:@"-" intoString:NULL]) {
#if DEBUG
		NSLog(@"%@: unable to scan - separator of %@", self, dateString);
#endif
		return dateString;
	}
	if (![scanner scanUpToString:@":" intoString:&zoneHour]) {
#if DEBUG
		NSLog(@"%@: unable to scan time zone hour portion of %@", self, dateString);
#endif
		return dateString;
	}
	if (![scanner scanString:@":" intoString:NULL]) {
#if DEBUG
		NSLog(@"%@: unable to scan : separator of %@", self, dateString);
#endif
		return dateString;
	}
	zoneMinute = [dateString substringFromIndex:[scanner scanLocation]];

	NSArray* splitTime = [time componentsSeparatedByString:@"."];
	time = [splitTime objectAtIndex:0];
	NSString* returnString = [NSString stringWithFormat:@"%@T%@-%@%@", date, time, zoneHour, zoneMinute];
	return returnString;
}


-(CXMLDocument*) getDocumentForRequest:(ASIHTTPRequest*) request
{
	NSString* response = [request responseString];
	if (!response || [response isEqual:@""]) {
		return nil;
	}

	NSError* error = nil;
	CXMLDocument* document = [[[CXMLDocument alloc] initWithXMLString: response options: 0 error: &error] autorelease];
	if (!document) {
		NSString* title;
		NSString* message;
		if (error) {
			title = [error localizedDescription];
			message = [error localizedFailureReason];
		} else {
			title = @"XML Parse Error";
			message = @"An error occurred parsing the document.";
		}
		
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle: title
								   message: message
								   delegate:self
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		[errorAlert show];
		[errorAlert autorelease];
		
		[self autorelease];
		return nil;
	}
	return document;
}

-(void) handleRequest:(ASIHTTPRequest*) request
{
#if DEBUG
	NSLog(@"%@: Handling completed request: %@", self, request);
#endif
}

#define ALWAYS_ON_MAIN_THREAD 0

-(void) finished
{
	if (methodTarget && method) {
#if ALWAYS_ON_MAIN_THREAD
		[methodTarget performSelectorOnMainThread:method withObject:nil waitUntilDone:YES];
#else
		[methodTarget performSelector:method withObject:nil];
#endif
	}
	[spinner stopAnimating];
}

#define USE_QUEUES 0

-(void) requestDidFinish:(ASIHTTPRequest*) request
{
#if USE_QUEUES
	NSInvocationOperation* operation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(handleRequest:) object:request] autorelease];
	[operationQueue addOperation:operation];
#else
	[self handleRequest:request];
#endif
}

-(void) requestFailed:(ASIHTTPRequest*) request
{
	NSError* error = [request error];
	NSLog(@"%@: Request failed: %@", self, [error localizedDescription]);
	if (methodTarget && method) {
#if ALWAYS_ON_MAIN_THREAD
		[methodTarget performSelectorOnMainThread:method withObject:nil waitUntilDone:YES];
#else
		[methodTarget performSelector:method withObject:nil];
#endif
	}
	[spinner stopAnimating];

	BOOL settingsActive = ((OpenNMSAppDelegate*)[UIApplication sharedApplication].delegate).settingsActive;
	if (!settingsActive) {
		UIAlertView *errorAlert = [[UIAlertView alloc]
			initWithTitle: [error localizedDescription]
			message: [error localizedFailureReason]
			delegate:self
			cancelButtonTitle:@"OK"
			otherButtonTitles:nil];
		[errorAlert show];
		[errorAlert autorelease];
	}
}

@end
