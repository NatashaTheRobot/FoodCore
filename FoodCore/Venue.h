//
//  Venue.h
//  FoodCore
//
//  Created by Natasha Murashev on 6/5/13.
//  Copyright (c) 2013 Natasha Murashev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Category, Image;

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
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) Category *category;
@property (nonatomic, retain) NSSet *images;
@end

@interface Venue (CoreDataGeneratedAccessors)

- (void)addImagesObject:(Image *)value;
- (void)removeImagesObject:(Image *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
