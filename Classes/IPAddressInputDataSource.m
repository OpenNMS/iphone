/*******************************************************************************
 * This file is part of the OpenNMS(R) iPhone Application.
 * OpenNMS(R) is a registered trademark of The OpenNMS Group, Inc.
 *
 * Copyright (C) 2010 The OpenNMS Group, Inc.  All rights reserved.
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

#import "IPAddressInputDataSource.h"


@implementation IPAddressInputDataSource

- (id)init
{
  if (self = [super init]) {
    _model = [[IPAddressInputModel alloc] init];

    _host = [[[UITextField alloc] init] autorelease];
    _host.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _host.keyboardType = UIKeyboardTypeURL;
    _host.placeholder = @"Hostname or IP Address";
  }
  return self;
}

- (id<TTModel>)model
{
  return _model;
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object
{
  if ([object isKindOfClass:[TTTableViewItem class]]) {
    return [TTTableViewCell class];
  } else {
    return [super tableView:tableView cellClassForObject:object];
  }
}

- (void)tableViewDidLoadModel:(UITableView*)tableView
{
  NSMutableArray* items = [[NSMutableArray alloc] init];
  NSMutableArray* sections = [[NSMutableArray alloc] init];
  
  [sections addObject:@""];

  NSMutableArray* inputItems = [NSMutableArray array];

  [inputItems addObject:[TTTableControlItem itemWithCaption:@"Host:" control:_host]];
  
  [items addObject:inputItems];
  
  self.items = items;
  self.sections = sections;
  
  TT_RELEASE_SAFELY(items);
  TT_RELEASE_SAFELY(sections);
}

- (NSString*)getHost
{
  return _host.text;
}

@end
