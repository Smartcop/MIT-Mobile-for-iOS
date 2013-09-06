#import "FacilitiesRootViewController.h"

#import "FacilitiesCategoryViewController.h"
#import "UIKit+MITAdditions.h"
#import "SecondaryGroupedTableViewCell.h"

static NSString* const kFacilitiesEmailAddress = @"txtdof@mit.edu";
static NSString* const kFacilitiesPhoneNumber = @"617.253.4948";

#pragma mark -
@implementation FacilitiesRootViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Building Services";
    }
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor mit_backgroundColor];
    self.textView.backgroundColor = [UIColor clearColor];
    [self.tableView applyStandardColors];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.textView = nil;
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


#pragma mark - UITableViewDelegate Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        default:
            return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reportCellIdentifier = @"FacilitiesCell";
    static NSString *contactCellIdentifier = @"ContactCell";

    UITableViewCell *cell = nil;

    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:reportCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:reportCellIdentifier];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:contactCellIdentifier];
        if (cell == nil) {
            cell = [[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:contactCellIdentifier];
        }
    }

    switch (indexPath.section) {
        case 0:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Report a Problem";
            break;
        }
        
        case 1:
        {
            SecondaryGroupedTableViewCell *customCell = (SecondaryGroupedTableViewCell *)cell;
            customCell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
            customCell.accessoryType = UITableViewCellAccessoryNone;
            customCell.textLabel.backgroundColor = [UIColor clearColor];
            customCell.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            switch (indexPath.row) {
                case 0:
                    customCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                    customCell.textLabel.text = @"Email Facilities";
                    customCell.secondaryTextLabel.text = [NSString stringWithFormat:@"(%@)",kFacilitiesEmailAddress];
                    break;
                case 1:
                    customCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                    customCell.textLabel.text =  @"Call Facilities";
                    customCell.secondaryTextLabel.text = [NSString stringWithFormat:@"(%@)",kFacilitiesPhoneNumber];
                    break;
                default:
                    break;
            }
        }

        default:
            break;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 0)) {
        FacilitiesCategoryViewController *vc = [[FacilitiesCategoryViewController alloc] init];
        [self.navigationController pushViewController:vc
                                             animated:YES];
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
            {
                if ([MFMailComposeViewController canSendMail]) {
                    MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
                    [mailView setMailComposeDelegate:self];
                    [mailView setSubject:@"Request from Building Services"];
                    [mailView setToRecipients:[NSArray arrayWithObject:kFacilitiesEmailAddress]];
                    [self presentModalViewController:mailView
                                            animated:YES]; 
                }
                break;
            }
                
            case 1:
            {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://1%@",kFacilitiesPhoneNumber]];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
                break;
            }
            
            default:
                /* Do Nothing */
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}

#pragma mark - MFMailComposeViewController delegation
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
	[self dismissModalViewControllerAnimated:YES];
}
@end
