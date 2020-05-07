//
// UTCMenuClockAppDelegate.m
// UTCMenuClock
//
// Created by John Adams on 11/14/11.
//
// Copyright 2011-2016 John Adams
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "UTCMenuClockAppDelegate.h"
#import "LaunchAtLoginController.h"

static NSString *const showDatePreferenceKey = @"ShowDate";
static NSString *const showSecondsPreferenceKey = @"ShowSeconds";
static NSString *const showJulianDatePreferenceKey = @"ShowJulianDate";
static NSString *const showTimeZonePreferenceKey = @"ShowTimeZone";
static NSString *const show24HourPreferenceKey = @"24HRTime";
static NSString *const useUtcTimezonePreferenceKey = @"UseUtcTimezone";

@implementation UTCMenuClockAppDelegate

@synthesize window;
@synthesize mainMenu;

NSStatusItem *ourStatus;
NSMenuItem *dateMenuItem;
NSMenuItem *showTimeZoneItem;
NSMenuItem *show24HrTimeItem;

- (void) quitProgram:(id)sender {
    // Cleanup here if necessary...
    [[NSApplication sharedApplication] terminate:nil];
}

- (void) toggleLaunch:(id)sender {
    NSInteger state = [sender state];
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];

    if (state == NSOffState) {
        [sender setState:NSOnState];
        [launchController setLaunchAtLogin:YES];
    } else {
        [sender setState:NSOffState];
        [launchController setLaunchAtLogin:NO];
    }

    [launchController release];
}

- (BOOL) fetchBooleanPreference:(NSString *)preference {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    BOOL value = [standardUserDefaults boolForKey:preference];
    return value;
}

- (void) togglePreference:(id)sender {
    NSInteger state = [sender state];
    NSString *preference = [sender representedObject];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    if (state == NSOffState) {
        [sender setState:NSOnState];
        [standardUserDefaults setBool:TRUE forKey:preference];
    } else {
        [sender setState:NSOffState];
        [standardUserDefaults setBool:FALSE forKey:preference];
    }

}

- (void) openGithubURL:(id)sender {
    [[NSWorkspace sharedWorkspace]
        openURL:[NSURL URLWithString:@"http://github.com/YF-Tung/EpochTimeConverter"]];
}

- (BOOL) isEpochValid:(double)epoch {
    // Between 2000 to 2040
    return 946684800 < epoch && epoch < 2208988800;
}

- (void) doDateUpdate {

    NSString *pbtext = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
    double pbval = [pbtext doubleValue];
    if (pbval > 1e10) pbval /= 1000;

    //NSDate* date = [NSDate date];
    NSDate* date = [[NSDate alloc] initWithTimeIntervalSince1970:pbval];
    NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter* dateDF = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter* dateShortDF = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter* daynum = [[[NSDateFormatter alloc] init] autorelease];

    BOOL useUtcTimezone = [self fetchBooleanPreference:useUtcTimezonePreferenceKey];
    BOOL showDate = [self fetchBooleanPreference:showDatePreferenceKey];
    BOOL showSeconds = [self fetchBooleanPreference:showSecondsPreferenceKey];
    BOOL showJulian = [self fetchBooleanPreference:showJulianDatePreferenceKey];
    BOOL showTimeZone = [self fetchBooleanPreference:showTimeZonePreferenceKey];
    BOOL show24HrTime = [self fetchBooleanPreference:show24HourPreferenceKey];

    NSTimeZone* tz;
    if (useUtcTimezone) {
        tz = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    } else {
        tz = [NSTimeZone localTimeZone];
    }

    [df setTimeZone: tz];
    [dateDF setTimeZone: tz];
    [dateShortDF setTimeZone: tz];
    [daynum setTimeZone: tz];

    if (showSeconds) {
        if (show24HrTime){
            [df setDateFormat: @"HH:mm:ss"];
        } else {
            [df setDateFormat: @"hh:mm:ss a"];
        }
    } else {
        if (show24HrTime){
            [df setDateFormat: @"HH:mm"];
        } else {
            [df setDateFormat: @"hh:mm a"];
        }
    }
    [dateDF setDateStyle:NSDateFormatterFullStyle];
    [dateShortDF setDateStyle:NSDateFormatterShortStyle];
    [daynum setDateFormat:@"D/"];

    NSString* timepart = [df stringFromDate: date];
    NSString* datepart = [dateDF stringFromDate: date];
    NSString* dateShort = [dateShortDF stringFromDate: date];
    NSString* julianDay;
    NSString* tzString;

    if (showJulian) {
        julianDay = [daynum stringFromDate: date];
    } else {
        julianDay = @"";
    }

    if (showTimeZone) {
        tzString = [NSString stringWithFormat:@" %@", [tz abbreviation]];
    } else {
        tzString = @"";
    }

    if ([self isEpochValid:pbval]) {
        int pbint = (int)pbval;
        if (showDate) {
            [ourStatus setTitle:[NSString stringWithFormat:@"%d = %@ %@%@%@", pbint, dateShort, julianDay, timepart, tzString]];
        } else {
            [ourStatus setTitle:[NSString stringWithFormat:@"%d = %@%@%@", pbint, julianDay, timepart, tzString]];
        }
    } else {
        [ourStatus setTitle:@""];
    }

    [dateMenuItem setTitle:datepart];

}

