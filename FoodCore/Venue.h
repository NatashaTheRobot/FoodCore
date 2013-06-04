//
//  Venue.h
//  FoodCore
//
//  Created by Natasha Murashev on 6/4/13.
//  Copyright (c) 2013 Natasha Murashev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Venue : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * foursquareId;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSNumber * zipCode;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic, retain) NSNumber * checkInCount;
@property (nonatomic, retain) NSNumber * peopleHereNow;
@property (nonatomic, retain) NSString * menuURLString;
@property (nonatomic, retain) NSString * reservationURLString;
@property (nonatomic, retain) NSManagedObject *category;

@end
