//
//  MPVideoRecordController.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPVideoRecordController.h"
#import <QuartzCore/QuartzCore.h>
#import "defs.h"
#import "mcanvas.h"
#import "MPUIKitViewController.h"
#import "SnibbeCapture.h"
#import "UIImage+SnibbeTransformable.h"
#import "SnibbeDevice.h"

#define FRAME_RECORD_DELAY .0666
#define RECORDING_LABEL_UPDATE_DELAY 2.0f

// private interface
@interface MPVideoRecordController()

- (void) recordFrameBegin;
- (void) recordFrame;
- (void) cancelRecording;
- (int) calculateTimeScale;

- (void) finalizeVideo;

- (UIImage *) imageTransformedForVideo: (UIImage *) original;

- (NSString *) pathForVideo;
- (void) removeTempVideo;

- (void) closeWindow;
- (void) clearContents;

- (void) updateRecordingLabel;

@end


@implementation MPVideoRecordController

@synthesize orientingParentDelegate_;
@synthesize videoDelegate_;
@synthesize videoScaleFactor_;
@synthesize videoNumLoops_;
@synthesize maxTimeScale_;
@synthesize iFrameIncrement_;
@synthesize optimize_;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        orientingParentDelegate_ = nil;
        videoDelegate_ = nil;
        videoPath_ = nil;
                
        
        float longDimension = [UIScreen mainScreen].bounds.size.height * gContentScaleFactor;        
        int amtRam = [SnibbeDevice amountOfRAM];
        float desiredLongDimension = VIDEO_IMAGE_DESIRED_WIDTH_IPAD_LOW;
        
        if ( IS_IPAD )
        {
            if ( amtRam >= 512 )
            {
                desiredLongDimension = VIDEO_IMAGE_DESIRED_WIDTH_IPAD_HIGH;
            }
        }
        else
        {
            // todo - iphone.. when to jump to high if ever?
            desiredLongDimension = VIDEO_IMAGE_DESIRED_WIDTH_IPHONE_LOW;
            if ( longDimension > 481.0f )
            {
                // retina screen
                desiredLongDimension = VIDEO_IMAGE_DESIRED_WIDTH_IPHONE_HIGH;
            }
                        
        }
        
        videoScaleFactor_ = desiredLongDimension / longDimension;                        

        
        videoNumLoops_ = VIDEO_SHARE_NUM_LOOPS;
        maxTimeScale_ = VIDEO_SHARE_DEFAULT_MAX_TIMESCALE;
        iFrameIncrement_ = VIDEO_SHARE_FRAME_INCREMENT_DEFAULT;
        optimize_ = false;
        timeScale_ = 60;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void) dealloc
{
    [self clearContents];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS;
    
    // cache this off so video is in consistent orientation for the duration of 
    // recording
    recordingViewOrientation_ = gDeviceOrientation; 
     
    
    totalFrames_ = gMCanvas->numFrames();
    totalFramesRendered_ = 0;
    iCurFrameNum_ = gMCanvas->inq_cframe();
    
    arrayFrames_ = [[NSMutableArray alloc] init];
    
    mainWindowBounds_ = [[UIScreen mainScreen] bounds];
    mainWindowBounds_ = CGRectMake( mainWindowBounds_.origin.x, 
                                    mainWindowBounds_.origin.y, 
                                    mainWindowBounds_.size.width * gContentScaleFactor, 
                                    mainWindowBounds_.size.height * gContentScaleFactor );
    
    
    [self removeTempVideo];
    
    [self recordFrameBegin];
    bShowingRecordingLabel_ = true;
    [self performSelector: @selector(updateRecordingLabel) withObject:nil afterDelay: RECORDING_LABEL_UPDATE_DELAY];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark private methods

- (void) recordFrameBegin
{

    
    // don't change orientations during video recording
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    timeScale_ = [self calculateTimeScale];
    
    if ( optimize_ )
    {        
        if ( timeScale_ >= 60 )
        {
            iFrameIncrement_ = 2;
            timeScale_ = 30;
            videoNumLoops_ *= 2;
        }
    }
    
    totalFramesPerLoop_ = totalFrames_ / iFrameIncrement_;

    
    gMCanvas->forceFrameNum( iCurFrameNum_ );
    [self performSelector : @selector( recordFrame )  withObject:nil afterDelay:FRAME_RECORD_DELAY];
    
}

- (void) recordFrame
{
    // save to UIImage 
    
    
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];           
    UIImage * imageSS = ssScreenShotUIImage( mainWindowBounds_ );        
    UIImage * imageTransformed = [self imageTransformedForVideo: imageSS];        

    SSLog( @"image size: %@, transformed size: %@\n", NSStringFromCGSize( imageSS.size ), NSStringFromCGSize( imageTransformed.size ) );
    
    // test
    /*

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * p = [[paths objectAtIndex:0] stringByAppendingPathComponent: @"test.png"];
        NSString * p2 = [[paths objectAtIndex:0] stringByAppendingPathComponent: @"test2.png"];
    //NSMutableData * imageData = [NSMutableData data];
	//NSKeyedArchiver * imageArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:imageData];

    
    NSData *pngSS = UIImagePNGRepresentation( imageTransformed );
    [pngSS writeToFile:p atomically:false];
    NSData *pngSS2 = UIImagePNGRepresentation( imageSS );
    [pngSS2 writeToFile:p2 atomically:false];

    
    NSLog( @"written: %@\n", p );
    
    */
    // end test
    
    
    
    
    [arrayFrames_ addObject: imageTransformed];
    
    [pool release];
    
    totalFramesRendered_++;

 
    
    
    if ( totalFramesRendered_ < totalFramesPerLoop_ )
    {
    
        [self performSelector : @selector( recordFrame )  withObject:nil afterDelay:FRAME_RECORD_DELAY];

        iCurFrameNum_ += iFrameIncrement_;                        
        iCurFrameNum_ = iCurFrameNum_ % totalFrames_;
        
        gMCanvas->forceFrameNum( iCurFrameNum_ );
    }
    else
    {
        // done!
        gMCanvas->forceFrameNum( -1 );
                             
        [NSThread detachNewThreadSelector:@selector(finalizeVideo) toTarget:self withObject:nil];                
                 
    }
    
}