- (IBAction)showFontMenu:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setDelegate:self];

    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:sender];
}
// this is the main work loop, fired on 1s intervals.
- (void) fireTimer:(NSTimer*)theTimer {
    [self doDateUpdate];
}

- (id)init {
    if (self = [super init]) {
        // set our default preferences at each launch.

        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *appDefaults = @{useUtcTimezonePreferenceKey: @NO,
                                      showTimeZonePreferenceKey: @YES,
                                      show24HourPreferenceKey: @YES,
                                      showJulianDatePreferenceKey: @NO,
                                      showDatePreferenceKey: @NO,
                                      showSecondsPreferenceKey: @NO};
        [standardUserDefaults registerDefaults:appDefaults];
        NSString *dateKey    = @"dateKey";
        //Remove old, outdated date key
        [standardUserDefaults removeObjectForKey:dateKey];
    }
    return self;

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    [self doDateUpdate];

}

- (void)awakeFromNib
{
    mainMenu = [[NSMenu alloc] init];

    //Create Image for menu item
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    NSStatusItem *theItem;
    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [theItem retain];
    // retain a reference to the item so we don't have to find it again
    ourStatus = theItem;

    //Set Image
    //[theItem setImage:(NSImage *)menuicon];
    [theItem setTitle:@""];

    //Make it turn blue when you click on it
    [theItem setHighlightMode:YES];
    [theItem setEnabled: YES];

    // build the menu
    NSMenuItem *mainItem = [[NSMenuItem alloc] init];
    dateMenuItem = mainItem;

    NSMenuItem *cp1Item = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *cp2Item = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *cp3Item = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *quitItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *launchItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *showDateItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *useUtcTimezoneItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *show24Item = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *showSecondsItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *showJulianItem = [[[NSMenuItem alloc] init] autorelease];
 //   NSMenuItem *changeFontItem = [[[NSMenuItem alloc] init] autorelease];

    showTimeZoneItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *sep1Item = [NSMenuItem separatorItem];
    NSMenuItem *sep2Item = [NSMenuItem separatorItem];
    NSMenuItem *sep3Item = [NSMenuItem separatorItem];
    NSMenuItem *sep4Item = [NSMenuItem separatorItem];

    [mainItem setTitle:@""];

    [cp1Item setTitle:@"UTC Menu Clock v1.2.3"];
    [cp2Item setTitle:@"jna@retina.net"];
    [cp3Item setTitle:@"http://github.com/netik/UTCMenuClock"];

    [cp3Item setEnabled:TRUE];
    [cp3Item setAction:@selector(openGithubURL:)];

    [launchItem setTitle:@"Open at Login"];
    [launchItem setEnabled:TRUE];
    [launchItem setAction:@selector(toggleLaunch:)];

    [useUtcTimezoneItem setTitle:@"Use UTC Timezone"];
    [useUtcTimezoneItem setEnabled:TRUE];
    [useUtcTimezoneItem setAction:@selector(togglePreference:)];
    [useUtcTimezoneItem setRepresentedObject:useUtcTimezonePreferenceKey];

    [show24Item setTitle:@"24 HR Time"];
    [show24Item setEnabled:TRUE];
    [show24Item setAction:@selector(togglePreference:)];
    [show24Item setRepresentedObject:show24HourPreferenceKey];

    [showDateItem setTitle:@"Show Date"];
    [showDateItem setEnabled:TRUE];
    [showDateItem setAction:@selector(togglePreference:)];
    [showDateItem setRepresentedObject:showDatePreferenceKey];

    [showSecondsItem setTitle:@"Show Seconds"];
    [showSecondsItem setEnabled:TRUE];
    [showSecondsItem setAction:@selector(togglePreference:)];
    [showSecondsItem setRepresentedObject:showSecondsPreferenceKey];

    [showJulianItem setTitle:@"Show Julian Date"];
    [showJulianItem setEnabled:TRUE];
    [showJulianItem setAction:@selector(togglePreference:)];
    [showJulianItem setRepresentedObject:showJulianDatePreferenceKey];

    [showTimeZoneItem setTitle:@"Show Time Zone"];
    [showTimeZoneItem setEnabled:TRUE];
    [showTimeZoneItem setAction:@selector(togglePreference:)];
    [showTimeZoneItem setRepresentedObject:showTimeZonePreferenceKey];

 //   [changeFontItem setTitle:@"Change Font..."];
  //  [changeFontItem setAction:@selector(showFontMenu:)];

    [quitItem setTitle:@"Quit"];
    [quitItem setEnabled:TRUE];
    [quitItem setAction:@selector(quitProgram:)];

    [mainMenu addItem:mainItem];
    // "---"
    [mainMenu addItem:sep2Item];
    // "---"
    [mainMenu addItem:cp1Item];
    [mainMenu addItem:cp2Item];
    // "---"
    [mainMenu addItem:sep1Item];
    [mainMenu addItem:cp3Item];
    // "---"
    [mainMenu addItem:sep3Item];

    // showDateItem
    BOOL showDate = [self fetchBooleanPreference:showDatePreferenceKey];
    BOOL showSeconds = [self fetchBooleanPreference:showSecondsPreferenceKey];
    BOOL showJulian = [self fetchBooleanPreference:showJulianDatePreferenceKey];
    BOOL showTimeZone = [self fetchBooleanPreference:showTimeZonePreferenceKey];
    BOOL show24HrTime = [self fetchBooleanPreference:show24HourPreferenceKey];
    BOOL useUtcTimezone = [self fetchBooleanPreference:useUtcTimezonePreferenceKey];

    // TODO: DRY this up a bit.

    if (useUtcTimezone) {
        [useUtcTimezoneItem setState:NSOnState];
    } else {
        [useUtcTimezoneItem setState:NSOffState];
    }

    if (show24HrTime) {
        [show24Item setState:NSOnState];
    } else {
        [show24Item setState:NSOffState];
    }

    if (showDate) {
        [showDateItem setState:NSOnState];
    } else {
        [showDateItem setState:NSOffState];
    }

    if (showSeconds) {
        [showSecondsItem setState:NSOnState];
    } else {
        [showSecondsItem setState:NSOffState];
    }

    if (showJulian) {
        [showJulianItem setState:NSOnState];
    } else {
        [showJulianItem setState:NSOffState];
    }

    if (showTimeZone) {
        [showTimeZoneItem setState:NSOnState];
    } else {
        [showTimeZoneItem setState:NSOffState];
    }

    // latsly, deal with Launch at Login
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    BOOL launch = [launchController launchAtLogin];
    [launchController release];

    if (launch) {
        [launchItem setState:NSOnState];
    } else {
        [launchItem setState:NSOffState];
    }

    [mainMenu addItem:launchItem];
    [mainMenu addItem:useUtcTimezoneItem];
    [mainMenu addItem:show24Item];
    [mainMenu addItem:showDateItem];
    [mainMenu addItem:showSecondsItem];
    [mainMenu addItem:showJulianItem];
    [mainMenu addItem:showTimeZoneItem];
  //  [mainMenu addItem:changeFontItem];
    // "---"
    [mainMenu addItem:sep4Item];
    [mainMenu addItem:quitItem];

    [theItem setMenu:(NSMenu *)mainMenu];

    // Update the date immediately after setup so that there is no timer lag
    [self doDateUpdate];

    NSNumber *myInt = [NSNumber numberWithInt:1];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:) userInfo:myInt repeats:YES];


}

@end
