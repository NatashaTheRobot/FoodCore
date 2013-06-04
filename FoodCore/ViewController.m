//
//  ViewController.m
//  FoodCore
//
//  Created by Natasha Murashev on 6/4/13.
//  Copyright (c) 2013 Natasha Murashev. All rights reserved.
//

#import "ViewController.h"
#import "Foursquare2.h"
#import <CoreData/CoreData.h>
#import "Category.h"
#import "Venue.h"

@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;

- (void)setupLocationManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupLocationManager];
}

#pragma mark - Location manager

- (void)setupLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = locations[0];
    
    [self getFoursquareVenuesWithLatitude:(CGFloat)location.coordinate.latitude
                             andLongitude:(CGFloat)location.coordinate.longitude];
    
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - foursquare
- (void)getFoursquareVenuesWithLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude
{
    [Foursquare2 searchVenuesNearByLatitude:[NSNumber numberWithFloat:latitude]
                                  longitude:[NSNumber numberWithFloat:longitude]
                                 accuracyLL:nil
                                   altitude:nil
                                accuracyAlt:nil
                                      query:nil
                                      limit:[NSNumber numberWithInt:100]
                                     intent:0
                                     radius:[NSNumber numberWithInt:800]
                                 categoryId:nil
                                   callback:^(BOOL success, id result) {
                                       
                                   }];
    
//    _venuesSortedByCheckins = [NSArray array];
//    
//    [Foursquare2 searchVenuesNearByLatitude:[NSNumber numberWithFloat:latitude]
//                                  longitude:[NSNumber numberWithFloat:longitude]
//                                 accuracyLL:nil
//                                   altitude:nil
//                                accuracyAlt:nil
//                                      query:nil
//                                      limit:[NSNumber numberWithInt:100]
//                                 categoryId:@"4d4b7105d754a06374d81259"
//                                     intent:0
//                                     radius:[NSNumber numberWithInt:800]
//                                   callback:^(BOOL success, id result) {
//                                       
//                                       if (success) {
//                                           
//                                           
//                                           NSMutableArray *venuesUnsorted = [NSMutableArray array];
//                                           
//                                           NSArray *venuesArray = [result valueForKeyPath:@"response.venues"];
//                                           
//                                           for (NSDictionary *venue in venuesArray) {
//                                               
//                                               Venue *newVenue = [[Venue alloc] init];
//                                               
//                                               newVenue.name = [venue objectForKey:@"name"];
//                                               newVenue.numberOfPeopleHereNow = [[venue valueForKeyPath:@"hereNow.count"] intValue];
//                                               newVenue.address = [venue valueForKeyPath:@"location.address"];
//                                               newVenue.city = [venue valueForKeyPath:@"location.city"];
//                                               newVenue.state = [venue valueForKeyPath:@"location.state"];
//                                               newVenue.zipCode = [[venue valueForKeyPath:@"location.postalCode"] intValue];
//                                               newVenue.latitude = [[venue valueForKeyPath:@"location.lat"] floatValue];
//                                               newVenue.longitude = [[venue valueForKeyPath:@"location.lng"] floatValue];
//                                               newVenue.menuURL = [NSURL URLWithString:[venue valueForKeyPath:@"menu.mobileUrl"]];
//                                               newVenue.reservationURL = [NSURL URLWithString:[venue valueForKeyPath:@"reservations.url"]];
//                                               newVenue.checkInCount = [[venue valueForKeyPath:@"stats.checkinsCount"] intValue];
//                                               newVenue.usersCount = [[venue valueForKeyPath:@"stats.usersCount"] intValue];
//                                               newVenue.foursquareId = [venue objectForKey:@"id"];
//                                               
//                                               [venuesUnsorted addObject:newVenue];
//                                           }
//                                           
//                                           _venuesSortedByCheckins = [venuesUnsorted sortedArrayUsingComparator:^NSComparisonResult(Venue *venue1, Venue *venue2) {
//                                               NSNumber *checkinCount1 = [NSNumber numberWithInt:venue1.checkInCount];
//                                               NSNumber *checkinCount2 = [NSNumber numberWithInt:venue2.checkInCount];
//                                               
//                                               return ([checkinCount1 compare:checkinCount2] == NSOrderedAscending);
//                                           }];
//                                           
//                                           for (UIViewController *viewController in self.childViewControllers) {
//                                               if ([viewController isKindOfClass:[VenuesListViewController class]]) {
//                                                   ((VenuesListViewController *)viewController).venues = _venuesSortedByCheckins;
//                                               } else if ([viewController isKindOfClass:[VenueMapViewController class]]){
//                                                   ((VenueMapViewController*)viewController).venues = _venuesSortedByCheckins;
//                                               }
//                                           }
//                                           
//                                           [__activityIndicator stopAnimating];
//                                           [self getImagesForVenues];
//                                       }
//                                   }];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"venue";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
