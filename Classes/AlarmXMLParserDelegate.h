//
//  AlarmXMLParserDelegate.h
//  OpenNMS
//
//  Created by Benjamin Reed on 8/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlarmModel.h"

@interface AlarmXMLParserDelegate : NSObject <NSXMLParserDelegate> {
  NSMutableArray* _alarms;
  AlarmModel* _currentAlarm;
  NSString* _currentElement;
  NSString* _currentValue;
  NSDateFormatter* _dateFormatter;
}

@property (nonatomic, copy) NSMutableArray* alarms;

@end