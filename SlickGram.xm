#import <UIKit/UIKit.h>
#define SGNotDefaultTabFrame(fr) (fr.origin.y > (SGKeyWindowRef.frame.size.height - 45.0))
#define SGKeyWindowRef [UIApplication sharedApplication].keyWindow
#define SGTabBarRef (((IGRootViewController *)SGKeyWindowRef.rootViewController).visibleViewController.tabBarController.tabBar)

/*********************** Instagram Forward-Declarations ***********************/

@interface IGRootViewController
@property (nonatomic,copy) UIViewController *visibleViewController;
@end

@interface IGTimelineHeaderView : UIView
@property (nonatomic,retain) UINavigationBar *navbar;
- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(float)arg2 andScrollDirectionIsUp:(BOOL)arg3;
@end

@interface IGMainFeedViewController : UIViewController
@property (nonatomic,retain) IGTimelineHeaderView* logoHeaderView;
@end

/***************** Static setFrame and Version-Check Functs *******************/

// Returns 1 if legacy supported, 2 if current supported, 0 if unsupported.
static NSUInteger sg_isSupportedVersionString(NSString *v) {
	if ([v isEqualToString:@"5.0.6"]) {
		NSLog(@"[SlickGram] Detected Instagram running on supported old version %@.", v);
		return 1;
	}

	else if ([@[@"5.0.7", @"5.0.8", @"5.0.9"] containsObject:v]) {
		NSLog(@"[SlickGram] Detected Instagram running on supported current version %@.", v);
		return 2;
	}

	else  {
		NSLog(@"[SlickGram] Detected Instagram running on unsupported version %@.", v);
		return 0;
	}
}

static void sg_slickTabBarForHeaderInWindow(UITabBar *bar, UIView *header, UIWindow *window) {
	CGRect slicked = bar.frame;
	slicked.origin.y = (window.frame.size.height - slicked.size.height) - (header.frame.origin.y - 20.0);
	[bar setFrame:slicked];
}

%group Preferences

/************************ Shared Preferences Cell Hook ************************/

%hook IGAccountSettingsViewController

-(NSInteger)tableView:(UITableView *)arg1 numberOfRowsInSection:(NSInteger)arg2 {
	return arg2 == 2 ? %orig() + 1 : %orig();
}

-(UITableViewCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	if (arg2.section == 2 && arg2.row == 3) {
		NSLog(@"[SlickGram] Squeezing in custom settings cell for %@.", arg2);
		UITableViewCell *styleCell = %orig(arg1, [NSIndexPath indexPathForRow:2 inSection:2]);
		styleCell.textLabel.text = @"SlickGram";

		UISwitch *styleCellSwitch = (UISwitch *) styleCell.accessoryView;
		[styleCellSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"SGEnabled"]];
		[styleCellSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
		[styleCellSwitch addTarget:self action:@selector(sg_switchChanged:) forControlEvents:UIControlEventValueChanged];
		return styleCell;
	}

	return %orig();
}

%new - (void)sg_switchChanged:(UISwitch *)sender {
	NSLog(@"[SlickGram] Detected state change of %@, setting enabled key...", sender);
	[[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"SGEnabled"];

	UIAlertView *stateChanged = [[UIAlertView alloc] initWithTitle:@"SlickGram" message:@"This option will override compatibility checks at launch. Please relaunch Instagram to apply." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[stateChanged show];
	[stateChanged release];
}

%end

%end // %group Preferences

/************************ Shared Tab Bar Rescue Hooks ************************/

%group Rescue

%hook IGMainFeedViewController

- (void)viewWillAppear:(BOOL)animated {
	NSLog(@"[SlickGram] Detected timeline view appearance, checking to re-capture...");
	sg_slickTabBarForHeaderInWindow(SGTabBarRef, self.logoHeaderView, SGKeyWindowRef);

	%orig();
}

- (void)viewWillDisappear:(BOOL)animated {
	NSLog(@"[SlickGram] Detected timeline view disappearing, checking to rescue...");
	UITabBar *tabBar = SGTabBarRef;
	UIWindow *keyWindow = SGKeyWindowRef;

	if (SGNotDefaultTabFrame(tabBar.frame)) {
		CGRect bestFrame = tabBar.frame;
		bestFrame.size.height = 45.0;
		bestFrame.origin.y = keyWindow.frame.size.height - bestFrame.size.height;
		tabBar.frame = bestFrame;
	}

	%orig();
}

%end

%end // %group Rescue

/**************************** Legacy TabBar Hooks ****************************/

%group Legacy // 5.0.6

%hook IGTimelineHeaderView

- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(float)arg2 andScrollDirectionIsUp:(BOOL)arg3 {
	%orig();

	UITabBar *tabBar = SGTabBarRef;
	UIWindow *keyWindow = SGKeyWindowRef;

	// Uh so I didn't really care how weird this frame math was when I made it,
	// and I'm now afraid to optimize it like I did the other stuff because I
	// can't test it. Just stay away. Far away.
	CGRect slicked = tabBar.frame;
	slicked.size.height -= (20.0 - self.frame.origin.y);
	slicked.origin.y = keyWindow.frame.size.height - slicked.size.height;

	[tabBar setFrame:slicked];
}

%end

%end // %group Legacy

/**************************** Current TabBar Hooks ****************************/

%group Current // 5.0.7, 5.0.8, 5.0.9

%hook IGTimelineHeaderView

- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(float)arg2 andScrollDirectionIsUp:(BOOL)arg3 {
	%orig();
	sg_slickTabBarForHeaderInWindow(SGTabBarRef, self, SGKeyWindowRef);
}

%end

%end // %group Current

/***************************** Logos Constructor *****************************/

%ctor {
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSUInteger supported = sg_isSupportedVersionString(version);
	BOOL userEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"SGEnabled"];
	BOOL alreadyChecked = [version isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"SGLastRanVersion"]];
	BOOL __block shouldEnable = (userEnabled && alreadyChecked) || (!alreadyChecked && supported);

	[[NSUserDefaults standardUserDefaults] setBool:shouldEnable forKey:@"SGEnabled"];
	[[NSUserDefaults standardUserDefaults] setObject:version forKey:@"SGLastRanVersion"];

	%init(Preferences);
	if (shouldEnable) {
		%init(Rescue);

		if (supported == 1) {	 // Legacy
			%init(Legacy);
		}

		else {					// Current Versions (5.0.7-5.0.9)
			%init(Current);
		}
	}

	// Unsupported
	else {
		[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
			if (shouldEnable) {
				NSLog(@"[SlickGram] Detected user running an incompatible version of Instagram (%@), prompting and rejecting hooks...", version);
				UIAlertView *incompatible = [[UIAlertView alloc] initWithTitle:@"SlickGram" message:[NSString stringWithFormat:@"Sorry, it appears your version of Instagram %@ isn't certified compatible with this release of SlickGram.  You can override this in Settings, as you contact @insanj for support!", version] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[incompatible show];
				[incompatible release];
			}
		}];
	}
}
