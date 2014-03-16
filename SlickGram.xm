#import <UIKit/UIKit.h>

@interface IGRootViewController
@property (nonatomic,copy) UIViewController *visibleViewController;
@end

@interface IGTimelineHeaderView : UIView
@end

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
