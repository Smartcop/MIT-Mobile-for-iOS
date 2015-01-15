#import "EmergencyData.h"
#import "MIT_MobileAppDelegate.h"
#import "Foundation+MITAdditions.h"
#import "EmergencyModule.h"
#import "MITEmergencyInfoWebservices.h"
#import "MITEmergencyInfoAnnouncement.h"
#import "MITEmergencyInfoContact.h"

@interface EmergencyData ()
@property (nonatomic,copy) NSArray *allPhoneNumbers;
@property (nonatomic, copy) NSArray *primaryPhoneNumbers;
@property (copy) NSArray *contacts;
@property (nonatomic, strong) NSString *announcementHTML;
@property (nonatomic, strong) NSDate *lastUpdated;
@end

@implementation EmergencyData
@dynamic htmlString;

NSString * const EmergencyMessageLastRead = @"EmergencyLastRead";

#pragma mark -
#pragma mark Singleton Boilerplate

+ (EmergencyData *)sharedData {
    static EmergencyData *sharedEmergencyData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEmergencyData = [[self alloc] init];
    });

    return sharedEmergencyData;
}
#pragma mark -
#pragma mark Initialization
- (id) init {
    self = [super init];
    if (self != nil) {
        // TODO: get primary numbers from m.mit.edu (it's unlikely, but numbers might change)
        self.primaryPhoneNumbers = @[@{@"title" : @"Campus Police",
                                       @"phone" : @"617.253.1212"},
                                     @{@"title" : @"MIT Medical",
                                       @"phone" : @"617.253.1311"},
                                     @{@"title" : @"Emergency Status",
                                       @"phone" : @"617.253.7669"}];
        
        [self checkForEmergencies];
        [self reloadContacts];
    }
    return self;
}

#pragma mark -
#pragma mark Accessors

- (NSString *)htmlString
{
    NSDate *lastUpdated = self.lastUpdated;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/d/y h:mm a zz"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *lastUpdatedString = [formatter stringFromDate:lastUpdated];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"emergency_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        DDLogError(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
        return nil;
    }
    
    NSDictionary *templates = @{@"__BODY__" : self.announcementHTML,
                                @"__POST_DATE__" : lastUpdatedString};
    [htmlString replaceOccurrencesOfStrings:[templates allKeys] withStrings:[templates allValues] options:NSLiteralSearch];
    
    return htmlString;
}

#pragma mark -
#pragma mark Server requests

// Send request
- (void)checkForEmergencies
{
    __weak EmergencyData *weakSelf = self;
    [MITEmergencyInfoWebservices getEmergencyAnnouncement:^(NSArray *announce, NSError *error) {
        MITEmergencyInfoAnnouncement *announcement = (MITEmergencyInfoAnnouncement *)announce[0];
        EmergencyData *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"request for :%@ failed with error %@",@"emergency",[error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidFailToLoadNotification object:blockSelf];
        } else {
            
            self.lastUpdated = announcement.published_at;
            
            self.announcementHTML = announcement.announcementHTML;
            
            // notify listeners that this is a new emergency
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidChangeNotification object:blockSelf];
            
            // notify listeners that the info is done loading, regardless of whether it's changed
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidLoadNotification object:blockSelf];
        }
    }];
}

// request contacts
- (void)reloadContacts
{
    __weak EmergencyData *weakSelf = self;
    [MITEmergencyInfoWebservices getEmergencyContacts:^(NSArray *contacts, NSError *error) {
    EmergencyData *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"request failed for :%@/%@ with error %@",@"emergency",@"contacts",[error localizedDescription]);
        } else {
            // delete all of the old numbers
            
            blockSelf.allPhoneNumbers = contacts;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyContactsDidLoadNotification object:self];
        }
    }];
}

@end
