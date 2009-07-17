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

#import "OutageParser.h"
#import "EventParser.h"
#import "FuzzyDate.h"

@implementation OutageParser

- (id) init
{
	if (self = [super init]) {
		fuzzyDate = [[FuzzyDate alloc] init];
		fuzzyDate.mini = NO;
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLenient:true];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
	}
	return self;
}

- (void)dealloc
{
	[fuzzyDate release];
	[dateFormatter release];

	[outages release];
	[super dealloc];
}

- (OnmsOutage*) getOutage:(CXMLElement*)xmlOutage
{
	OnmsOutage* outage = [[OnmsOutage alloc] init];

	// ID
	for (id attr in [xmlOutage attributes]) {
		if ([[attr name] isEqual:@"id"]) {
			outage.outageId = [NSNumber numberWithInt:[[attr stringValue] intValue]];
		}
	}

	// Service Name
	CXMLElement* msElement = [xmlOutage elementForName:@"monitoredService"];
	if (msElement) {
		CXMLElement* stElement = [msElement elementForName:@"serviceType"];
		if (stElement) {
			CXMLElement* snElement = [stElement elementForName:@"name"];
			if (snElement) {
				[outage setServiceName:[[snElement childAtIndex:0] stringValue]];
			}
		}
	}

	// IP Address
	CXMLElement* ipElement = [xmlOutage elementForName:@"ipAddress"];
	if (ipElement) {
		[outage setIpAddress:[[ipElement childAtIndex:0] stringValue]];
	}

	// Service Lost Date
	CXMLElement* slElement = [xmlOutage elementForName:@"ifLostService"];
	if (slElement) {
		[outage setIfLostService:[dateFormatter dateFromString:[[slElement childAtIndex:0] stringValue]]];
	}
	
	// Service Regained Date
	CXMLElement* srElement = [xmlOutage elementForName:@"ifRegainedService"];
	if (srElement) {
		[outage setIfRegainedService:[dateFormatter dateFromString:[[srElement childAtIndex:0] stringValue]]];
	}
	
	EventParser* eParser = [[EventParser alloc] init];
	
	// Service Lost Event
	CXMLElement* sleElement = [xmlOutage elementForName:@"serviceLostEvent"];
	if (sleElement) {
		if ([eParser parse:sleElement]) {
			[outage setServiceLostEvent: [eParser event]];
		} else {
			NSLog(@"warning: unable to parse %@", sleElement);
		}
	}
	
	// Service Regained Event
	CXMLElement* sreElement = [xmlOutage elementForName:@"serviceRegainedEvent"];
	if (sreElement) {
		if ([eParser parse:sreElement]) {
			[outage setServiceRegainedEvent: [eParser event]];
		} else {
			NSLog(@"warning: unable to parse %@", sreElement);
		}
	}

	[eParser release];
	return outage;
}

- (NSArray*)getViewOutages:(CXMLElement*)node distinctNodes:(BOOL)distinct
{
	NSCountedSet* labelCount;
	if (distinct) {
		labelCount = [[NSCountedSet alloc] init];
	}

	NSMutableArray* viewOutages = [[NSMutableArray alloc] init];
	for (id xmlOutage in [node elementsForName:@"outage"]) {
		ViewOutage* viewOutage = [[ViewOutage alloc] init];
		OnmsOutage* outage = [self getOutage:xmlOutage];
		
		viewOutage.outageId = [outage.outageId copy];
		viewOutage.serviceLostDate = [fuzzyDate format:outage.ifLostService];
		viewOutage.serviceRegainedDate = [fuzzyDate format:outage.ifRegainedService];
		viewOutage.serviceName = [outage.serviceName copy];
		viewOutage.nodeId = [outage.serviceLostEvent.nodeId copy];
		viewOutage.ipAddress = [outage.ipAddress copy];

		if (distinct) {
			if ([labelCount countForObject:outage.serviceLostEvent.nodeId] == 0) {
				[viewOutages addObject:viewOutage];
			}
			[labelCount addObject:[outage.serviceLostEvent.nodeId copy]];
		} else {
			[viewOutages addObject:viewOutage];
		}
		
		[outage release];
	}
	return viewOutages;
}

- (BOOL)parse:(CXMLElement*)node skipRegained:(BOOL)skip
{
    // Release the old outageArray
    [outages release];
	
    // Create a new, empty itemArray
    outages = [[NSMutableArray alloc] init];

	NSArray* xmlOutages = [node elementsForName:@"outage"];
	for (id xmlOutage in xmlOutages) {
		OnmsOutage* outage = [self getOutage:xmlOutage];
		if (!skip || outage.serviceRegainedEvent == nil) {
			[outages addObject: outage];
		}
	}
	return true;
}

- (NSArray*)outages
{
	return outages;
}

- (OnmsOutage*)outage
{
	if ([outages count] > 0) {
		return [outages objectAtIndex:0];
	} else {
		return nil;
	}
}

@end