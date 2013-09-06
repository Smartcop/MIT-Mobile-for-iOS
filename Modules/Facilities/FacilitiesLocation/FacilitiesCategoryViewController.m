#import "FacilitiesCategoryViewController.h"

#import "FacilitiesCategory.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocation.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesLocationViewController.h"
#import "FacilitiesLeasedViewController.h"
#import "FacilitiesRoomViewController.h"
#import "FacilitiesTypeViewController.h"
#import "FacilitiesUserLocationViewController.h"
#import "HighlightTableViewCell.h"
#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"
#import "FacilitiesLocationSearch.h"


@interface FacilitiesCategoryViewController ()
@property (nonatomic,strong) FacilitiesLocationSearch *searchHelper;
@property (nonatomic,strong) FacilitiesLocationData* locationData;
@property (nonatomic,strong) NSPredicate* filterPredicate;

@property (nonatomic,strong) NSArray* cachedData;
@property (nonatomic,strong) NSArray* filteredData;
@property (nonatomic,strong) NSString* searchString;
@property (nonatomic,strong) NSString *trimmedString;
@property (nonatomic,strong) id observerToken;

- (BOOL)shouldShowLocationSection;
- (NSArray*)dataForMainTableView;
- (void)configureMainTableCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
- (NSArray*)resultsForSearchString:(NSString*)searchText;
- (void)configureSearchCell:(HighlightTableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
@end

@implementation FacilitiesCategoryViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
        self.locationData = [FacilitiesLocationData sharedData];
        self.filterPredicate = [NSPredicate predicateWithFormat:@"locations.@count > 0"];
    }
    return self;
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *mainView = [[UIView alloc] initWithFrame:screenFrame];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor mit_backgroundColor];
    
    
    CGRect searchBarFrame = CGRectZero;
    
    {
        UISearchBar *searchBar = [[UISearchBar alloc] init];
        searchBar.delegate = self;
        searchBar.barStyle = UIBarStyleBlackOpaque;
        
        UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar
                                                                                         contentsController:self];
        searchController.delegate = self;
        searchController.searchResultsDataSource = self;
        searchController.searchResultsDelegate = self;
        
        [searchBar sizeToFit];
        searchBarFrame = searchBar.frame;
        [mainView addSubview:searchBar];
    }
    
    {
        CGRect tableRect = screenFrame;
        tableRect.origin = CGPointMake(0, searchBarFrame.size.height);
        tableRect.size.height -= searchBarFrame.size.height;
        
        UITableView *tableView = [[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped];
        [tableView applyStandardColors];
        
        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.hidden = YES;
        tableView.scrollEnabled = YES;
        tableView.autoresizesSubviews = YES;
        
        self.tableView = tableView;
        [mainView addSubview:tableView];
    }
    
    
    {
        CGRect loadingFrame = screenFrame;
        loadingFrame.origin = CGPointMake(0, searchBarFrame.size.height);
        loadingFrame.size.height -= searchBarFrame.size.height;
        
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:loadingFrame];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor clearColor];
        
        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.cachedData = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.observerToken == nil) {
        __block FacilitiesCategoryViewController *weakSelf = self;
        self.observerToken = [self.locationData addUpdateObserver:^(NSString *notification, BOOL updated, id userData) {
            FacilitiesCategoryViewController *blockSelf = weakSelf;
            if (blockSelf && [userData isEqualToString:FacilitiesCategoriesKey]) {
                if ([blockSelf.loadingView superview]) {
                    [blockSelf.loadingView removeFromSuperview];
                    blockSelf.loadingView = nil;
                    blockSelf.tableView.hidden = NO;
                }
                                     
                if ((blockSelf.cachedData == nil) || updated) {
                    blockSelf.cachedData = nil;
                    [blockSelf.tableView reloadData];
                }
            } else if ([userData isEqualToString:FacilitiesLocationsKey]) {
                if ([blockSelf.searchDisplayController isActive] && ((blockSelf.filteredData == nil) || updated)) {
                    blockSelf.filteredData = nil;
                    [blockSelf.searchDisplayController.searchResultsTableView reloadData];
                }
            }
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.observerToken) {
        [self.locationData removeUpdateObserver:self.observerToken];
    }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Private Methods
- (BOOL)shouldShowLocationSection {
    if ((self.cachedData == nil) || ([self.cachedData count] == 0)) {
        return NO;
    } else {
        return [CLLocationManager locationServicesEnabled];
    }
}


#pragma mark - Public Methods
- (NSArray*)dataForMainTableView {
    NSArray *data = [self.locationData allCategories];
    data = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
        FacilitiesCategory *c1 = (FacilitiesCategory*)obj1;
        FacilitiesCategory *c2 = (FacilitiesCategory*)obj2;
        
        return [c1.name compare:c2.name];
    }];
    
    return data;
}

