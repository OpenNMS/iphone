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

#import <UIKit/UIKit.h>
#import "FuzzyDate.h"
#import "Alarm.h"

@interface AlarmDetailController : UIViewController <UINavigationBarDelegate, UITableViewDelegate, UITableViewDataSource> {
	@private UITableView* alarmTable;
	
	@private FuzzyDate* fuzzyDate;
	@private UIFont* defaultFont;
	@private UIColor* clear;
	@private UIColor* white;

	@private NSMutableArray* sections;
	@private NSManagedObjectID* alarmObjectId;
	@private Alarm* alarm;
	@private NSManagedObjectContext* managedObjectContext;
}

@property (nonatomic, retain) IBOutlet UITableView* alarmTable;

@property (nonatomic, retain) FuzzyDate* fuzzyDate;
@property (nonatomic, retain) UIFont* defaultFont;
@property (nonatomic, retain) UIColor* clear;
@property (nonatomic, retain) UIColor* white;

@property (nonatomic, retain) NSMutableArray* sections;
@property (nonatomic, retain) NSManagedObjectID* alarmObjectId;
@property (nonatomic, retain) Alarm* alarm;
@property (nonatomic, retain) NSManagedObjectContext* managedObjectContext;

-(void)acknowledge;
-(void)unacknowledge;

@end
