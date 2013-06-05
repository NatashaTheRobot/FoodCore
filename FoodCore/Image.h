//
//  Image.h
//  FoodCore
//
//  Created by Natasha Murashev on 6/5/13.
//  Copyright (c) 2013 Natasha Murashev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Venue;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) Venue *venue;

@end
