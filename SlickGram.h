#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "substrate.h"

@interface IGRootViewController

@property (nonatomic, copy) UIViewController *visibleViewController;

@end

@interface IGTimelineHeaderView : UIView

@property (nonatomic, retain) UINavigationBar *navbar;

// iOS 8
-(void)updateAppearanceWithAbsoluteOffset:(CGFloat)arg1;

// iOS 7
- (void)updateAppearanceWithParentScrollView:(id)arg1 baseOffset:(CGFloat)arg2 andScrollDirectionIsUp:(BOOL)arg3;
@end

@interface IGMainFeedViewController : UIViewController

@property (nonatomic, retain) IGTimelineHeaderView *logoHeaderView;

@end