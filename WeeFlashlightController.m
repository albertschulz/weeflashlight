#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BBWeeAppController-Protocol.h"
#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVCaptureOutput.h>
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>
#import <AVFoundation/AVFoundation.h>

static NSBundle *_WeeFlashlightWeeAppBundle = nil;

@interface WeeFlashlightController: NSObject <BBWeeAppController> {
	UIView *_view;
	UIImageView *_backgroundView;
    
    UIButton *lightButton;
    AVCaptureSession *torchSession;
    
    float width;
    int orient;
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, retain) AVCaptureSession * torchSession;

- (void)lightButtonPressed:(id)sender;
- (void)torchOnOff:(BOOL)onOff;

@end



@implementation WeeFlashlightController

@synthesize view = _view;
@synthesize torchSession;

+ (void)initialize {
	_WeeFlashlightWeeAppBundle = [[NSBundle bundleForClass:
                                   [self class]] retain];
    NSLog(@"Initialize WeeFlashlight");
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (! [defaults boolForKey:@"notFirstRunn"]) {
        // display alert...
        [defaults setBool:YES forKey:@"notFirstRunn"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:@"/var/mobile/Library/BulletinBoard/SectionInfo.plist" error:NULL];
    }
    // rest of initialization ...
    
}

- (id)init {
	if((self = [super init]) != nil) {
		
	} return self;
}

- (void)dealloc {
	[_view release];
	[_backgroundView release];
	[super dealloc];
}

- (void)loadFullView {
    if (width != 480) width = 320;

	// Add subviews to _backgroundView (or _view) here.
    BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:@"flashState"];
    
    lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [lightButton setFrame:CGRectMake((width/2)-150, 7, 300, 22)];
    [lightButton addTarget:self action:@selector(lightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    lightButton.titleLabel.font            = [UIFont boldSystemFontOfSize: 16];
    lightButton.titleLabel.textAlignment   = UITextAlignmentCenter;
    [lightButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/WeeFlashlight.bundle/FlashlightButtonOff.png"] forState:UIControlStateNormal];
    lightButton.titleLabel.textColor = [UIColor lightGrayColor];
    lightButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    if (state) {
        [lightButton setTitle:@"Flashlight Off" forState:UIControlStateNormal];
        lightButton.tag = 2;
        [lightButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        
        [lightButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/WeeFlashlight.bundle/FlashlightButtonOff.png"] forState:UIControlStateNormal];


    }
    else {
        [lightButton setTitle:@"Flashlight On" forState:UIControlStateNormal];
        lightButton.tag = 1;
        [lightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [lightButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/WeeFlashlight.bundle/FlashlightButtonOn.png"] forState:UIControlStateNormal];


    }

    [_view addSubview:lightButton];
}

- (void)loadPlaceholderView {
	// This should only be a placeholder - it should not connect to any servers or perform any intense
	// data loading operations.
	//
	// All widgets are 316 points wide. Image size calculations match those of the Stocks widget.
	_view = [[UIView alloc] initWithFrame:(CGRect){CGPointZero, {316.f, [self viewHeight]}}];
	_view.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	UIImage *bgImg = [UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"];
	UIImage *stretchableBgImg = [bgImg stretchableImageWithLeftCapWidth:floorf(bgImg.size.width / 2.f) topCapHeight:floorf(bgImg.size.height / 2.f)];
	_backgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg];
	_backgroundView.frame = CGRectInset(_view.bounds, 2.f, 0.f);
	_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_view addSubview:_backgroundView];
}

- (void)unloadView {
	[_view release];
	_view = nil;
	[_backgroundView release];
	_backgroundView = nil;
    
    lightButton = nil;
	// Destroy any additional subviews you added here. Don't waste memory :(.
}

- (float)viewHeight {
	return 37.f;
}

- (void)lightButtonPressed:(id)sender {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device hasTorch] && [device hasFlash]){
        
        if (lightButton.tag == 2) {
            // turn from off to on
            lightButton.tag = 1;
            [lightButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/WeeFlashlight.bundle/FlashlightButtonOn.png"] forState:UIControlStateNormal];
            [lightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [lightButton setTitle:@"Flashlight On" forState:UIControlStateNormal];
            
            [self torchOnOff:TRUE];
            
        }
        else {
            lightButton.tag = 2;
            [lightButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/WeeFlashlight.bundle/FlashlightButtonOff.png"] forState:UIControlStateNormal];
            [lightButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [lightButton setTitle:@"Flashlight Off" forState:UIControlStateNormal];
            
            
            [self torchOnOff:FALSE];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Your device is not compatible with WeeFlashlight, because it does not have a flashlight on the back. Please deactivate WeeFlashlight in your Settings." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (void)torchOnOff:(BOOL)onOff
{
    [[NSUserDefaults standardUserDefaults] setBool:!onOff forKey:@"flashState"];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode: onOff ? AVCaptureTorchModeOn : AVCaptureTorchModeOff];
        [device unlockForConfiguration];
    }
    
}

- (void)willAnimateRotationToInterfaceOrientation:(int)arg1
{
    orient = arg1;
    
    if (arg1 == 1) {
        width = 320;
    }
    if (arg1 == 3 || arg1 == 4) {
        width = 480;
    }
    if (width != 480) {
        width = 320;
    }
}

- (id)launchURLForTapLocation:(CGPoint)point
{	
    // Dirty hack to fix the "TouchHandler" bug.
    UIButton *button
    = (UIButton *)
    [[self view].window
     hitTest:
     [[self view].window
      convertPoint:point
      fromView:[self view]]
     withEvent:nil];
    
    SEL selector = @selector(sendActionsForControlEvents:);
    BOOL canHandleSelector = [button respondsToSelector:selector];
    if(canHandleSelector)
    {
        [button sendActionsForControlEvents:
         UIControlEventTouchUpInside];
    }
    return nil;
}

@end