// helper
- (void) movieCreated
{
    if ( videoDelegate_ )
    {
        [videoDelegate_ onVideoCreated: videoPath_];            
    }
    
    if ( videoPath_ )
    {
        [videoPath_ release];
        videoPath_ = nil;
    }
    
    [self closeWindow];
    

}

// helper
- (void) movieFailed
{
    if ( videoDelegate_ )
    {
        [videoDelegate_ onVideoFailed];            
    }
    
    if ( videoPath_ )
    {
        [videoPath_ release];
        videoPath_ = nil;
    }
    
    [self closeWindow];

}


- (bool) sizesEqualOne: (CGSize) size1 two: (CGSize) size2
{
    
    float deltaW = size1.width - size2.width;
    float deltaH = size1.height - size2.height;
    
    return (fabs( deltaW ) < .001 && fabs( deltaH ) < .001);

}

//
// put together the video    
- (void) finalizeVideo
{
    
    
    if ( videoPath_ )
    {
        [videoPath_ release];
        videoPath_ = nil;
    }
    
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];        
    
    
    //NSLog( @"timeScale: %d\n", iTimeScale );
    
    dir_ = gMCanvas->getFrameDirection();                        
    int iNumImages = [arrayFrames_ count];
    int iImagesAdded = 0;
    
    UIImage * firstImage = 0;
    if ( iNumImages > 0 )
    {
        firstImage = [arrayFrames_ objectAtIndex: 0];
    }
    
    if ( firstImage )
    {
        
        videoPath_ = [self pathForVideo];
        if ( videoPath_ )
        {
            [videoPath_ retain];
        }
        else
        {
            [self performSelectorOnMainThread:@selector(movieFailed) withObject:nil waitUntilDone:NO];
        }
        
        ssRecordMovieBegin( videoPath_, firstImage.size, timeScale_ );
        
        CGSize movieSize = firstImage.size;
        
        
        SSLog( @"writing motionphone video (%@) at: %@\n", NSStringFromCGSize(firstImage.size), videoPath_ );
               
        
        
        
        // limit the number of frames if the movie is going to exceed a certain
        // length - only if optimization is enabled
        
        float secondsPerFrame = 1.0f / (float) timeScale_;        
        float secondsPerLoop = totalFramesPerLoop_ * secondsPerFrame;
        float totalTime = videoNumLoops_ * secondsPerLoop;
        SSLog( @"pre: total time is: %f, num loops: %d\n", totalTime, videoNumLoops_);
        
        float maxLen = VIDEO_DEFAULT_MAX_VIDEO_LENGTH;
        float minLen = VIDEO_DEFAULT_MIN_VIDEO_LENGTH;

        
        if ( optimize_ )
        {
            maxLen = VIDEO_OPTIMIZE_MAX_VIDEO_LENGTH;
            minLen = VIDEO_OPTIMIZE_MIN_VIDEO_LENGTH;
        }
        
        while ( totalTime > maxLen )
        {
            videoNumLoops_--;
            totalTime = videoNumLoops_ * secondsPerLoop;
            
            if ( totalTime < minLen )
            {
                // we've gone too far - back up (we won't be under max but at least we'll be over min)
                videoNumLoops_++;
                totalTime = videoNumLoops_ * secondsPerLoop;
                break;
            }
            SSLog( @"reducing: total time is: %f, num loops: %d\n", totalTime, videoNumLoops_);
        }
    
                           
        
        
        for ( int iLoop = 0; iLoop < videoNumLoops_; ++iLoop )
        {
            
            NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
            
            if ( dir_ > 0 )
            {
                for ( int iFrame = 0; iFrame < iNumImages; ++iFrame )
                {
                    while ( !ssRecordMovieReadyForData() )
                    {
                        ;
                    }
                    
                    UIImage * curImage = [arrayFrames_ objectAtIndex: iFrame];

                    // sanity check to filter out any off-sized images that may have been created
                    if ( [self sizesEqualOne: movieSize two:curImage.size] )
                    {                    
                        //NSLog( @"adding frame: %@\n", NSStringFromCGSize(curImage.size));
                        ssRecordMovieAddFrame( curImage, iImagesAdded++ );
                    }
                    else
                    {
                        //NSLog( @"   skipping frame: %@\n", NSStringFromCGSize(curImage.size));
                    }
                    
                }
            }
            else
            {
                for ( int iFrame = iNumImages-1; iFrame >= 0; --iFrame )
                {
                    while ( !ssRecordMovieReadyForData() )
                    {                                            
                        ;
                    }
                    
                    UIImage * curImage = [arrayFrames_ objectAtIndex: iFrame];
                    
                    // sanity check to filter out any off-sized images that may have been created
                    if ( [self sizesEqualOne: movieSize two:curImage.size] )
                    {       
                        //NSLog( @"adding frame: %@\n", NSStringFromCGSize(curImage.size));
                        ssRecordMovieAddFrame( curImage, iImagesAdded++ );
                    }
                    else
                    {
                        //NSLog( @"   skipping frame: %@\n", NSStringFromCGSize(curImage.size));
                    }
                }
            }
            
            [pool release];
        
            
        }
        
        ssRecordMovieEnd();      
        
        [self performSelectorOnMainThread:@selector(movieCreated) withObject:nil waitUntilDone:NO];
        
                
                
    }
    else
    {
        [self performSelectorOnMainThread:@selector(movieFailed) withObject:nil waitUntilDone:NO];                
    }

    [pool release];
}

