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

#import "config.h"

#import "IpInterfaceFactory.h"
#import "IpInterface.h"

#import "IpInterfaceUpdater.h"
#import "IpInterfaceUpdateHandler.h"

#import "OpenNMSAppDelegate.h"

@implementation IpInterfaceFactory

static IpInterfaceFactory* ipInterfaceFactorySingleton = nil;

// 2 weeks
#define CUTOFF (60.0 * 60.0 * 24.0 * 14.0)

+(void) initialize
{
	static BOOL initialized = NO;
	if (!initialized)
	{
		initialized = YES;
		ipInterfaceFactorySingleton = [[IpInterfaceFactory alloc] init];
	}
}

+(IpInterfaceFactory*) getInstance
{
	if (ipInterfaceFactorySingleton == nil) {
		[IpInterfaceFactory initialize];
	}
	return ipInterfaceFactorySingleton;
}

-(void) clearData
{
	NSManagedObjectContext* context = [contextService newContext];
	[context lock];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"IpInterface" inManagedObjectContext:context];
	[request setEntity:entity];
	NSError* error = nil;
	NSArray *ifacesToDelete = [context executeFetchRequest:request error:&error];
	if (!ifacesToDelete) {
		if (error) {
			NSLog(@"%@: error fetching ifaces to delete (clearData): %@", self, [error localizedDescription]);
			[error release];
		} else {
			NSLog(@"%@: error fetching ifaces to delete (clearData)", self);
		}
	} else {
		for (id iface in ifacesToDelete) {
#if DEBUG
			NSLog(@"deleting %@", iface);
#endif
			[context deleteObject:iface];
		}
	}
	error = nil;
	if (![context save:&error]) {
		NSLog(@"%@: an error occurred saving the managed object context: %@", self, [error localizedDescription]);
		[error release];
	}
	[context unlock];
	[context release];
}

-(IpInterface*) getCoreDataIpInterface:(NSNumber*) ipInterfaceId
{
    IpInterface* iface = nil;
	NSManagedObjectContext* context = [contextService readContext];
	
	NSFetchRequest* ipInterfaceRequest = [[NSFetchRequest alloc] init];

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"IpInterface" inManagedObjectContext:context];
	[ipInterfaceRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ipInterfaceId == %@", ipInterfaceId];
	[ipInterfaceRequest setPredicate:predicate];

	NSError* error = nil;
	NSArray *results = [context executeFetchRequest:ipInterfaceRequest error:&error];
	[ipInterfaceRequest release];
	if (!results || [results count] == 0) {
		if (error) {
			NSLog(@"%@: error fetching ipInterface for ID %@: %@", self, ipInterfaceId, [error localizedDescription]);
			[error release];
		}
	} else {
		iface = (IpInterface*)[results objectAtIndex:0];
	}
    return iface;
}

-(NSArray*) getCoreDataIpInterfacesForNode:(NSNumber*) nodeId
{
	NSManagedObjectContext* context = [contextService readContext];
	
	NSFetchRequest* nodeIpInterfaceRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"IpInterface" inManagedObjectContext:context];
	[nodeIpInterfaceRequest setEntity:entity];

	if (nodeId) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nodeId == %@", nodeId];
		[nodeIpInterfaceRequest setPredicate:predicate];
	}

	NSMutableArray* sortDescriptors = [NSMutableArray array];
	[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"interfaceId" ascending:YES] autorelease]];
	[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"ipAddress" ascending:YES] autorelease]];
	[nodeIpInterfaceRequest setSortDescriptors:sortDescriptors];

	NSError* error = nil;
	NSArray *results = [context executeFetchRequest:nodeIpInterfaceRequest error:&error];
	[nodeIpInterfaceRequest release];
	if (!results) {
		if (error) {
			NSLog(@"%@: error fetching ipInterfaces for node ID %@: %@", self, nodeId, [error localizedDescription]);
			[error release];
		} else {
			NSLog(@"%@: error fetching ipInterfaces for node ID %@", self, nodeId);
		}
	}
    return results;
}

-(NSArray*) getRemoteIpInterfacesForNode:(NSNumber*) nodeId
{
	NSArray* ipInterfaces = nil;
	if (nodeId) {
		IpInterfaceUpdater* ipInterfaceUpdater = [[IpInterfaceUpdater alloc] initWithNodeId:nodeId];
		IpInterfaceUpdateHandler* ipInterfaceHandler = [[IpInterfaceUpdateHandler alloc] initWithMethod:@selector(finish) target:self];
		ipInterfaceHandler.nodeId = nodeId;
		ipInterfaceHandler.clearOldObjects = YES;
		ipInterfaceUpdater.handler = ipInterfaceHandler;
		
		[factoryLock lock];
		isFinished = NO;
		[ipInterfaceUpdater update];
		[ipInterfaceUpdater release];
		
		while (!isFinished) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		}
		ipInterfaces = [self getCoreDataIpInterfacesForNode:nodeId];
		[factoryLock unlock];
	}
	return ipInterfaces;
}

-(NSArray*) getIpInterfacesForNode:(NSNumber*) nodeId
{
	NSArray* ipInterfaces = [self getCoreDataIpInterfacesForNode:nodeId];
	BOOL refreshIpInterfaces = (!ipInterfaces || ([ipInterfaces count] == 0));
	
	if (refreshIpInterfaces == NO) {
		for (id ipInterface in ipInterfaces) {
			if ([((IpInterface*)ipInterface).lastModified timeIntervalSinceNow] > CUTOFF) {
				refreshIpInterfaces = YES;
				break;
			}
		}
	}
	if (refreshIpInterfaces) {
#if DEBUG
		NSLog(@"%@: ipInterface(s) not found, or last modified(s) out of date", self);
#endif
		return [self getRemoteIpInterfacesForNode:nodeId];
	}
	return ipInterfaces;
}

@end
