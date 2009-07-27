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

#import "AlarmListController.h"
#import "ColumnarTableViewCell.h"
#import "OpenNMSRestAgent.h"
#import "OnmsAlarm.h"

@implementation AlarmListController

@synthesize alarmTable;
@synthesize fuzzyDate;

@synthesize alarmList;

-(void) dealloc
{
	[self.fuzzyDate release];
	[self.alarmTable release];
	[self.alarmList release];

    [super dealloc];
}

-(void) initializeData
{
	OpenNMSRestAgent* agent = [[OpenNMSRestAgent alloc] init];
	self.alarmList = [agent getAlarms];
	[agent release];
	[self.alarmTable reloadData];
}

-(IBAction) reload:(id) sender
{
	[self initializeData];
}

-(UIColor*) getColorForSeverity:(NSString*)severity
{
	if ([severity isEqual:@"INDETERMINATE"]) {
		// #EBEBCD
		return [UIColor colorWithRed:0.92157 green:0.92157 blue:0.80392 alpha:1.0];
	} else if ([severity isEqual:@"CLEARED"]) {
		// #EEEEEE
		return [UIColor colorWithWhite:0.93333 alpha:1.0];
	} else if ([severity isEqual:@"NORMAL"]) {
		// #D7E1CD
		return [UIColor colorWithRed:0.843134 green:0.88235 blue:0.80392 alpha:1.0];
	} else if ([severity isEqual:@"WARNING"]) {
		// #FFF5CD
		return [UIColor colorWithRed:1.0 green:0.96078 blue:0.80392 alpha:1.0];
	} else if ([severity isEqual:@"MINOR"]) {
		// #FFEBCD
		return [UIColor colorWithRed:1.0 green:0.92157 blue:0.80392 alpha:1.0];
	} else if ([severity isEqual:@"MAJOR"]) {
		// #FFD7CD
		return [UIColor colorWithRed:1.0 green:0.843134 blue:0.80392 alpha:1.0];
	} else if ([severity isEqual:@"CRITICAL"]) {
		// #F5CDCD
		return [UIColor colorWithRed:0.96078 green:0.80392 blue:0.80392 alpha:1.0];
	}
	return [UIColor colorWithWhite:1.0 alpha:1.0];
}

-(UIColor*) getSeparatorColorForSeverity:(NSString*)severity
{
	if ([severity isEqual:@"INDETERMINATE"]) {
		// #999900
		return [UIColor colorWithRed:0.6 green:0.6 blue:0.0 alpha:1.0];
	} else if ([severity isEqual:@"CLEARED"]) {
		// #999999
		return [UIColor colorWithWhite:0.6 alpha:1.0];
	} else if ([severity isEqual:@"NORMAL"]) {
		// #336600
		return [UIColor colorWithRed:0.2 green:0.4 blue:0.0 alpha:1.0];
	} else if ([severity isEqual:@"WARNING"]) {
		// #FFCC00
		return [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
	} else if ([severity isEqual:@"MINOR"]) {
		// #FF9900
		return [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
	} else if ([severity isEqual:@"MAJOR"]) {
		// #FF3300
		return [UIColor colorWithRed:1.0 green:0.2 blue:0.0 alpha:1.0];
	} else if ([severity isEqual:@"CRITICAL"]) {
		// #CC0000
		return [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
	}
	return [UIColor colorWithWhite:0.5 alpha:1.0];
}

#pragma mark UIViewController delegates

- (void) viewDidLoad
{
	self.fuzzyDate = [[FuzzyDate alloc] init];
	[self initializeData];
	[super viewDidLoad];
}

- (void) viewDidUnload
{
	[self.alarmTable release];
	[self.fuzzyDate release];
	[self.alarmList release];
	[super viewDidUnload];
}

-(void) viewWillAppear:(BOOL)animated
{
	NSIndexPath* tableSelection = [self.alarmTable indexPathForSelectedRow];
	if (tableSelection) {
		[self.alarmTable deselectRowAtIndexPath:tableSelection animated:NO];
	}
}

#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.alarmList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.alarmList count] > 0) {
		OnmsAlarm* alarm = [self.alarmList objectAtIndex:indexPath.row];
		CGSize size = [alarm.logMessage sizeWithFont:[UIFont boldSystemFontOfSize:12]
						constrainedToSize:CGSizeMake(220.0, 1000.0)
						lineBreakMode:UILineBreakModeWordWrap];
		if ((size.height + 10) >= tableView.rowHeight) {
			return (size.height + 10);
		}
	}
	return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ColumnarTableViewCell* cell = [[[ColumnarTableViewCell alloc] initWithFrame:CGRectZero] autorelease];

	UIView* backgroundView = [[[UIView alloc] init] autorelease];
	backgroundView.backgroundColor = [UIColor colorWithWhite:0.9333333 alpha:1.0];
	cell.selectedBackgroundView = backgroundView;
	
	if ([self.alarmList count] > 0) {
		// set the border based on the severity (can only set entire table background color :( )
		// tableView.separatorColor = [self getSeparatorColorForSeverity:alarm.severity];

		OnmsAlarm* alarm = [self.alarmList objectAtIndex:indexPath.row];

		UIColor* color = [self getColorForSeverity:alarm.severity];
		cell.contentView.backgroundColor = color;
		
		UILabel *label = [[[UILabel	alloc] initWithFrame:CGRectMake(10.0, 0, 220.0, tableView.rowHeight)] autorelease];
		[cell addColumn:alarm.logMessage];
		label.font = [UIFont boldSystemFontOfSize:12];
		label.text = alarm.logMessage;
		label.backgroundColor = color;
		label.lineBreakMode = UILineBreakModeWordWrap;
		label.numberOfLines = 0;
		[cell.contentView addSubview:label];

		label = [[[UILabel	alloc] initWithFrame:CGRectMake(235.0, 0, 75.0, tableView.rowHeight)] autorelease];
		NSString* eventString = [fuzzyDate format:alarm.lastEventTime];
		[cell addColumn:eventString];
		label.font = [UIFont boldSystemFontOfSize:12];
		label.text = eventString;
		label.backgroundColor = color;
		[cell.contentView addSubview:label];
	} else {
		cell.textLabel.text = @"";
	}
	
	return cell;
}

@end

