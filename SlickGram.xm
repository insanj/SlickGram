#import "SlickGram.h"

#define SGLOG(fmt, ...) NSLog((@"[SlickGram] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

/*
                                                            ____                  
            ..'''' |         |       .'.       |`````````, |            |``````.  
         .''       |_________|     .''```.     |'''|'''''  |______      |       | 
      ..'          |         |   .'       `.   |    `.     |            |       | 
....''             |         | .'           `. |      `.   |___________ |......'  
                                                                                  
*/

static void sg_slickTabBarForHeaderInWindow(UIView *header) {
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	UITabBar *tabBar = ((IGRootViewController *)window.rootViewController).visibleViewController.tabBarController.tabBar;

	CGRect slicked = tabBar.frame;
	slicked.origin.y = (window.frame.size.height - slicked.size.height) - (header.frame.origin.y - 20.0);
	tabBar.frame = slicked;
}

%group Shared

%hook IGMainFeedViewController

- (void)viewWillAppear:(BOOL)animated {
	SGLOG(@"Detected timeline view appearance, checking to re-capture...");
	sg_slickTabBarForHeaderInWindow(self.logoHeaderView);

	%orig();
}

- (void)viewWillDisappear:(BOOL)animated {
	SGLOG(@"Detected timeline view disappearing, checking to rescue...");
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	UITabBar *tabBar = ((IGRootViewController *)window.rootViewController).visibleViewController.tabBarController.tabBar;

	if (tabBar.frame.origin.y > window.frame.size.height - 45.0) {
		CGRect bestFrame = tabBar.frame;
		bestFrame.size.height = 45.0;
		bestFrame.origin.y = window.frame.size.height - bestFrame.size.height;
		tabBar.frame = bestFrame;
	}

	%orig();
}

%end

%end // %group Shared

/*
 ___________                                              
|            | |`````````,             ..'''' `````|````` 
|______      | |'''|'''''           .''            |      
|            | |    `.           ..'               |      
|            | |      `.   ....''                  |      
                                                        
*/

%group FirstSupportPhase 

%hook IGTimelineHeaderView

- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(CGFloat)arg2 andScrollDirectionIsUp:(BOOL)arg3 {
	%orig();
	sg_slickTabBarForHeaderInWindow(self);
}

%end

%end // %group FirstSupportPhase

/*

                    ____           ______      ______                             
            ..'''' |             .~      ~.  .~      ~.  |..          | |``````.  
         .''       |______      |           |          | |  ``..      | |       | 
      ..'          |            |           |          | |      ``..  | |       | 
....''             |___________  `.______.'  `.______.'  |          ``| |......'  
                                                                                  
*/

%group  SecondSupportPhase

%hook IGTimelineHeaderView

-(void)updateAppearanceWithAbsoluteOffset:(CGFloat)arg1 {
	%orig();
	sg_slickTabBarForHeaderInWindow(self);
}

%end

%end // %group SecondSupportPhase


/***************************** Logos Constructor *****************************/

%ctor {
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSComparisonResult supportedVersionComparisonResult = [version compare:@"6.1.3" options:NSNumericSearch];

	%init(Shared);

	BOOL knownSupportedVersion = NO;
	if (supportedVersionComparisonResult == NSOrderedDescending || (knownSupportedVersion = supportedVersionComparisonResult == NSOrderedSame)) {
		SGLOG(@"Detected Instagram running on %@known supported version %@.", knownSupportedVersion ? @"" : @"un", version);
		%init(SecondSupportPhase);
	}

	else {
		SGLOG(@"Detected Instagram running on most likely unsupported old version %@.", version);
		%init(FirstSupportPhase);
	}
}
