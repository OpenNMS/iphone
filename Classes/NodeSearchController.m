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

#import "NodeSearchController.h"
#import "NodeSearchDataSource.h"

#import "ONMSDefaultStyleSheet.h"

#import "ONMSConstants.h"

@implementation NodeSearchController

@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    _delegate = nil;

    self.title = @"Nodes";
    self.tabBarItem = [[[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"display.png"] tag:0] autorelease];
  }
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

- (void)addNode
{
  TTNavigator* navigator = [TTNavigator navigator];
  TTURLAction* action = [TTURLAction actionWithURLPath:@"onms://nodes/add"];
  action.animated = YES;
  [navigator openURLAction:action];
}

- (void)loadView
{
  [super loadView];

  TTTableViewController* searchController = [[[TTTableViewController alloc] init] autorelease];
  searchController.dataSource = [[[NodeSearchDataSource alloc] init] autorelease];
  self.searchViewController = searchController;
  self.tableView.tableHeaderView = _searchController.searchBar;
  _searchController.searchBar.placeholder = @"Node Label or IP Begins with...";

  self.navigationBarTintColor = TTSTYLEVAR(navigationBarTintColor);
  _searchController.searchBar.tintColor = TTSTYLEVAR(navigationBarTintColor);
  [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNode)] autorelease] animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  id obj = [defaults objectForKey:kNodeSearchKey];
  if (obj) {
    NSString* text = obj;
    _searchController.searchBar.text = text;
  }
}

- (void)createModel
{
  self.dataSource = [TTSectionedDataSource dataSourceWithItems:[NSArray arrayWithObject:[NSArray arrayWithObject:[TTTableTextItem itemWithText:@"No Matches."]]] sections:[NSArray arrayWithObject:@""]];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTTableViewController

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
  [_delegate nodeSearchController:self didSelectObject:object];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTSearchTextFieldDelegate

- (void)textField:(TTSearchTextField*)textField didSelectObject:(id)object {
  [_delegate nodeSearchController:self didSelectObject:object];
}

@end