- (NSArray*)resultsForSearchString:(NSString *)searchText {
    if (self.searchHelper == nil) {
        self.searchHelper = [[FacilitiesLocationSearch alloc] init];
    }
    
    self.searchHelper.category = nil;
    self.searchHelper.searchString = searchText;
    NSArray *results = [self.searchHelper searchResults];
    
    results = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [obj1 valueForKey:FacilitiesSearchResultDisplayStringKey];
        NSString *key2 = [obj2 valueForKey:FacilitiesSearchResultDisplayStringKey];

        return [key1 compare:key2
              options:(NSCaseInsensitiveSearch |
                       NSNumericSearch |
                       NSForcedOrderingSearch)];
    }];
    
    return results;
}

- (void)configureMainTableCell:(UITableViewCell *)cell
                  forIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 0) && ([self shouldShowLocationSection])) {
        cell.textLabel.text = @"Use my location";
    } else {
        FacilitiesCategory *cat = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = cat.name;
    }
}

- (void)configureSearchCell:(HighlightTableViewCell *)cell
                forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *loc = [self.filteredData objectAtIndex:indexPath.row];
    
    cell.highlightLabel.searchString = self.searchString;
    cell.highlightLabel.text = [loc objectForKey:FacilitiesSearchResultDisplayStringKey];
}


#pragma mark - Dynamic Setters/Getters
- (void)setFilterPredicate:(NSPredicate *)filterPredicate {
    self.cachedData = nil;
    _filterPredicate = filterPredicate;
}

- (NSArray*)cachedData {
    if (_cachedData == nil) {
        self.cachedData = [self dataForMainTableView];
    }
    
    return _cachedData;
}

- (NSArray*)filteredData {
    if (!_filteredData && [self.searchString length] > 0) {
        self.filteredData = [self resultsForSearchString:self.searchString];
    }
    
    return _filteredData;
}


#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *nextViewController = nil;
    
    if (tableView == self.tableView) {
        if ((indexPath.section == 0) && [self shouldShowLocationSection]) {
            nextViewController = [[FacilitiesUserLocationViewController alloc] init];
        } else {
            FacilitiesCategory *category = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
            FacilitiesLocationViewController *controller = [[FacilitiesLocationViewController alloc] init];
            controller.category = category;
            nextViewController = controller;
        }
    } else {
        if (indexPath.row == 0) {
            FacilitiesTypeViewController *vc = [[FacilitiesTypeViewController alloc] init];
            vc.userData = [NSDictionary dictionaryWithObject: self.searchString
                                                      forKey: FacilitiesRequestLocationUserBuildingKey];
            nextViewController = vc;
        } else {
            
            NSDictionary *dict = [self.filteredData objectAtIndex:indexPath.row-1];
            FacilitiesLocation *location = (FacilitiesLocation*)[dict objectForKey:FacilitiesSearchResultLocationKey];
            
            if ([location.isLeased boolValue]) {
                FacilitiesLeasedViewController *controller = [[FacilitiesLeasedViewController alloc] initWithLocation:location];
                
                nextViewController = controller;
            } else {
                FacilitiesRoomViewController *controller = [[FacilitiesRoomViewController alloc] init];
                controller.location = location;
                nextViewController = controller;
            }
        }
    }
    
    [self.navigationController pushViewController:nextViewController
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return ([self shouldShowLocationSection] ? 2 : 1);
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return ((section == 0) && [self shouldShowLocationSection]) ? 1 : [self.cachedData count];
    } else {
        return ([self.trimmedString length] > 0) ? [self.filteredData count] + 1 : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *facilitiesIdentifier = @"facilitiesCell";
    static NSString *searchIdentifier = @"searchCell";
    
    if (tableView == self.tableView) {
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:facilitiesIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:facilitiesIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        [self configureMainTableCell:cell 
                        forIndexPath:indexPath];
        return cell;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        HighlightTableViewCell *hlCell = nil;
        hlCell = (HighlightTableViewCell*)[tableView dequeueReusableCellWithIdentifier:searchIdentifier];
        
        if (hlCell == nil) {
            hlCell = [[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:searchIdentifier];
            
            hlCell.autoresizesSubviews = YES;
            hlCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (indexPath.row == 0) {
            hlCell.highlightLabel.searchString = nil;
            hlCell.highlightLabel.text = [NSString stringWithFormat:@"Use \"%@\"",self.searchString];
        } else {
            NSIndexPath *path = [NSIndexPath indexPathForRow:(indexPath.row-1)
                                                   inSection:indexPath.section];
            [self configureSearchCell:hlCell
                         forIndexPath:path];
        }
        
        
        return hlCell;
    } else {
        return nil;
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.trimmedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self.searchString isEqualToString:self.trimmedString]) {
        self.searchString = ([self.trimmedString length] > 0) ? self.trimmedString : nil;
        self.filteredData = nil;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchDisplayController setActive:NO
                                   animated:YES];
}

// Make sure tapping the status bar always scrolls to the top of the active table
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    self.tableView.scrollsToTop = NO;
    tableView.scrollsToTop = YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    // using willUnload because willHide strangely doesn't get called when the "Cancel" button is clicked
    tableView.scrollsToTop = NO;
    self.tableView.scrollsToTop = YES;
}

@end
