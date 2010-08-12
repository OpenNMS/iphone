//
//  OutageDataSource.m
//  OpenNMS
//
//  Created by Benjamin Reed on 8/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NodeDataSource.h"
#import "NodeModel.h"
#import "OutageModel.h"
#import "IPInterfaceModel.h"
#import "SNMPInterfaceModel.h"
#import "EventModel.h"

#import "ONMSSeverityItem.h"
#import "ONMSSeverityItemCell.h"

#import "Three20Core/NSDateAdditions.h"
#import "Three20Core/NSStringAdditions.h"

@implementation NodeDataSource

@synthesize label = _label;

- (id)initWithNodeId:(NSString*)nodeId
{
	TTDINFO(@"init called");
	if (self = [super init]) {
		_nodeModel = [[[NodeModel alloc] initWithNodeId:nodeId] retain];
	}
	return self;
}

- (void)dealloc
{
	// Don't do this!  It's done for us.
	// TT_RELEASE_SAFELY(_nodeModel);
	[super dealloc];
}

- (id<TTModel>)model
{
	return _nodeModel;
}

- (NSString *)flattenHTML:(NSString *)html
{
  
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

///////////////////////////////////////////////////////////////////////////////////////////////////
- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object
{
  if ([object isKindOfClass:[ONMSSeverityItem class]]) {
    return [ONMSSeverityItemCell class];
  } else {
    return [super tableView:tableView cellClassForObject:object];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
/*
- (void)        tableView: (UITableView*)tableView
                     cell: (UITableViewCell*)cell
    willAppearAtIndexPath: (NSIndexPath*)indexPath {
  if ([cell isKindOfClass:[ONMSSeverityItemCell class]]) {
    ONMSSeverityItemCell* outageCell = (ONMSSeverityItemCell*)cell;
    outageCell.delegate = _delegate;
  }
}
 */

- (void)tableViewDidLoadModel:(UITableView*)tableView
{
	NSMutableArray* items = [[NSMutableArray alloc] init];
	NSMutableArray* sections = [[NSMutableArray alloc] init];

	TTDINFO(@"model loaded: %@", _nodeModel);
	
	_label = _nodeModel.label;

	if (_nodeModel.outages && [_nodeModel.outages count] > 0) {
		[sections addObject:@"Outages"];

		NSMutableArray* outageItems = [NSMutableArray arrayWithCapacity:[_nodeModel.outages count]];
		for (id o in _nodeModel.outages) {
			OutageModel* outage = (OutageModel*)o;
//		NSString* host = outage.host;
			NSString* host = nil;
			if (!host) {
				host = outage.ipAddress;
			}
      ONMSSeverityItem* item = [[[ONMSSeverityItem alloc] init] autorelease];
			item.text = [host stringByAppendingFormat:@"/%@", outage.serviceName];
      item.caption = [outage.logMessage stringByRemovingHTMLTags];
			item.timestamp = outage.ifLostService;
      item.severity = outage.severity;
			[outageItems addObject:item];
		}
		[items addObject:outageItems];
	}
	
	if (_nodeModel.ipInterfaces && [_nodeModel.ipInterfaces count] > 0) {
		[sections addObject:@"IP Interfaces"];

		NSMutableArray* interfaceItems = [NSMutableArray arrayWithCapacity:[_nodeModel.ipInterfaces count]];
		for (id i in _nodeModel.ipInterfaces) {
			IPInterfaceModel* interface = (IPInterfaceModel*)i;
      TTDINFO(@"IP interface = %@", interface);
      TTTableSubtitleItem* item = [[[TTTableSubtitleItem alloc] init] autorelease];
      item.text = interface.hostName;
      item.subtitle = [NSString stringWithFormat:@"%@ (%@)", interface.ipAddress, [interface.managed isEqual:@"M"]? @"Managed" : @"Unmanaged"];
      [interfaceItems addObject:item];
		}
		[items addObject:interfaceItems];
	}
	
	if (_nodeModel.snmpInterfaces && [_nodeModel.snmpInterfaces count] > 0) {
		[sections addObject:@"SNMP Interfaces"];
    
		NSMutableArray* interfaceItems = [NSMutableArray arrayWithCapacity:[_nodeModel.snmpInterfaces count]];
		for (id s in _nodeModel.snmpInterfaces) {
			SNMPInterfaceModel* interface = s;
      TTDINFO(@"SNMP interface = %@", interface);
      TTTableSubtitleItem* item = [[[TTTableSubtitleItem alloc] init] autorelease];
      NSString* text;
      if (TTIsStringWithAnyText(interface.ifDescr)) {
        text = [NSString stringWithFormat:@"%@: %@", interface.ifIndex, interface.ifDescr];
      } else {
        text = interface.ifIndex;
      }
      item.text = text;
      item.subtitle = [NSString stringWithFormat:@"%@ (%@)", interface.ipAddress, interface.ifSpeed];
      [interfaceItems addObject:item];
		}
		[items addObject:interfaceItems];
	}
	
	if (_nodeModel.events && [_nodeModel.events count] > 0) {
		[sections addObject:@"Events"];
    
		NSMutableArray* eventItems = [NSMutableArray arrayWithCapacity:[_nodeModel.events count]];
		for (id e in _nodeModel.events) {
			EventModel* event = e;
      /*
      TTTableCaptionItem* item = [[[TTTableCaptionItem alloc] init] autorelease];
      item.caption = [event.timestamp formatShortTime];
      item.text = [self cleanUpString:event.logMessage];
       */
      ONMSSeverityItem* item = [[[ONMSSeverityItem alloc] init] autorelease];
			item.text = [event.uei stringByReplacingOccurrencesOfString:@"uei.opennms.org/" withString:@""];
      item.caption = [event.logMessage stringByRemovingHTMLTags];
			item.timestamp = event.timestamp;
      item.severity = event.severity;
      
      [eventItems addObject:item];
		}
		[items addObject:eventItems];
	}
	
	self.items = items;
	self.sections = sections;
	
	TT_RELEASE_SAFELY(items);
	TT_RELEASE_SAFELY(sections);
}

@end
