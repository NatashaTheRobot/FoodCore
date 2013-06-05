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
#import "Image.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSOperationQueue *operationQueue;

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
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:4];
    
    [self setupVenues];
    
    [self addRefreshControl];
    
    [self setupLocationManager];
    
}

#pragma mark - refresh control
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
    
        
}

- (void)persistFoursquareVenueFromResult:(NSArray *)venuesArray
{
    for (NSDictionary *venueDictionary in venuesArray) {
        
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
    
    if (venue.images.count > 0) {
        NSString *imageFileName = ((Image *)[venue.images anyObject]).fileName;
        NSURL *venueImageURL = [NSURL URLWithString:imageFileName];
        NSString *venueImageFileName = [venueImageURL  lastPathComponent];
        NSURL *localVenueURL = [self.documentsDirectory URLByAppendingPathComponent:venueImageFileName];
        cell.imageView.image = [UIImage imageWithContentsOfFile:[localVenueURL path]];
    } else {
        [self getImagesForVenue:venue atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)getImagesForVenue:(Venue *)venue atIndexPath:(NSIndexPath *)indexPath
{
    [Foursquare2 getPhotosForVenue:venue.foursquareId
                             limit:[NSNumber numberWithInt:5]
                            offset:nil
                          callback:^(BOOL success, id result) {
                              if (success) {
                                  if ([[result valueForKeyPath:@"response.photos.count"] intValue] > 0) {
                                  
                                      NSDictionary *photoItem = [result valueForKeyPath:@"response.photos.items"][0];
                                      
                                      //TODO iterate through all the returned photos and download the images
                                      
                                      NSString *imageSize = @"300x200";
                                      NSString *imageURLString = [NSString stringWithFormat:@"%@%@%@",
                                                                  [photoItem objectForKey:@"prefix"],
                                                                  imageSize,
                                                                  [photoItem objectForKey:@"suffix"]];
                                      [self downloadImageWithURL:[NSURL URLWithString:imageURLString]
                                                        forVenue:venue
                                                     atIndexPath:indexPath];
                                      }
                              }
                          }];
}

- (void)downloadImageWithURL:(NSURL *)imageURL forVenue:(Venue *)venue atIndexPath:(NSIndexPath *)indexPath
{
    NSBlockOperation *fetchOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];        
        
        // save image data to file
        NSString *imageFileName = [imageURL lastPathComponent];
        NSURL *localImageURL = [self.documentsDirectory URLByAppendingPathComponent:imageFileName];
        [imageData writeToURL:localImageURL atomically:YES];
        
        NSBlockOperation *mainQueueOperation = [NSBlockOperation blockOperationWithBlock:^{
            
            Image *image = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Image class])
                                                         inManagedObjectContext:self.managedObjectContext];
            image.fileName = imageFileName;
            image.venue = venue;

            // refresh table cell if it's the first image?
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:0];
            
            // never saved!
            NSError *saveError = nil;
            BOOL saved = [self.managedObjectContext save:&saveError];
            
            if (!saved) {
                NSLog(@"SAVE ERROR: %@", saveError);
            }
            
        }];
        
        [[NSOperationQueue mainQueue] addOperation:mainQueueOperation];
    }];
    
    [self.operationQueue addOperation:fetchOperation];
    
}

@end