//
//
- (void) cancelRecording
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    gMCanvas->forceFrameNum( -1 );
    if ( videoDelegate_ )
    {
        [videoDelegate_ onVideoFailed];
    }
}

//
//
- (int) calculateTimeScale
{
    return  MIN( maxTimeScale_, 1.0f / gMCanvas->minFrameTime());
}

// Returns a new UIImage scaled and rotated according to the platform and
// device orientation.  
- (UIImage *) imageTransformedForVideo: (UIImage *) original
{
    
    UIDeviceOrientation orient = recordingViewOrientation_;        

    UIImage *imageScaled = [original imageByScalingToSize: CGSizeMake( original.size.width * videoScaleFactor_, original.size.height * videoScaleFactor_ ) ];
    
    if ( orient == UIDeviceOrientationPortrait )                                 
    {    
        return imageScaled;                                  
    }
    else
    {
        float degToRotate = 0.0f;
        
        if ( orient == UIDeviceOrientationPortraitUpsideDown )
        {
            degToRotate = 180.0f;
        }
        else if ( orient == UIDeviceOrientationLandscapeLeft )
        {
            degToRotate = -90.0f;
        }
        else if ( orient == UIDeviceOrientationLandscapeRight )
        {
            degToRotate = 90.0f;
        }
        
        UIImage *imageRotated = [imageScaled imageRotatedByDegrees: degToRotate];
        return imageRotated;
    }
    
    
}


//
//
- (NSString *) pathForVideo
{
    NSString *tmpDir = NSTemporaryDirectory();
    return [tmpDir stringByAppendingPathComponent: @"motionphone.mov"];
}

//
//
- (void) removeTempVideo
{
    NSString * videoPath = [self pathForVideo];
    [[NSFileManager defaultManager] removeItemAtPath: videoPath error:nil];
}


//
//
- (void) closeWindow
{
    // startup the orientation messages again
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [self clearContents];
    
    if ( orientingParentDelegate_ )
    {
        // using the motionphone pseudo-modal view controller method
        [orientingParentDelegate_ onViewControllerRequestDismissal: self];
    }
    else
    {
        
        // presented modally?
        
        [[MPUIKitViewController getUIKitViewController] onUIEnd];
        
        if ( [self respondsToSelector:@selector(presentingViewController)] )
        {
            [[self presentingViewController] dismissModalViewControllerAnimated:true];
        }
        else
        {
            [[self parentViewController] dismissModalViewControllerAnimated:true];        
        }
        
    }

}

//
//
- (void) clearContents
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateRecordingLabel) object:nil];
    
    if ( videoPath_ )
    {
        [videoPath_ release];
        videoPath_ = nil;
    }
    
    if ( arrayFrames_ )
    {
        [arrayFrames_ release];    
        arrayFrames_ = nil;
    }
}

//
//
- (void) updateRecordingLabel
{
    [UIView beginAnimations:@"update recording label" context:nil];
    [UIView setAnimationDuration:1.0f];
    
    labelRecording_.alpha = bShowingRecordingLabel_ ? 0.0f : 1.0f;

    [UIView commitAnimations];
    
    bShowingRecordingLabel_ = !bShowingRecordingLabel_;
    
    [self performSelector: @selector(updateRecordingLabel) withObject:nil afterDelay: RECORDING_LABEL_UPDATE_DELAY];
}


#pragma mark IBAction methods

//
//
- (IBAction) onButtonCancel:(id)sender
{
    
    [self cancelRecording];
    
    [self closeWindow];    
}


@end
