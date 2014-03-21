#import <UIKit/UIKit.h>

@interface IGRootViewController
@property (nonatomic,copy) UIViewController *visibleViewController;
@end

@interface IGTimelineHeaderView : UIView
@property (nonatomic,retain) UINavigationBar *navbar;
- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(float)arg2 andScrollDirectionIsUp:(BOOL)arg3;
@end

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

%group Version507

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

%end // %group Version507

%ctor {
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

	if ([version isEqualToString:@"5.0.6"]) {
		NSLog(@"[SlickGram] Detected user running on Instagram version %@, hooking in now...", version);
		%init(Version506);
	}

	else if ([version isEqualToString:@"5.0.7"]) {
		NSLog(@"[SlickGram] Detected user running on Instagram version %@, hooking in now...", version);
		%init(Version507);
	}

	else {
		[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
			NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
			NSString *last = [[NSUserDefaults standardUserDefaults] objectForKey:@"SGLastRanVersion"];

			if (![version isEqualToString:last]) {
				[[NSUserDefaults standardUserDefaults] setObject:version forKey:@"SGLastRanVersion"];
				NSLog(@"[SlickGram] Detected user running an incompatible version of Instagram (%@), prompting and rejecting hooks...", version);
				UIAlertView *incompatible = [[UIAlertView alloc] initWithTitle:@"SlickGram" message:[NSString stringWithFormat:@"Sorry, it appears your version of Instagram %@ isn't certified compatible with this release of SlickGram. Please contact @insanj to demand support!", version] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[incompatible show];
				[incompatible release];
			}
		}];
	}
}
