#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <IOKit/hid/IOHIDEvent.h>
@interface SpringBoard
- (void)_simulateHomeButtonPress;
- (void)_menuButtonUp:(IOHIDEventRef)up;
- (void)_menuButtonDown:(IOHIDEventRef)down;
- (void)activateSiri;
- (void)takeScreenshot;
- (void)dismissMenu;
@end
@interface AXSpringBoardServer
+ (id)server;
- (void)openAppSwitcher;
- (void)takeScreenshot;
- (BOOL)openSiri;
@end
@protocol _SBScreenshotProvider // iOS 9.2+
- (UIImage *)captureScreenshot;
@end

@interface _SBScreenshotPersistenceCoordinator : NSObject // iOS 9.2+
- (BOOL)isSaving;
- (BOOL)_isWritingSnapshot;
- (void)saveScreenshot:(UIImage *)image withCompletion:(void (^)())completionBlock;
@end

@interface SBScreenshotManager : NSObject // iOS 9.2+
- (NSObject <_SBScreenshotProvider> *)_providerForScreen:(UIScreen *)screen;
- (void)saveScreenshotsWithCompletion:(void (^)())completionBlock;
@end

@interface UIApplication (iOS92)
- (SBScreenshotManager *)screenshotManager;
@end
UIWindow *home = nil;
UIWindow *tutorial = nil;
UIWindow *menu = nil;
UIWindow *menuGestureWindow = nil;
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1 {
%orig;
// Add an UIWindow
home = [[UIWindow alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 25,[UIScreen mainScreen].bounds.size.height / 3 + 15,30,50)];
home.backgroundColor = [UIColor clearColor];
home.hidden = NO;
home.windowLevel = 9998;
home.layer.masksToBounds = YES;
home.layer.cornerRadius = 7.0;
// Add some bluuuuuuur
UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
UIVisualEffectView *blurView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
blurView.frame = home.bounds;
[home addSubview:blurView];
// Gesture recognizer? Huh? Um, ok.
UITapGestureRecognizer *singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(getMeHome)] autorelease];
singleTap.numberOfTapsRequired = 1;
[home addGestureRecognizer:singleTap];
UITapGestureRecognizer *doubleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(multitask)] autorelease];
doubleTap.numberOfTapsRequired = 2;
[home addGestureRecognizer:doubleTap];
[singleTap requireGestureRecognizerToFail:doubleTap];
// Hold gesture
UILongPressGestureRecognizer *rightLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu)];
rightLongPressRecognizer.delegate = nil;
// rightLongPressRecognizer.tag = PRESS_RIGHT_TAG;
[rightLongPressRecognizer setMinimumPressDuration:1.0];
[home addGestureRecognizer:rightLongPressRecognizer];
// Add a tutorial screen, I suppose
if (![[NSUserDefaults standardUserDefaults] boolForKey:@"iWantHomeTutorialWasShown"]) {
// Wasn't shown, just do it!
// Bluuuuuur again
tutorial = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
tutorial.hidden = NO;
tutorial.windowLevel = 9999;
UIVisualEffectView *tutorialBlurView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
tutorialBlurView.frame = tutorial.bounds;
[tutorial addSubview:tutorialBlurView];
UITapGestureRecognizer *dismissTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTutorial)] autorelease];
dismissTap.numberOfTapsRequired = 1;
[tutorial addGestureRecognizer:dismissTap];
// Some text
UILabel *helloLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,50,[UIScreen mainScreen].bounds.size.width,50)];
helloLabel.text = @"Installed iWantHome";
helloLabel.backgroundColor = [UIColor clearColor];
helloLabel.textColor = [UIColor whiteColor];
helloLabel.textAlignment = UITextAlignmentCenter;
helloLabel.numberOfLines = 2;
[helloLabel setFont:[UIFont systemFontOfSize:30]];
[tutorial addSubview:helloLabel];
UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,10,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 50)];
textLabel.text = @"iWantHome was installed.\nNow you can start using it.\nJust tap anywhere on the screen to dismiss that screen.\nAdter this, a small black suqircle will appear at the right of the screen.\nTap it once to exit an app.\nTap it twice to open the App Switcher.\nHold it for all the other actions menu.\n\n\nBe sure to support me by following me on Twitter or reddit!";
textLabel.backgroundColor = [UIColor clearColor];
textLabel.textColor = [UIColor whiteColor];
textLabel.textAlignment = UITextAlignmentCenter;
textLabel.numberOfLines = 20;
[textLabel setFont:[UIFont systemFontOfSize:20]];
[tutorial addSubview:textLabel];
[home setAlpha:0];
// Save that it was shown
[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"iWantHomeTutorialWasShown"];
[[NSUserDefaults standardUserDefaults] synchronize];
}
else {
// Was already shown, do nothing
}
}
%new
- (void)getMeHome {
// iOS 7 - 9
if(SYSTEM_VERSION_LESS_THAN(@"10.0")) {
uint64_t timeStamp = mach_absolute_time();
IOHIDEventRef event = IOHIDEventCreate(kCFAllocatorDefault, kIOHIDEventTypeKeyboard, *(AbsoluteTime *)&timeStamp, 0);
SpringBoard *springBoard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
[springBoard _menuButtonDown:event];
[springBoard _menuButtonUp:event];
CFRelease(event);
}
// iOS 10
[(SpringBoard *)[UIApplication sharedApplication] _simulateHomeButtonPress];
}
%new
- (void)multitask {
[[objc_getClass("AXSpringBoardServer") server] openAppSwitcher];
}
%new
- (void)showMenu {
// Hide button
[home setAlpha:0];
// Add menu
if(menu == nil) {
menu = [[UIWindow alloc] initWithFrame:CGRectMake(30,[UIScreen mainScreen].bounds.size.height / 2 - [UIScreen mainScreen].bounds.size.height / 4,[UIScreen mainScreen].bounds.size.width - 60,85)];
menu.hidden = NO;
menu.windowLevel = 9999;
menuGestureWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
menuGestureWindow.hidden = NO;
menuGestureWindow.windowLevel = 9998;
menu.layer.masksToBounds = YES;
menu.layer.cornerRadius = 7.0;
menu.alpha = 0;
UITapGestureRecognizer *dismissTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMenu)] autorelease];
dismissTap.numberOfTapsRequired = 1;
[menuGestureWindow addGestureRecognizer:dismissTap];
UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
UIVisualEffectView *blurView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
blurView.frame = menu.bounds;
[menu addSubview:blurView];
[UIView animateWithDuration:0.6 animations:^{
[home setAlpha:0];
} completion:nil];
[UIView animateWithDuration:0.6 animations:^{
[menu setAlpha:1];
} completion:nil];
}
// Screenshot image
UIImage *screenshot = [UIImage imageNamed:@"screenshot.png"];
UIImageView *screenshotView = [[UIImageView alloc] initWithImage:screenshot];
screenshotView.frame = CGRectMake(20,8,70,70);
[menu addSubview:screenshotView];
// Siri image
UIImage *siri = [UIImage imageNamed:@"siri.png"];
UIImageView *siriView = [[UIImageView alloc] initWithImage:siri];
siriView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 150,8,70,70);
[menu addSubview:siriView];
// Screenshot gesture
UITapGestureRecognizer *screenshotTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takeScreenshot)] autorelease];
screenshotTap.numberOfTapsRequired = 1;
[screenshotView addGestureRecognizer:screenshotTap];
// Siri gesture
UITapGestureRecognizer *siriTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(activateSiri)] autorelease];
siriTap.numberOfTapsRequired = 1;
[siriView addGestureRecognizer:siriTap];
// Enable user interaction on all image views
[screenshotView setUserInteractionEnabled:YES];
[siriView setUserInteractionEnabled:YES];
}
%new
- (void)dismissMenu {
[UIView animateWithDuration:0.6 animations:^{
[home setAlpha:1];
} completion:nil];
[UIView animateWithDuration:0.6 animations:^{
[menu setAlpha:0];
} completion:nil];
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
menu.hidden = YES;
menu = nil;
});
menuGestureWindow.hidden = YES;
menuGestureWindow = nil;
}
%new
- (void)takeScreenshot {
[self dismissMenu];
[UIApplication.sharedApplication.screenshotManager saveScreenshotsWithCompletion:nil];
}
%new
- (void)activateSiri {
[self dismissMenu];
[[objc_getClass("AXSpringBoardServer") server] openSiri];
}
%new
- (void)dismissTutorial {
[UIView animateWithDuration:1.5 animations:^{
[tutorial setAlpha:0.0];
} completion:nil];
[UIView animateWithDuration:1.5 animations:^{
[home setAlpha:1.0];
} completion:nil];
}
%end
