#import "MITNewsiPadViewController.h"
#import "MITNewsPadLayout.h"
#import "MITNewsModelController.h"
#import "MITNewsStory.h"
#import "MITNewsStoryCollectionViewCell.h"
#import "MITNewsConstants.h"

#import "MITNewsListViewController.h"
#import "MITNewsGridViewController.h"
#import "MITMobile.h"


@interface MITNewsiPadViewController (NewsDataSource) <MITNewsStoryDataSource,MITNewsStoryDelegate>
@property (nonatomic,strong) NSString *searchQuery;
@property (nonatomic,strong) NSOrderedSet *searchResults;

- (NSUInteger)numberOfCategories;
- (BOOL)isFeaturedCategoryAtIndex:(NSUInteger)index;
- (NSString*)titleForCategoryAtIndex:(NSUInteger)index;
- (NSUInteger)numberOfStoriesInCategoryAtIndex:(NSUInteger)index;
- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath;
@end

@interface MITNewsiPadViewController ()
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet MITNewsGridViewController *gridViewController;
@property (nonatomic, weak) IBOutlet MITNewsListViewController *listViewController;

@property (nonatomic, readonly, weak) UIViewController *activeViewController;
@property (nonatomic, getter=isSearching) BOOL searching;

#pragma mark Data Source
@property (nonatomic,readonly,strong) NSFetchedResultsController *storiesDataSource;

// We need this because there is no easy way to section (or sort) the featured stories.
// They should be displayed in the order the server spits them back and do not have a
// category definition of their own (featured stories will be a mix of stories from
// every category).
@property (nonatomic,readonly,strong) NSFetchedResultsController *featuredStoriesDataSource;
@property (nonatomic,strong) NSOrderedSet *featuredStories;

@property (nonatomic,copy) NSURL *nextPageURL;

@end

@implementation MITNewsiPadViewController {
    BOOL _isTransitioningToPresentationStyle;
}

@synthesize storiesDataSource = _storiesDataSource;
@synthesize activeViewController = _activeViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.gridViewController.collectionView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self showStoriesAsGrid:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Dynamic Properties
- (MITNewsGridViewController*)gridViewController
{
    if (![self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
        return nil;
    } else if (!_gridViewController) {
        MITNewsGridViewController *gridViewController = [[MITNewsGridViewController alloc] init];

        [self addChildViewController:_gridViewController];
        _gridViewController = gridViewController;
    }

    return _gridViewController;
}

- (MITNewsListViewController*)listViewController
{
    if (![self supportsPresentationStyle:MITNewsPresentationStyleList]) {
        return nil;
    } else if (!_listViewController) {
        MITNewsListViewController *listViewController = [[MITNewsListViewController alloc] init];

        [self addChildViewController:listViewController];
        _listViewController = listViewController;
    }
    
    return _listViewController;
}

- (void)setPresentationStyle:(MITNewsPresentationStyle)style
{
    [self setPresentationStyle:style animated:NO];
}

- (void)setPresentationStyle:(MITNewsPresentationStyle)style animated:(BOOL)animated
{
    NSAssert([self supportsPresentationStyle:style], @"presentation style %d is not supported on this device", style);

    if (![self supportsPresentationStyle:style]) {
        return;
    } else if ((_presentationStyle != style) || !self.activeViewController) {
        _presentationStyle = style;

        // Figure out which view controllers we are going to be
        // transitioning from/to.
        UIViewController *fromViewController = self.activeViewController;
        UIViewController *toViewController = nil;
        if (_presentationStyle == MITNewsPresentationStyleGrid) {
            toViewController = self.gridViewController;
        } else {
            toViewController = self.listViewController;
        }

        const CGRect viewFrame = self.containerView.bounds;
        fromViewController.view.frame = viewFrame;
        toViewController.view.frame = viewFrame;

        const NSTimeInterval animationDuration = (animated ? 0.25 : 0);
        _isTransitioningToPresentationStyle = YES;
        _activeViewController = toViewController;
        if (!fromViewController) {
            toViewController.view.alpha = 0.0;
            [self.containerView addSubview:toViewController.view];

            [UIView transitionWithView:self.containerView
                              duration:animationDuration
                               options:0
                            animations:^{
                                toViewController.view.alpha = 1.0;
                            } completion:^(BOOL finished) {
                                _isTransitioningToPresentationStyle = NO;
                            }];
        } else {
            [self transitionFromViewController:fromViewController
                              toViewController:toViewController
                                      duration:animationDuration
                                       options:0
                                    animations:nil
                                    completion:^(BOOL finished) {
                                        _isTransitioningToPresentationStyle = NO;
                                    }];
        }
    }
}

#pragma mark Utility Methods
- (BOOL)supportsPresentationStyle:(MITNewsPresentationStyle)style
{
    if (style == MITNewsPresentationStyleList) {
        return YES;
    } else if (style == MITNewsPresentationStyleGrid) {
        const CGFloat minimumWidthForGrid = 768.;
        const CGFloat boundsWidth = CGRectGetWidth(self.view.bounds);

        return (boundsWidth >= minimumWidthForGrid);
    }

    return NO;
}

#pragma mark UI Actions
- (IBAction)searchButtonWasTriggered:(UIBarButtonItem *)sender
{
    
}

- (IBAction)showStoriesAsGrid:(UIBarButtonItem *)sender
{
    self.presentationStyle = MITNewsPresentationStyleGrid;
}

- (IBAction)showStoriesAsList:(UIBarButtonItem *)sender
{
    self.presentationStyle = MITNewsPresentationStyleList;
}

- (void)updateNavigationItem:(BOOL)animated
{
    NSMutableArray *rightBarItems = [[NSMutableArray alloc] init];

    if (self.presentationStyle == MITNewsPresentationStyleList) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
            UIBarButtonItem *gridItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(showStoriesAsGrid:)];
            [rightBarItems addObject:gridItem];
        }
    } else if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleList]) {
            UIImage *listImage = [UIImage imageNamed:@"map/item_list"];
            UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:listImage style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesAsList:)];
            [rightBarItems addObject:listItem];
        }
    }
    
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonWasTriggered:)];
    [rightBarItems addObject:searchItem];
    
    [self.navigationItem setRightBarButtonItems:rightBarItems animated:animated];
}

@end

@implementation MITNewsiPadViewController (NewsDataSource)
- (BOOL)canLoadMoreItems
{
    return (BOOL)(self.nextPageURL != nil);
}

- (void)loadMoreItems:(void(^)(NSError *error))block
{
    [[MITMobile defaultManager] getObjectsForURL:self.nextPageURL completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        
    }];
}

- (void)reloadItems:(void(^)(NSError *error))block
{

}

- (NSUInteger)numberOfCategories
{
    return [self.storiesDataSource.sections count];
}

- (BOOL)isFeaturedCategoryAtIndex:(NSUInteger)index
{
    if (self.isSearching) {
        return NO;
    } else if (self.showsFeaturedStories && (index == 0)) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString*)titleForCategoryAtIndex:(NSUInteger)index
{
    if (self.isSearching) {
        return nil;
    } else if (self.showsFeaturedStories && (index == 0)) {
        return @"Featured";
    } else if ([self numberOfCategories] == 1) {
        return nil;
    } else {
        return @"My Category's Name";
    }
}

- (NSUInteger)numberOfStoriesInCategoryAtIndex:(NSUInteger)index
{
    if (self.isSearching) {
        return [self.searchResults count];
    }
    return 0;
}

- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndex:(NSUInteger)index
{
    return [self storyAtIndex:index];
}

@end
