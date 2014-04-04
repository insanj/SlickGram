#import <UIKit/UIKit.h>

/*********************** Instagram Forward-Declarations ***********************/

@interface IGRootViewController
@property (nonatomic,copy) UIViewController *visibleViewController;
@end

@interface IGTimelineHeaderView : UIView
@property (nonatomic,retain) UINavigationBar *navbar;
- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(float)arg2 andScrollDirectionIsUp:(BOOL)arg3;
@end

/*********************** Static Version Checking Functs ***********************/

// Returns 1 if legacy supported, 2 if current supported, 0 if unsupported.
BOOL sg_isSupportedVersionString(NSString *v) {
	if ([v isEqualToString:@"5.0.6"]) {
		NSLog(@"[SlickGram] Detected Instagram running on supported old version %@.", v);
		return 1;
	}

	else if ([v isEqualToString:@"5.0.7"] || [v isEqualToString:@"5.0.8"]) {
		NSLog(@"[SlickGram] Detected Instagram running on supported current version %@.", v);
		return 2;
	}

	else  {
		NSLog(@"[SlickGram] Detected Instagram running on unsupported version %@.", v);
		return 0;
	}
}

/*********************** "Shared" Preferences Cell Hook ***********************/

%group Shared // Preferences

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

%end // %group Shared

/**************************** Legacy TabBar Hooks ****************************/

%group Version506

%hook IGTimelineHeaderView

- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(float)arg2 andScrollDirectionIsUp:(BOOL)arg3 {
	%orig();

	UIWindow *keyWindow =  [UIApplication sharedApplication].keyWindow;
	UITabBar *tabBar = ((IGRootViewController *) keyWindow.rootViewController).visibleViewController.tabBarController.tabBar;

	NSLog(@"[SlickGram] Slicking %@ to concord with %@...", tabBar, arg1);
	CGRect slicked = tabBar.frame;
	slicked.size.height -= (20.0 - self.frame.origin.y);
	slicked.origin.y = keyWindow.frame.size.height - slicked.size.height;

	[tabBar setFrame:slicked];
}

%end

%end // %group Version506

/**************************** Current TabBar Hooks ****************************/

%group Current // 5.0.7, 5.0.8

%hook IGTimelineHeaderView

- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(float)arg2 andScrollDirectionIsUp:(BOOL)arg3 {
	%orig();

	UIWindow *keyWindow =  [UIApplication sharedApplication].keyWindow;
	UITabBar *tabBar = ((IGRootViewController *) keyWindow.rootViewController).visibleViewController.tabBarController.tabBar;

	CGRect slicked = tabBar.frame;
	slicked.origin.y = (keyWindow.frame.size.height - slicked.size.height) - (self.frame.origin.y - 20.0);
	[tabBar setFrame:slicked];
}

%end

%end // %group Current

/***************************** Logos Constructor *****************************/

%ctor {
	%init(Shared);
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSUInteger supported = sg_isSupportedVersionString(version);
	BOOL userEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"SGEnabled"];
	BOOL alreadyChecked = [version isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"SGLastRanVersion"]];
	BOOL __block shouldEnable = (userEnabled && alreadyChecked) || (!alreadyChecked && supported);

	[[NSUserDefaults standardUserDefaults] setBool:shouldEnable forKey:@"SGEnabled"];
	[[NSUserDefaults standardUserDefaults] setObject:version forKey:@"SGLastRanVersion"];

	// Legacy
	if (shouldEnable && supported == 1) {
		%init(Version506);
	}

	// Legacy
	else if (shouldEnable) {
		%init(Current);
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
