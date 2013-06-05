//
//  ViewController.m
//  FoodCore
//
//  Created by Natasha Murashev on 6/4/13.
//  Copyright (c) 2013 Natasha Murashev. All rights reserved.
//

#import "ViewController.h"
#import "Foursquare2.h"
#import "Category.h"
#import "Venue.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) NSFileManager *fileManager;
@property (strong, nonatomic) NSURL *documentsDirectory;

- (void)setupLocationManager;
- (void)addRefreshControl;
- (void)refresh;

- (void)getFoursquareVenuesWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude;
- (void)persistFoursquareVenueFromResult:(NSArray *)venuesArray;
- (Category *)categoryWithUniqueName:(NSString *)categoryName;
- (BOOL)venueExists:(NSDictionary *)venueDictionary;
- (void)setupVenues;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.activityIndicator startAnimating];
    
    self.fileManager = [NSFileManager defaultManager];
    self.documentsDirectory = [self.fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    
    [self addRefreshControl];
    
    [self setupLocationManager];
    
}

- (void)addRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)refresh
{
    [self.locationManager startUpdatingLocation];
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
                                longitude:(CGFloat)location.coordinate.longitude];
    
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - foursquare
- (void)getFoursquareVenuesWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
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
                                       if (success) {
                                           
                                           [self persistFoursquareVenueFromResult:[result valueForKeyPath:@"response.venues"]];
                                           
                                       } else {
                                           NSLog(@"ERROR: %@", result);
                                       }
                                       [self.activityIndicator stopAnimating];
                                       [self.refreshControl endRefreshing];
                                       
                                   }];
                                               
//                                           [self getImagesForVenues];
    
}

- (void)persistFoursquareVenueFromResult:(NSArray *)venuesArray
{
    for (NSDictionary *venueDictionary in venuesArray) {
        
        // check if venue exists by latitude / longitude?
        if (![self venueExists:venueDictionary]) {
            
            Venue *venue = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Venue class])
                                                         inManagedObjectContext:self.managedObjectContext];
            
            venue.name = [venueDictionary objectForKey:@"name"];
            venue.peopleHereNow = [NSNumber numberWithInt:[[venueDictionary valueForKeyPath:@"hereNow.count"] intValue]];
            venue.address = [venueDictionary valueForKeyPath:@"location.address"];
            venue.city = [venueDictionary valueForKeyPath:@"location.city"];
            venue.state = [venueDictionary valueForKeyPath:@"location.state"];
            venue.zipCode = [NSNumber numberWithInt:[[venueDictionary valueForKeyPath:@"location.postalCode"] intValue]];
            venue.latitude = [NSNumber numberWithFloat:[[venueDictionary valueForKeyPath:@"location.lat"] floatValue]];
            venue.longitude = [NSNumber numberWithFloat:[[venueDictionary valueForKeyPath:@"location.lng"] floatValue]];
            venue.menuURLString = [venueDictionary valueForKeyPath:@"menu.mobileUrl"];
            venue.reservationURLString = [venueDictionary valueForKeyPath:@"reservations.url"];
            venue.checkInCount = [NSNumber numberWithInt:[[venueDictionary valueForKeyPath:@"stats.checkinsCount"] intValue]];
            venue.foursquareId = [venueDictionary objectForKey:@"id"];
            
            // get the venue category
            NSString *categoryName;
            if ([venueDictionary[@"categories"] count] == 0) {
                categoryName = @"Unknown";
            } else {
                categoryName = venueDictionary[@"categories"][0][@"pluralName"];
            }
            venue.category = [self categoryWithUniqueName:categoryName];
        }
    }
    
    NSError *saveError = nil;
    BOOL didSave = [self.managedObjectContext save:&saveError];
    
    if (!didSave) {
        NSLog(@"SAVE ERROR: %@", saveError.description);
    }
    
    [self setupVenues];
        
}

- (void)setupVenues
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:NSStringFromClass([Venue class])
                                      inManagedObjectContext:self.managedObjectContext];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"category.name" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"checkInCount" ascending:NO]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:@"category.name"
                                                                                   cacheName:nil];
    NSError *fetchError = nil;
    BOOL success = [self.fetchedResultsController performFetch:&fetchError];
    
    if (!success) {
        NSLog(@"FETCH ERROR: %@", fetchError.description);
    } else {
        [self.tableView reloadData];
    }
}

- (BOOL)venueExists:(NSDictionary *)venueDictionary
{
    NSNumber *latitude = [NSNumber numberWithFloat:[[venueDictionary valueForKeyPath:@"location.lat"] floatValue]];
    NSNumber *longitude = [NSNumber numberWithFloat:[[venueDictionary valueForKeyPath:@"location.lng"] floatValue]];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:NSStringFromClass([Venue class])
                                      inManagedObjectContext:self.managedObjectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"latitude = %@ AND longitude = %@", latitude, longitude];
    
    NSError *fetchError = nil;
    NSArray *fetchedVenueArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (fetchError) {
        NSLog(@"Venue FETCH ERROR: %@", fetchError.description);
    } else if (fetchedVenueArray.count == 0) {
        return NO;
    } else {
        return YES;
    }
    
    return NO;
}

- (Category *)categoryWithUniqueName:(NSString *)categoryName
{
    Category *category = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:NSStringFromClass([Category class])
                                 inManagedObjectContext:self.managedObjectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", categoryName];
    
    NSError *fetchError = nil;
    NSArray *categoriesArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (fetchError) {
        NSLog(@"CATEGORY FETCH ERROR: %@", fetchError.description);
    } else if (categoriesArray.count == 0) {
        category = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Category class])
                                                 inManagedObjectContext:self.managedObjectContext];
        category.name = categoryName;
    } else {
        category = categoriesArray[0];
    }
    
    
    return category;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo name];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"venue";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    
    Venue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = venue.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ checkins, %@ here now", venue.checkInCount, venue.peopleHereNow];
    
    if (venue.imageName) {
        NSURL *venueImageURL = [NSURL URLWithString:venue.imageName];
        NSString *venueImageFileName = [venueImageURL  lastPathComponent];
        NSURL *localVenueURL = [self.documentsDirectory URLByAppendingPathComponent:venueImageFileName];
        cell.imageView.image = [UIImage imageWithContentsOfFile:[localVenueURL path]];
    }
    
    return cell;
}

@end
