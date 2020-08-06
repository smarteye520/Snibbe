//
//  CrownsScene.mm
//  Scoop
//
//  Created by Scott Snibbe on 7/18/10.
//  Copyright Scott Snibbe 2010. All rights reserved.
//
//
//  class CrownScene
//  ---------------
//  Orientation: The parent view controller handles scene rotation, so cocos2d can effectively
//  remain in "portrait" mode the entire time.  This keeps the coordinate system consistent.
//  We do resize the gl view / cocos scene in response to orientation changes, but "up" should
//  always be "up".


// Import the interfaces
#import "CrownsScene.h"
#include "ofxMSAShape3D.h"
#import "TouchModeManager.h"
#import "ScoopDefs.h"
#import "CCNode.h"
#import "SettingsManager.h"
#import "BeatListController.h"
#import "ScoopBeat.h"
#import <UIKit/UIkit.h>
#import "ScoopUtils.h"
#import "SnibbeStore.h"


//const float kCameraRotation = 22.5;	// pi / 
const float kCameraRotation = 28.0;  // modified angle to visually match spec
const double kFutureTime = 9999999999.0f;


#define kMaterialCell 16

// private interface
@interface Crowns()

-(void) setSceneProjection: (CGSize) s;
-(void) populateScoopLibarary;

-(void) onTouchesChanged;
-(CGPoint) updateScoopLastTouchWithAvg;
-(void) updateDirectorOrientation;
-(CGPoint) convertPointToScoopOrientation: (CGPoint) glPoint;
-(CGPoint) convertPointLogicalToPixels: (CGPoint) point;
-(CGPoint) convertPointPixelsToLogical: (CGPoint) point;

-(void) testAndWrapUnwrap;

-(bool) point: (CGPoint) pt isWithinNode: (CCNode *) n;

-(void) saveUIState;
-(void) testAndRestoreUIState;
-(void) testAndSaveUIState;
-(void) restoreUIState;

// pause / play
-(void) onPauseButton: (id) sender;
-(void) onPlayButton: (id) sender;

// quantizer on / off

-(void) onQuantizeOn1: (id) sender;
-(void) onQuantizeOn2: (id) sender;
-(void) onQuantizeOff: (id) sender;

// mute beats
-(void) updateDrumMute;
-(void) onDrumMuteOn;
-(void) onDrumMuteOff;

// tempo tracking
-(void) trackTempo: (CGPoint) pt;
-(void) positionTempoSlider: (float) normVal;
-(void) onTempoButton: (id) sender;
-(bool) showTempoSlider: (bool) bShow;
-(bool) isTempoButtonEnabled;
-(NSString *) bpmTextureNameForBPM: (int) bpm;
-(void) updateBPMIndicator;

// beats
-(void) createBeatUI;
-(void) setBeatUIVisibility: (float) fadeTime;
-(CCSprite *) getBeatAtPoint: (CGPoint) pt;
-(NSString *) beatSpriteNameForSet: (int) iSet index: (int) iIndex frameIndex: (int) frameIndex;

// save / load menu
-(void) clearSaveLoadUI;
-(CCSprite *) createSavedScoopNode: (CGPoint) pos uid: (int) uniqueID;
-(void) createSaveLoadUI;
-(void) repositionSaveLoadUI;

-(void) dragSave: (CGPoint) pt;
-(void) returnDraggedSave;
-(void) deleteDraggedSave;
-(CGPoint) calculatePositionForSaveLoadNode: (CCNode *) n;

-(void) loadButtonPressed:  (id) sender;
-(void) saveButtonPressed:  (id) sender;

-(CCSprite *) getSaveItemAtPoint: (CGPoint) pt;

// genral controls
-(void) createControls;
-(void) updateControls;
-(void) hidePopover;
-(void) onBeatSetButton: (id) sender;
-(void) onInfoButton: (id) sender;

//-(void) displayPhoneTrackSwapAnim: (float) duration;

// info screen
-(void) cleanupInfoScreen;
-(void) clearInfoScreen;

// popover delegate methods
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;

// ScoopBeatSetIDTarget delegate methods
-(void) onBeatSetIDSelected: (int) id;
-(void) onTempoChanged: (float) normalizedTempo;

- (void) scoopSetPaused: (bool) bPause;

- (bool) justBecameActiveAgain;
@end



@implementation Crowns

@synthesize mainViewController_;


+(id) scene: (bool) bRetina withViewController: (UIViewController *) vc
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	Crowns *layer = [Crowns node];
	
    [layer setRetinaEnabled:bRetina];
    layer.mainViewController_ = vc;
    
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(void) setRetinaEnabled: (bool) bEnabled
{
    retinaEnabled_ = bEnabled;
}

// initialize your instance here
-(id) init
{
	if( (self=[super init])) {
		
		[self setSceneProjection: [[CCDirector sharedDirector] winSizeInPixels] ];		
		
        savedOpacityState_ = [[NSMutableDictionary alloc] init];
		
		shape3D = new ofxMSAShape3D();
		shape3D->setSafeMode(false);
		shape3D->enableNormal(false);
		shape3D->enableTexCoord(false);
		shape3D->enableColor(true);
		
        drawDelay_ = 0;
        isActive_ = true;
        
        timeUIRestored_ = 0;
        timeUIHidden_ = 0;
        
        // needed to bump this value so that it didn't need to reallocate 
        // on the first orientation change (caused flash)
		shape3D->reserve(6000); 
		
		// enable touches
		self.isTouchEnabled = YES;
		resizingView_ = false;
        
        savedRotateData_ = [[NSMutableArray alloc] init];
        
        timeOrientationChangedToPortrait_ = kFutureTime;
        timeOrientationChangedToLandscape_ = kFutureTime;
        
        pendingDeviceOrientation_ = UIDeviceOrientationUnknown;
        
		CGSize screenSize = [CCDirector sharedDirector].winSizeInPixels;
		CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
		
		glClearColor( 232.0f/255, 239.0f/255,  243.0f/255, 1.0f );
		
        [self populateScoopLibarary];
        
        uiHidden_ = false;
        
        infoScreen_ = nil;
        
        timeLastBecameActive_ = -1.0f;
        timeLastResignedActive_ = -1.0f;
        
        float scaleXCoef = .83f;
        float scaleYCoef = 0.47f;
        
		float scaleFactorX = (screenSize.width / 768) * scaleXCoef;
   		float scaleFactorY = (screenSize.height / 1024) * scaleYCoef;
        
		//scaleFactor = 0.1;
		scoop = Scoop::createScoop(screenSize.width, screenSize.height, scaleFactorX, scaleFactorY, GRAPH_SIZE);

		
		//scoop->focusOn(3);
		
		// schedule a repeating callback on every frame
        [self schedule:@selector(nextFrame:)];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) 
													 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
		
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scoopWillRotate:) 
													 name:@"ScoopWillRotate" object:nil];
        
        

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResigningActive:) 
													 name:@"app_resigning_active" object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomingActive:) 
													 name:@"app_becoming_active" object:nil];
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeTransactionFailed:) 
													 name:kInAppPurchaseManagerTransactionFailedNotification object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeTransactionSucceeded:) 
													 name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
        
        
        

		currentOrientation_ = UIDeviceOrientationPortrait; // is this our startup orientation?
        //saveLoadNumbers_ = nil;
        
		scoop->setSpeed(.75);
		[self createControls];
		
        numTouchEventsInCurSequence_ = 0;
        
		inputState_ = eNormal;
        prevScoopDirty_ = false;
        scoop->clearDirty();
        nodeTouchedSave_ = nil;
        loadedSaveUID_ = -1;
        lastTempoTouchTime_ = -1;
        popControllerBeatSets_ = nil;
        
        if ( gbIsIPad )
        {
            beatController_ = [[BeatListController alloc] init];        
            beatController_.beatSetIDDelegate_ = self;
            beatController_.view; // load it!

            settingsViewPhone_ = nil;
        }
        else
        {
            settingsViewPhone_ = [[SettingsViewPhone alloc] init]; 
            settingsViewPhone_.beatSetIDDelegate_ = self;
            settingsViewPhone_.view; // load it!
            beatController_ = nil;
        }
        
         
        timeLastDirtyVisibleChanged_ = 0.0f;
        
        
        controllerAudioTuning_ = [[UIViewControllerAudioTuning alloc] initWithNibName: @"UIViewControllerAudioTuning" bundle: nil];
        [controllerAudioTuning_ setScoop: scoop];
        
        
        // preload save textures
        for ( int iS = 1; iS <= maxSaves(); ++iS )
        {
            for ( int iF = SAVE_ANIM_FRAME_FIRST; iF < SAVE_ANIM_FRAME_LAST; ++iF )
            {       
                NSString *texName = getPlatformResourceName( [NSString stringWithFormat: @"%d_%05d", iS, iF], @"png" );
                [[CCTextureCache sharedTextureCache] addImage: texName];                                
            }
        }
        
        // preload bpm textures    
        if ( gbIsIPad )
        {
            for ( int iB = MIN_BPM; iB <= MAX_BPM; ++iB )
            {
                [[CCTextureCache sharedTextureCache] addImage:[self bpmTextureNameForBPM: iB]];
            }
        }
        
        [self scoopSetPaused: false];
	}
	return self;
}


-(void) draw
{
    if ( drawDelay_ > 0 )
    {
        --drawDelay_;
    }
    else
    {
    
        // save off the blend function state... our code modifies it
        GLint savedBlendSrc = 0;
        GLint savedBlendDst = 0;
        
        glGetIntegerv(GL_BLEND_DST, &savedBlendDst );
        glGetIntegerv(GL_BLEND_SRC, &savedBlendSrc );
        
        // Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
        // Needed states:  GL_VERTEX_ARRAY, 
        // Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);

        shape3D->setSafeMode(false);
        shape3D->setClientStates();
        
        glPushMatrix();
        CGSize screenSize = [CCDirector sharedDirector].winSizeInPixels;
        //glTranslatef(screenSize.width, screenSize.height * 1.1, 0);
        glTranslatef(screenSize.width, screenSize.height, 0);
        glRotatef(180, 0, 0, 1);	// flip rendering - rotated
        
        
        scoop->drawGL3D(shape3D, kCameraRotation);
        
        glPopMatrix();
        
        shape3D->restoreClientStates();
        
        // restore default GL states
        glEnable(GL_TEXTURE_2D);
        glEnableClientState(GL_COLOR_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        // restore the blend function state
        glBlendFunc( savedBlendSrc, savedBlendDst );
    }
    
}



-(void) nextFrame: (ccTime) dt
{
	
	TouchModeManager::Manager().Update(dt);
	scoop->update(dt);
	
	[self testAndWrapUnwrap];
    [self testAndRestoreUIState];
    [self testAndSaveUIState];
    [self updateControls];    
    

}


//
// helper function
- (void) testAndBeginWritingIntoTrack
{

    if ( scoop->getScoopOrientation() == eScoopPortrait && 
         scoop->focusTrack() != Scoop_FocusNone && 
        !scoop->isMoving() && 
         TouchModeManager::Manager().getCurNumTouches() > 0 )
    {
        scoop->writeIntoSelectedTrack(true, kCameraRotation);
    }
}

// and maybe start recording already? no.              
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
		

    numTouchEventsInCurSequence_++;
    
	for( UITouch *touch in touches ) 
	{		
		// inform the touch mode manager
		TouchModeManager::Manager().touchBegan( touch, event );		
	}
    
    [self onTouchesChanged];
	
	
	CGPoint location = [self updateScoopLastTouchWithAvg];
    CGPoint pixelLocation = [self convertPointLogicalToPixels:location];
	CCSprite *touchedSavedScoop = [self getSaveItemAtPoint: location];
    CCSprite *touchedBeat = [self getBeatAtPoint: location];
    ScoopOrientationT scoopOrient = scoop->getScoopOrientation();
    
    bool touchedTempoSlider = false;
    
    //NSLog( @"FIRST touch pos: %@\n", NSStringFromCGPoint(location) );
    
    // special case for showing the tempo slider
    if ( [self point:location isWithinNode:sliderBG_] && inputState_ == eNormal  )
    {
        if ( sliderBG_.opacity == 0 )
        {
            [self showTempoSlider: true]; 
            return;
        }
        
        touchedTempoSlider = true;        
        
    }
    
    
    //NSLog(@"x: %f, y:%f\n", location.x, location.y );
    
    // here we test for special handling for certain objects we can manipulate
    
	if ( [self point: location isWithinNode: sliderButton_] && [self isTempoButtonEnabled] )
	{
		// here we begin tracking the tempo slider
		inputState_ = eTrackingTempo;
		
	}
    else if ( [self point: location isWithinNode: nodeSaveNew_] && nodeSaveNew_.opacity > 0 )
    {
        // we use opacity here for "enabled" since it's not a real button
        inputState_ = eTouchedSaveNew;
    }
    else if ( touchedSavedScoop )
    {
        inputState_ = eTouchedSavedScoop;
        nodeTouchedSave_ = touchedSavedScoop;
        // may need to adjust z here
        nodeTouchedSaveOriginalPt_ = [self calculatePositionForSaveLoadNode: nodeTouchedSave_];
    }
    else if ( touchedBeat )
    {
        inputState_ = eTouchedBeat;
        nodeTouchedBeat_ = touchedBeat;
    }
	
    if ( inputState_ != eTrackingTempo && !touchedTempoSlider )
    {
        [self showTempoSlider: false]; // any touch besides tempo slider hides it
    }
	
	switch (inputState_) {
		case eNormal:
		{

			
			
            float expandTouchBox = 1.13f;
			int track = scoop->trackHitsPoint(pixelLocation, kCameraRotation, expandTouchBox);
			
            
            if ( scoopOrient == eScoopPortrait )
            {
                
                if (track == scoop->focusTrack()) 
                {
                    scoop->writeIntoSelectedTrack(true, kCameraRotation);
                } 
                else if (track != Scoop_FocusNone) 
                {
                                    
                    // what should the interp time be?                
                    // base it off the tempo so we can have a consistent effect
                    float interpTimeAtBaseLineBPM = .4f;                
                    float interpTime = scoop ? ( ( scoop->baselineWrapDuration() / scoop->wrapDuration() ) * interpTimeAtBaseLineBPM) : interpTimeAtBaseLineBPM;
                    
                    if ( !gbIsIPad )
                    {
                        interpTime *= 2;
                        //[self displayPhoneTrackSwapAnim: interpTime];
                    }
                    
                    scoop->focusOn(track, interpTime, true);                    
                    
                    float timeToTest = interpTimeAtBaseLineBPM;
                    if ( !gbIsIPad )
                    {
                        timeToTest = interpTimeAtBaseLineBPM * 2;
                    }
                    
                    // we want to begin writing into the track after the transition is complete
                    [self performSelector:@selector(testAndBeginWritingIntoTrack) withObject:nil afterDelay:timeToTest + .1f];                                                  
                    
                } 

                
                
            }
            else if ( scoopOrient == eScoopLandscape )
            {
                                                
                if (track != Scoop_FocusNone) 
                {           
                    
                    scoop->focusOnLandscape( track, pixelLocation, kCameraRotation );                                          
                    scoop->writeIntoSelectedTrack(true, kCameraRotation);
                }
            } 

			break;
		}		
		default:
		{
			
			break;
		}
	}
	
	
	
	
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    numTouchEventsInCurSequence_++;
    
	for( UITouch *touch in touches ) {
		
		// inform the touch mode manager
		TouchModeManager::Manager().touchMoved( touch, event );
	}
	
    [self onTouchesChanged];
	
	CGPoint location = [self updateScoopLastTouchWithAvg];
    
    //NSLog( @"touch pos: %@\n", NSStringFromCGPoint(location) );
    
	switch (inputState_) {
		case eNormal:
		{
			if (scoop->writingIntoSelectedTrack()) 
			{				
				scoop->writeIntoSelectedTrack(false, kCameraRotation);				
			}
			break;
		}
		case eTrackingTempo:
		{
			[self trackTempo: location];
			break;
		}	
        case eTouchedSavedScoop:
        {
            
            CGPoint worldNodeOriginalPos = [[nodeTouchedSave_ parent] convertToWorldSpace: nodeTouchedSaveOriginalPt_ ];
            if ( ccpDistance( location,  worldNodeOriginalPos ) > UI_DRAG_DIST_THRESHOLD )
            {
                // we qualify as a drag now
                inputState_ = eDraggingSavedScoop;
            }
            break;
        }
        case eDraggingSavedScoop:
        {
            [self dragSave: location];
            break;
        }
        case eTouchedSaveNew:
        {
            if ( ![self point: location isWithinNode: nodeSaveNew_] )
            {
                // we're not on the node anymore.. back to normal
                inputState_ = eNormal;
            }                        
            break;
        }
        case eTouchedBeat:
        {
            CCSprite *touchedBeat = [self getBeatAtPoint: location];
            if ( touchedBeat != nodeTouchedBeat_ )
            {
                // we're off it
                inputState_ = eNormal;
                nodeTouchedBeat_ = nil;
            }
            break;
        }
		default:
		{
			
			break;
		}
	}
	
	
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
		
	
	for( UITouch *touch in touches ) {
		
		// inform the touch mode manager
		TouchModeManager::Manager().touchEnded( touch, event );
	}
			
	
	// not elegant... we aren't associating particular touches with UI elements since
    // it doesn't seem necessary.  Our UI is simple enough to get by by 
    
	if ( TouchModeManager::Manager().getCurNumTouches() == 0 )        
    {
        
        numTouchEventsInCurSequence_ = 0;
        
        if ( inputState_ == eDraggingSavedScoop )
        {        
            CGPoint curDraggedNodeWorldPos = [[nodeTouchedSave_ parent] convertToWorldSpace: nodeTouchedSave_.position ];             
            float draggedRightSideX =  curDraggedNodeWorldPos.x + nodeTouchedSave_.contentSize.width / 2.0f;
            
            if ( draggedRightSideX < uiDividerRight_.position.x )
            {
                [self deleteDraggedSave];
            }
            else
            {
                [self returnDraggedSave]; 
            }
        }
        else if ( inputState_ == eTouchedSavedScoop )
        {
            [self returnDraggedSave]; 
            [self loadButtonPressed: nodeTouchedSave_];
        }
        else if ( inputState_ == eTouchedSaveNew )
        {
            // our makeshift "button up" for save 
            [self saveButtonPressed:nil];            
        }
        else if ( inputState_ == eTouchedBeat )
        {
            // we tapped a beat button
            int iBeatIndex = nodeTouchedBeat_.tag;
                        
            scoop->setCurBeatIndex( iBeatIndex );
            
        }
	
        
		inputState_ = eNormal;
        nodeTouchedSave_ = nil;
	}
	
    
	if (scoop->writingIntoSelectedTrack()) 
	{		
				
		if ( TouchModeManager::Manager().getCurNumTouches() == 0 )
		{
			scoop->stopWritingIntoSelectedTrack();
		}
		else 
		{
			scoop->writeIntoSelectedTrack(false, kCameraRotation);
		}
	}

	
	[self onTouchesChanged];
}

//
//
- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self ccTouchesEnded:touches withEvent:event];
}

// tell the director that the orientation has changed
- (void) orientationChanged:(NSNotification *)notification
{


    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];	

    if ( !shouldHandleDeviceOrientation( orientation ) )
    {           
        // we don't care about these
        return;
    }
        
    
    switch (orientation) 
	{
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
        {
            timeOrientationChangedToPortrait_ = CACurrentMediaTime();
            timeOrientationChangedToLandscape_ = kFutureTime;
            pendingDeviceOrientation_ = orientation;
            break;
        }
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
        {
            timeOrientationChangedToLandscape_ = CACurrentMediaTime();
            timeOrientationChangedToPortrait_ = kFutureTime;
            pendingDeviceOrientation_ = orientation;
            break;
        }
        default:
        {
            break;
        }

    }
    

       

    
}


//
//
- (void) doScoopWillRotate: (NSDictionary *) params
{
        
    
    CGRect destinationRect = [(NSValue *)[params objectForKey:@"rect"] CGRectValue];    
    bool toLandscape = [ (NSNumber *) [params objectForKey:@"tolandscape"] boolValue];
    //double atTime = [(NSNumber *) [params objectForKey:@"time"] doubleValue];
    
    // do this here so we catch it early on before the rotate (visually better)
    if ( toLandscape )
    {
        [self saveUIState];
    }
    
    CGSize prevScoopSize = scoop->getSize();
    
    
    scoop->setSize( destinationRect.size );        
    [self setSceneProjection: destinationRect.size ];


    if ( destinationRect.size.width != prevScoopSize.width ||
         destinationRect.size.height != prevScoopSize.height )
    {
        scoop->reFocus(); // this tells the graphs to recalculate their positions with respect to the new size of the view
    }
    [self hidePopover];
    

}

// tell the director that the orientation has changed.
- (void) scoopWillRotate:(NSNotification *)notification
{
                
	NSMutableDictionary *params = [notification object];
    
    [self clearInfoScreen];
    
    if ( isActive_ )
    {
        // only do this if we're not in a suspended state
        [self scoopSetPaused: false];    
    }

    [self doScoopWillRotate:params];
    
}



//
//
-(void) appResigningActive: (NSNotification *) notification
{
     
    [self scoopSetPaused: true];    
    scoop->FadeMasterVol( 0.0f, 0 );
    timeLastResignedActive_ = CACurrentMediaTime();
    isActive_ = false;
   
}


//
//
-(void) appBecomingActive: (NSNotification *) notification
{    
    isActive_ = true;
    timeLastBecameActive_ = CACurrentMediaTime();
    scoop->FadeMasterVol( 1.0f );
    [self scoopSetPaused: false];    
    
    
    if ( [self justBecameActiveAgain] )
    {
        scoop->reFocus();
    }
    
}

//
//
-(void) storeTransactionFailed: (NSNotification *) notification
{
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Unable to process transaction" message:@"Sorry, we were unable to process this transaction.  Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [av show];
    [av release];
    
}


//
//
-(void) storeTransactionSucceeded: (NSNotification *) notification
{        
    NSLog( @"transation SUCCESS!!\n" );
}


// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	Scoop::destroyScoop();
	
    [savedRotateData_ release];
    savedRotateData_ = nil;
    
    [savedOpacityState_ release];

    if ( beatController_  )
    {
        [beatController_ release];
    }
    
    if ( settingsViewPhone_ )
    {
        [settingsViewPhone_ release];
    }
    
	// in case you have something to dealloc, do it in this method
	//delete world;
	//world = NULL;
	
	//delete m_debugDraw;

	// don't forget to call "super dealloc"
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////
// private implementation
///////////////////////////////////////////////////////////////////////////////

//
//
-(void) setSceneProjection: (CGSize) s
{
    [[CCDirector sharedDirector] setProjection: kCCDirectorProjectionCustom];
    
    glViewport(0, 0, s.width, s.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(0, s.width, 0, s.height, -1024, 1024);
    //glRotatef(kCameraRotation, 1, 0, 0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    landscapeBaseYVal_ = s.height / 2.0f - s.width / 2.0f;
    landscapeBaseXVal_ = s.width / 2.0f - s.height / 2.0f;

    
   
}


//
// setup the library of beats the app will access
-(void) populateScoopLibarary
{
    
    ScoopLibrary& lib = ScoopLibrary::Library();
    
    
    // set 1
    ScoopBeatSet *bs = lib.addBeatSet();
    bs->setName( "Core Beats" );
    bs->setDescription( "Back Flip\nJump\nPush\nThump\nElectron" );
    bs->setUID( 1 );
    
    bs->addBeat( 100, "2-Step Back Flip Beat 01.L" );
    bs->addBeat( 101, "2-Step Jump Beat 01.L" );
    bs->addBeat( 102, "2-Step Push Beat 01.L" );
    bs->addBeat( 103, "2-Step Thump Beat 04.L" );
    bs->addBeat( 104, "Breaks Electro Beat 02.L" );
    bs->addBeat( 105, "Electroclash Glam Beat 01.L" );        
    
    
    // set 2    
    bs = lib.addBeatSet();
    bs->setName( "Hip Hop 1" );
    bs->setDescription( "Bandit\nBounce\nBumper\nDeep" );
    bs->setUID( 2 );
    
    bs->addBeat( 200, "Hip Hop Bandit Beat 01.L" );
    bs->addBeat( 201, "Hip Hop Beat 13.L" );
    bs->addBeat( 202, "Hip Hop Bumper Beat.L" );
    bs->addBeat( 203, "Hip Hop Deep Beat 01.L" );
    
    // set 3
    bs = lib.addBeatSet();
    bs->setName( "Electro" );
    bs->setDescription( "Deep End\nMainframe\nSharp Shape\nTransistor" );
    bs->setUID( 3 );
    
    bs->addBeat( 300, "Electro Deep End Beat.L" );
    bs->addBeat( 301, "Electro Mainframe Beat 01.L" );
    bs->addBeat( 302, "Electro Sharp Shape Beat.L" );
    bs->addBeat( 303, "Electro Transistor Beat.L" );
    
    
    // set 4
    bs = lib.addBeatSet();
    bs->setName( "Hip Hop 2" );
    bs->setDescription( "Everybody\nPhat\nThugz\nUrban" );
    bs->setUID( 4 );
    
    bs->addBeat( 400, "Hip Hop Everybody Beat.L" );
    bs->addBeat( 401, "Hip Hop Fat Frog Beat 02.L" );
    bs->addBeat( 402, "Hip Hop Muscle Beat 02.L" );
    bs->addBeat( 403, "Hip Hop Small Box Beat 02.L" );

    
    
    

        
    // set 5
    bs = lib.addBeatSet();
    bs->setName( "Techno" );
    bs->setDescription( "Accelerator\nPhaze\nLightwave\nUltrabeat" );
    bs->setUID( 5 );
    
    bs->addBeat( 500, "mphloop2.L" );
    bs->addBeat( 501, "Techno Hopscotch Beat 02.L" );
    bs->addBeat( 502, "Techno Runner Beat 04.L" );
    bs->addBeat( 503, "ultrabeat def.L" );
    
    // set 6
    bs = lib.addBeatSet();
    bs->setName( "House" );
    bs->setDescription( "Locked Down\nRolling\nOver the Edge\nMinimal Kit" );
    bs->setUID( 6 );
    
    bs->addBeat( 600, "House Backstage Beat 01.L" );
    bs->addBeat( 601, "House Disguised Beat.L" );
    bs->addBeat( 602, "House Over The Edge Beat.L" );
    bs->addBeat( 603, "minimal kit.L" );
    
    // continue adding sets here as needed
                    
    
}


//
// 
-(void) onTouchesChanged
{
	TouchModeT tMode = TouchModeManager::Manager().getCurTouchMode();

	
	switch (tMode) 
	{
		case eMode2Touch:
		case eMode3Touch:
		case eMode4Touch:
		case eMode5Touch:
		{	
            
            // doing this with a button now
            
//			scoop->setQuantize(PITCH_GRAPH_INDEX, QUANTIZE_STEPS_PITCH); 
//			scoop->setQuantize(VOLUME_GRAPH_INDEX, QUANTIZE_STEPS_VOLUME);
//			scoop->setQuantize(FILTER_GRAPH_INDEX, QUANTIZE_STEPS_FILTER); 
//			
//			scoop->setQuantizeY( PITCH_GRAPH_INDEX, QUANTIZE_STEPS_PITCH_Y_DIR );
			

            
			break;
		}
		default:
		{
            
            // doing this with a button now
            
//			scoop->setQuantize(PITCH_GRAPH_INDEX, 0); 
//			scoop->setQuantize(VOLUME_GRAPH_INDEX, 0); 
//			scoop->setQuantize(FILTER_GRAPH_INDEX, 0); 
//			
//			scoop->setQuantizeY( PITCH_GRAPH_INDEX, 0 );
			
			break;
		}
	}
	
	scoop->numTouchesChanged( TouchModeManager::Manager().getCurNumTouches() );
		
}


//
//
-(CGPoint) updateScoopLastTouchWithAvg
{
	// we're just doing the average point now
	CGPoint avgTouch = CGPointZero;
	NSTimeInterval lastTimestamp = 0;
	
	// point is already converted to gl coords within the touch manager
	TouchModeManager::Manager().getTouchesAvgPoint( avgTouch, lastTimestamp );	

	//avgTouch = [self convertPointToScoopOrientation: avgTouch];	
	//NSLog( @"touch: %f, %f\n", avgTouch.x, avgTouch.y );
	
    CGPoint pixelPoint = [self convertPointLogicalToPixels: avgTouch];
	scoop->lastTouch( pixelPoint, lastTimestamp );
	

    // this doesn't matter below - since we're writing as the crown turns, smoothing
    // doesn't really help unless we do it retroactively
    
    // this is special-case code to counteract the way that apple delays the first touchesMoved event.
    // we don't want a shart discontinuity so we average
//    if ( scoop->getScoopOrientation() == eScoopPortrait )
//    {
//        if ( numTouchEventsInCurSequence_ <= MAX_NUM_TOUCH_SMOOTHING && numTouchEventsInCurSequence_ > 0 )
//        {
//            touchesY_[numTouchEventsInCurSequence_-1] = avgTouch.y;  
//            
//            if ( numTouchEventsInCurSequence_ > 1 )
//            {
//                avgTouch = CGPointMake( avgTouch.x, (avgTouch.y + touchesY_[numTouchEventsInCurSequence_-2] ) / 2.0f );
//            }
//        }
//    }
    
	return avgTouch;
}
	
	
//
// inform the CCDirector object regarding the current device orientation
-(void) updateDirectorOrientation
{
    // no longer doing this
	
}

// determines whether we're in a state where we should be
// telling the scoop to wrap or unwrap itself, and initiates
// the process if needed
-(void) testAndWrapUnwrap
{
 
    
	
	ScoopOrientationT scoopOrient = scoop->getScoopOrientation();
	bool bUpdatedOrientation = false;
    double time = CACurrentMediaTime();   
    
    bool enoughTimeToChangeScoopOrientToPortrait = (time - timeOrientationChangedToPortrait_) > TIME_IN_ORIENTATION_BEFORE_SCOOP_WRAP;
    bool enoughTimeToChangeScoopOrientToLandscape = (time - timeOrientationChangedToLandscape_) > TIME_IN_ORIENTATION_BEFORE_SCOOP_WRAP;
    
    // this is just a hack to get the least back result in these multitasking edge cases
    float justActiveTransitionTimeWrap = 0.4f;
    float justActiveTransitionTimeAllElse = 0.4f;
    
    
    // we use this value so that we only capture the 4 values we're 
    // interested in and we can not be bothered by "face up" and "face down", etc.
	UIDeviceOrientation orientation = pendingDeviceOrientation_; 	
	
    switch ( pendingDeviceOrientation_ ) 
	{
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown: 
		{
			
			// only transition if we are in the opposite mode
			if ( scoopOrient == eScoopLandscape && enoughTimeToChangeScoopOrientToPortrait )
			{
				scoop->startWrap( [self justBecameActiveAgain] ? justActiveTransitionTimeWrap : WRAP_SCENE_TRANSFORMATION_DURATION );	
                bUpdatedOrientation = true;
                timeOrientationChangedToPortrait_ = kFutureTime;
                pendingDeviceOrientation_ = UIDeviceOrientationUnknown;
			}                     			
			
			break;
		}
			
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
		{
			
			// only transition if we are in the opposite mode
			if ( scoopOrient == eScoopPortrait && enoughTimeToChangeScoopOrientToLandscape )
			{
				scoop->startUnwrap( [self justBecameActiveAgain] ? justActiveTransitionTimeAllElse : WRAP_SCENE_TRANSFORMATION_DURATION );
				bUpdatedOrientation = true;         
                timeOrientationChangedToLandscape_ = kFutureTime;
                pendingDeviceOrientation_ = UIDeviceOrientationUnknown;
                
			}							
            			
			break;
		}
			
			
			
		default:
		{
			break;
		}
	}
	    
    
	// we only update current orientation if it's one of the four we actually want to change to
    
	if ( orientation == UIDeviceOrientationPortrait ||
         orientation == UIDeviceOrientationPortraitUpsideDown ||
         orientation == UIDeviceOrientationLandscapeLeft ||
         orientation == UIDeviceOrientationLandscapeRight )
	{
		currentOrientation_ = orientation;
	}
    
    if ( bUpdatedOrientation )
    {
        
        float transitionTime = WRAP_SCENE_TRANSFORMATION_DURATION;

                
        if ( [self justBecameActiveAgain] )            // we just regained focus... let's make this an instant transition
        {
            transitionTime = justActiveTransitionTimeAllElse;
        }
        
        
        if ( gbIsIPad )
        {
                        
            if ( orientation == UIDeviceOrientationPortrait ||
                orientation == UIDeviceOrientationPortraitUpsideDown )
            {
                // we want a slightly longer transition time in this instance
                transitionTime *= 2;
            }
                        
            scoop->focusOn(3, transitionTime);
            
            
        }
        else
        {
            if ( orientation == UIDeviceOrientationPortrait ||
                 orientation == UIDeviceOrientationPortraitUpsideDown )
            {
                // we want whatever is on the bottom
                transitionTime *= 1.333333;
                scoop->focusOn(scoop->trackShouldGetFocusOnPhoneTransitionToPortrait(), transitionTime );
            }
            else
            {
                scoop->focusOn(3, transitionTime);
            }

        }
    }
}

// Since we never switch the cocos director orientation and instead
// translate the layer itself to achieve animation, we need to use this orientation to
// modify points.  The director always thinks it's in the same mode it was on startup.
//
// gl point always assumes portrait (update of startup in different orientation?)
- (CGPoint) convertPointToScoopOrientation: (CGPoint) glPoint
{

    return glPoint;
    

    /*
	
	CGSize s = [[CCDirector sharedDirector] winSizeInPixels];
	float newY = s.height - glPoint.y;
	float newX = s.width - glPoint.x;
	
	CGPoint ret = CGPointZero;
	
	switch ( currentOrientation_)  
	{
		case CCDeviceOrientationPortrait:
			ret = ccp( glPoint.x, glPoint.y );
			break;
		case CCDeviceOrientationPortraitUpsideDown:			
			ret = ccp(newX, newY);
			break;
		case CCDeviceOrientationLandscapeLeft:
			ret = ccp( newY - landscapeBaseXVal_, glPoint.x + landscapeBaseYVal_);					
			break;
		case CCDeviceOrientationLandscapeRight:
			ret = ccp( glPoint.y - landscapeBaseXVal_, newX + landscapeBaseYVal_);			
			break;
		default:
			break;
	}
	
	return ret;
     */

}


// Takes a point in logical coordinates and translates to
// pixel coords
-(CGPoint) convertPointLogicalToPixels: (CGPoint) point
{

    CCDirector *dir = [CCDirector sharedDirector];
    CGSize logicalSize = [dir winSize];
    CGSize pixelSize = [dir winSizeInPixels];
    
    return CGPointMake( (point.x / logicalSize.width) * pixelSize.width, (point.y / logicalSize.height) * pixelSize.height );

}




// Takes a point in pixel coordinates and translates to
// logical coords
-(CGPoint) convertPointPixelsToLogical: (CGPoint) point
{
    CCDirector *dir = [CCDirector sharedDirector];
    CGSize logicalSize = [dir winSize];
    CGSize pixelSize = [dir winSizeInPixels];
    
    return CGPointMake( (point.x / pixelSize.width) * logicalSize.width, (point.y / pixelSize.height) * logicalSize.height );
}

//
//
-(bool) point: (CGPoint) pt isWithinNode: (CCNode *) n
{
	bool bWithin = false;
	
	if ( n )
	{
		CGRect nodeBB = [n boundingBox]; // only relative to the direct parent		
        
        CGPoint bbOrigin = nodeBB.origin;
        bbOrigin = [[n parent] convertToWorldSpace: bbOrigin];        
        
        //NSLog( @"pt: %@\n", NSStringFromCGPoint(pt) );
        //NSLog( @"box: %@\n", NSStringFromCGRect( CGRectMake(bbOrigin.x, bbOrigin.y, nodeBB.size.width, nodeBB.size.height)));
        
		bWithin = ( pt.x >= bbOrigin.x && 
		            pt.x <= bbOrigin.x + nodeBB.size.width &&
				    pt.y >= bbOrigin.y &&
				    pt.y <= bbOrigin.y + nodeBB.size.height );
	}
	
	
	return bWithin;
}


//
// helper function to save opacity
-(void) saveUIOpacity: (CCNode *) curParent 
{
    if ( !curParent ||
        curParent == cursor_ || 
        curParent == menuPersistent_ )
    {
        // objects we don't want to be affected by this process
        return;
    }
    
    if ( [curParent class] == [CCSprite class]  )
    {
        
        // use the address
        unsigned long int theKey = (unsigned int)curParent;
        
        int savedOpacity = [(CCSprite *)curParent opacity];
        if ( savedOpacity > 0 )
        {
            savedOpacity = 255; // in case we catch in the middle of a fade
        }
        
        [savedOpacityState_ setObject: [NSNumber numberWithInt: savedOpacity ] forKey: [NSNumber numberWithLong: theKey]  ];
                
        curParent.visible = false; 
        

    }
    
    for ( CCNode *curChild in [curParent children] )
    {
        [self saveUIOpacity:curChild];
    }
}

//
// helper function to restore opacity
-(void) restoreUIOpacity: (CCNode *) curParent 
{
    if ( !curParent  )
    {        
        return;
    }
    

    if ( [curParent class] == [CCSprite class] )
    {
        unsigned long int theKey = (unsigned int)curParent;
        
        NSNumber *opacity = [savedOpacityState_ objectForKey: [NSNumber numberWithLong: theKey]];
        
        int targetOpacity = [opacity intValue];
        
        // we start ones fading up at 1 so that if saveUIState is called immediatetly it can 
        // differentiate between the visible elements and hidden ones.  Basically all elements end        
        // up at either 0 or 255 opacity ultimately.  If that ever changes we'll have to revisit this.
        
        ((CCSprite *)curParent).opacity = targetOpacity > 0 ? 1 : 0; 
        
        
        curParent.visible = true;        
        [(CCSprite *)curParent runAction:[CCFadeTo actionWithDuration:UI_ORIENTATION_CHANGED_FADE_TIME opacity: [opacity intValue]]];
    }
    
    for ( CCNode *curChild in [curParent children] )
    {
        [self restoreUIOpacity:curChild];
    }
}

//
// cache off any UI state needed (doesn't persist between executions) 
-(void) saveUIState
{
    if ( !uiHidden_ )
    {                
        uiHidden_ = true;        
        [savedOpacityState_ removeAllObjects];        
        [self saveUIOpacity: controlParent_];
        
        controlParent_.position = ccp( 10000.0f, 10000.0f );
        
        // we special case these
        uiDividerLeft_.visible = false;
        uiDividerRight_.visible = false;
        cursor_.visible = true;
        
        timeUIHidden_ = CACurrentMediaTime();
        
        // move the quantize controls to their new location
        
        //CGSize winSize = [[CCDirector sharedDirector] winSize];
        //buttonQuantizeOn1_.position = buttonQuantizeOn2_.position = buttonQuantizeOff_.position = ccp( winSize.width - buttonQuantizeOn1_.contentSize.width/2.0f, winSize.height - buttonQuantizeOn1_.contentSize.height / 2.0f );
        
        
    }
    
}



// helper to only restore the ui to a visible state when various conditions are
// met (which should avoid all the potential bugs in this process)
- (void) testAndRestoreUIState
{
    double time = CACurrentMediaTime();
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if ( uiHidden_ &&
         time - timeUIHidden_ > MIN_TIME_BETWEEN_UI_HIDE_SHOW &&
         ( orientation != UIDeviceOrientationLandscapeLeft && 
           orientation != UIDeviceOrientationLandscapeRight ) &&
         scoop->getScoopOrientation() == eScoopPortrait )
    {
        [self restoreUIState];
    }
}


// helper to only save the ui to a visible state when various conditions are
// met (which should avoid all the potential bugs in this process).
// This generally should almost never get called because we handle saving the UI
// state manually, but there are very particular sequences of circumstances where 
// the UI can remain visible in landscape mode.  this should catch those.

- (void) testAndSaveUIState
{
    double time = CACurrentMediaTime();
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if ( !uiHidden_ &&
        time - timeUIRestored_ > MIN_TIME_BETWEEN_UI_HIDE_SHOW &&
        ( orientation != UIDeviceOrientationPortrait && 
         orientation != UIDeviceOrientationPortraitUpsideDown ) &&
        scoop->getScoopOrientation() == eScoopLandscape )
    {
        [self saveUIState];
    }
}




//
// restore any UI state needed
-(void) restoreUIState
{
    if ( uiHidden_ )
    {
        [self restoreUIOpacity: controlParent_];
                
        controlParent_.position = ccp( 0.0f, 0.0f );
        
        // we special case these

        uiDividerLeft_.visible = gbIsIPad;
        uiDividerRight_.visible = gbIsIPad;
        
        timeUIRestored_ = CACurrentMediaTime();
        
        cursor_.visible = true;
        
        uiHidden_ = false;

    }
}


//////////////////////////////////////////////////////////////
// recording controls
//////////////////////////////////////////////////////////////



-(void) onPauseButton: (id) sender
{
    /*
    // test
    
    CGSize movieSize = [[CCDirector sharedDirector] winSize];


	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filePath = [documentsDirectory stringByAppendingPathComponent: @"test.mov" ];
    
    
    bool bStartedMovie = recordMovieBegin( filePath, movieSize );    
    if ( bStartedMovie )
    {
        UIImage *screen = screenShotUIImage( CGRectMake(0, 0, movieSize.width, movieSize.height) );
        recordMovieAddFrame(screen, 0);
        recordMovieEnd();
    }
    
    */
    
    
    if ( scoop )
    {
        [self scoopSetPaused: true];        
    }
    
    [self showTempoSlider: false]; // any touch besides tempo slider hides it
    
}


-(void) onPlayButton: (id) sender
{
    
    if ( scoop )
    {
        [self scoopSetPaused: false];
    }

    
    [self showTempoSlider: false]; // any touch besides tempo slider hides it
}




//////////////////////////////////////////////////////////////
// quantize controls
//////////////////////////////////////////////////////////////

//
// helper
- (void) getQuantizeNoteArray: (float *) outNotes num: (int *) outNumNotes
{
    // just create the normalized pentatonic scale here.
    // if we want to expand we can pull this out and generalize it    
    
    // the crown goes through PITCH_SHIFT_RANGE semitones
    // currently it goes from 47 -> 71
    // these values are based on the base pitch of the tone and
    // the range, so if either change this needs to be updated
    
    float lowNote = 47;
    float highNote = 71;
    float range = highNote - lowNote;
    
    
    // C D E G A
    int kPentatonicMajorScaleNotes[] = { 48, 50, 52, 55, 57, 60, 62, 64, 67, 69, 72, 74, 76, 79, 81, 84, 86, 88};                
    int numPentatonicNotes = sizeof( kPentatonicMajorScaleNotes ) / sizeof( kPentatonicMajorScaleNotes[0] );

    // C# D# F G A B
    int kWholeToneScaleNotes[] = { 47, 49, 51, 53, 55, 57, 59, 61, 63, 65, 67, 69, 71, 73, 75, 87, 79, 81, 83};                
    int numWholeToneNotes = sizeof( kWholeToneScaleNotes ) / sizeof( kWholeToneScaleNotes[0] );
    
    //int *pScaleNodes = kPentatonicMajorScaleNotes;
    //int numNotes = numPentatonicNotes;
    
    int *pScaleNodes = kPentatonicMajorScaleNotes;
    int numNotes = numPentatonicNotes;
    
    
    
    for ( int i = 0; i < numNotes; ++i )
    {
        if ( pScaleNodes[i] <= highNote )
        {
            float normalVal = (float)(pScaleNodes[i] - lowNote) / range;
            outNotes[i] = normalVal;
            ++(*outNumNotes);
        }
        else
        {
            break;
        }
    }                

}


-(void) onQuantizeOnCommon: (int) numTimeSteps vis1: (bool) bVis1 vis2: (bool) bVis2 visOff: (bool) bVisOff
{
    if ( scoop )
    {
        
        scoop->setQuantize(PITCH_GRAPH_INDEX, numTimeSteps); 
        scoop->setQuantize(VOLUME_GRAPH_INDEX, numTimeSteps);
        scoop->setQuantize(FILTER_GRAPH_INDEX, numTimeSteps); 
        
        float quantizedVals[MAX_NUM_QUANTIZE_STEPS];
        int numVals = 0;
        
        [self getQuantizeNoteArray: quantizedVals num: &numVals];
        
        scoop->setQuantizeY( PITCH_GRAPH_INDEX, quantizedVals, numVals );
        
        buttonQuantizeOn1_.visible = bVis1;
        buttonQuantizeOn2_.visible = bVis2;
        buttonQuantizeOff_.visible = bVisOff;
        
    }
    
    [self showTempoSlider: false]; // any touch besides tempo slider hides it

}

//
//
-(void) onQuantizeOn1: (id) sender
{    
    // transition to quantize 2
    [self onQuantizeOnCommon:QUANTIZE_STEPS_PITCH_2 vis1:false vis2:true visOff:false];
}

//
//
-(void) onQuantizeOn2: (id) sender
{
    // transition to quantize off
    
    if ( scoop )
    {
        
        scoop->setQuantize(PITCH_GRAPH_INDEX, 0); 
        scoop->setQuantize(VOLUME_GRAPH_INDEX, 0);
        scoop->setQuantize(FILTER_GRAPH_INDEX, 0); 
        
        scoop->setQuantizeY( PITCH_GRAPH_INDEX, 0, 0 );
        
        buttonQuantizeOn1_.visible = false;
        buttonQuantizeOn2_.visible = false;
        buttonQuantizeOff_.visible = true;
        
        
    }
    
    [self showTempoSlider: false]; // any touch besides tempo slider hides it
}
//
//
-(void) onQuantizeOff: (id) sender
{
    // transition to quantize 1
    [self onQuantizeOnCommon:QUANTIZE_STEPS_PITCH_1 vis1:true vis2:false visOff:false];
    
    
    
}

//
//
- (void) updateDrumMute
{
    
    bool bMuted = scoop->BeatsMuted();
    
    buttonMuteBeatsOff_.visible = !bMuted;
    buttonMuteBeatsOn_.visible = bMuted;
        
}

//
//
-(void) onDrumMuteOn
{

    scoop->MuteBeats( true );
    [self updateDrumMute];
}

//
//
-(void) onDrumMuteOff
{
    scoop->MuteBeats( false );
    [self updateDrumMute];    
}


//////////////////////////////////////////////////////////////
// tempo controls
//////////////////////////////////////////////////////////////

// This is hacky but we don't have a slider widget.  We should make one so
// we can properly have it handle tracking it's own input, etc..
-(void) trackTempo: (CGPoint) pt
{
	//CGSize winSize = [[CCDirector sharedDirector] winSize];
	CGRect trackRect = [sliderBG_ boundingBox];
	
	int xValMin = trackRect.origin.x + 60;
	int xValMax = trackRect.origin.x + trackRect.size.width - 30;
	
	
	int xVal = pt.x;
	xVal = MIN( xVal, xValMax );
	xVal = MAX( xVal, xValMin );
	
	float norm = (xVal - xValMin) / (float) ( xValMax - xValMin);
	
	scoop->setSpeed( norm );
	
	sliderButton_.position = ccp( xVal, sliderButton_.position.y );
	
    lastTempoTouchTime_ = CACurrentMediaTime();
}

//
//
-(void) positionTempoSlider: (float) normVal
{
	CGRect trackRect = [sliderBG_ boundingBox];
	
	// $ duplicated code - we need to put this in a class
	int xValMin = trackRect.origin.x + 60;
	int xValMax = trackRect.origin.x + trackRect.size.width - 30;
	
	float posX = xValMin + normVal * (xValMax - xValMin);
			
	sliderButton_.position = ccp( posX, sliderButton_.position.y );
	
}


//
//
-(void) onTempoButton: (id) sender
{
    [self showTempoSlider: ( sliderBG_.opacity == 0 ) ];
}

//
//
-(bool) showTempoSlider: (bool) bShow
{
    
    if ( !gbIsIPad )
    {
        return false;
    }
    
    int iTarget = -1;
    bool actionTaken = false;
    
    if ( bShow  && sliderBG_.opacity == 0 )
    {
        iTarget = 255;      
        lastTempoTouchTime_ = CACurrentMediaTime();
    }
    else if ( !bShow && sliderBG_.opacity == 255 )
    {
        iTarget = 0;  
        lastTempoTouchTime_ = -1; // hiding the control.. reset the value
    }
    
    if ( iTarget >= 0 )
    {
        CCAction *actionFade = [CCFadeTo actionWithDuration: UI_TEMPO_FADE_TIME opacity: iTarget];
        CCAction *actionFade2 = [CCFadeTo actionWithDuration: UI_TEMPO_FADE_TIME opacity: iTarget];        
        [sliderBG_ runAction: actionFade];
        [sliderButton_ runAction: actionFade2 ];                
        
        actionTaken = true;
    }
    
    return actionTaken;
}

//
//
-(bool) isTempoButtonEnabled
{
    if (!gbIsIPad )
    {
        return false;
    }
    
    return sliderButton_.opacity > 0;
}


-(NSString *) bpmTextureNameForBPM: (int) bpm
{
    
    bpm = MAX( bpm, MIN_BPM );
    bpm = MIN( bpm, MAX_BPM );
    
    // which image?
    // no_csr_00000 == 60 bpm
    // no_csr_00080 == 140 bpm
    
    int iImageIndex = bpm - MIN_BPM;
        
    return getPlatformResourceName( [NSString stringWithFormat:@"no_csr_000%02d", iImageIndex], @"png" );        

}

//
// set the correct sprite for the bpm indicator
-(void) updateBPMIndicator
{
    if ( !gbIsIPad )
    {
        return;
    }
    
    if ( scoop )
    {
            
        // what's our bpm?
        float curBPM = scoop->getCurBPM();
        int iBPM = ROUNDINT( curBPM );
        NSString * textureName = [self bpmTextureNameForBPM: iBPM];
        
        CCTexture2D *texBPM = [[CCTextureCache sharedTextureCache] textureForKey:textureName];
        if ( !texBPM )
        {
            texBPM = [[CCTextureCache sharedTextureCache] addImage: textureName ];
        }
        
                
        CCTexture2D *curTexture = [sliderButton_ texture];                
        if ( curTexture != texBPM )
        {
            [sliderButton_ setTexture: texBPM];
        }
        
        
    }
    
}

//////////////////////////////////////////////////////////////
// save load buttons
//////////////////////////////////////////////////////////////


// set the texture for each beat button.  the active one should cycle through
// all images with the music and the inactive ones correlate to their index
-(void) updateBeatControls
{
    
    float posInBeat = scoop->getNormalizedBeatPosition();    
    
    int iActiveBeatIndex = scoop->getActiveBeatIndex();
    int iBeatSetID = scoop->getBeatSet();

    
    int iBeatFrameIndex = NUM_BEAT_FRAMES * NUM_BEAT_FRAME_ANIM_CYCLES_PER_AUDIO_CYCLE * posInBeat;
    iBeatFrameIndex = iBeatFrameIndex % NUM_BEAT_FRAMES; // 0 - 3
    
    int iIndex = 0;
    for ( CCSprite *curSprite in beatNodes_ )
    {
        NSString *spriteName = [self beatSpriteNameForSet: iBeatSetID index: iIndex+1 frameIndex: BEAT_FRAME_INDEX_DEFAULT];
        
        if ( iIndex == iActiveBeatIndex )
        {
            // in this situation we're the animating sprite            
            spriteName = [self beatSpriteNameForSet: iBeatSetID index: iIndex+1 frameIndex: iBeatFrameIndex];
            
        }
        
        CCTexture2D *frameTexture = [[CCTextureCache sharedTextureCache] textureForKey: spriteName ];
        if ( !frameTexture )
        {
            frameTexture = [[CCTextureCache sharedTextureCache] addImage:spriteName];
        }
        
        if ( curSprite.texture != frameTexture )
        {
            curSprite.texture = frameTexture;
        }
        
        ++iIndex;
                                     
    }
    
    
}

//
//
-(void) createBeatUI
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    if ( !beatNodes_ )
    {
        beatNodes_ = [[NSMutableArray alloc] init];
    }
    
    CGPoint curPos = CGPointZero;
    CGSize beatNodeSize = CGSizeZero;
    
    CCNode *beatNodeParent = [CCNode node];
    int iBeatSetID = scoop->getBeatSet();
    
    int iMaxBeats = maxVisibleBeats();
    
    for ( int i = 1; i <= iMaxBeats; ++i )
    {

        NSString *curDefTexture = [self beatSpriteNameForSet: iBeatSetID index: i frameIndex: BEAT_FRAME_INDEX_DEFAULT];
                 
        CCSprite *curSprite = [CCSprite spriteWithFile: curDefTexture ];
        curSprite.position = curPos;
        curSprite.opacity = 0;
        curSprite.tag = i-1; // the index of the beat
        
        curPos = ccp( curPos.x, curPos.y - curSprite.contentSize.height - BEAT_SET_ICON_PADDING );        
        [beatNodeParent addChild: curSprite z: 1];
        
        [beatNodes_ addObject:curSprite];
        
        beatNodeSize = curSprite.contentSize;                            
                               
    }
            
            
    // add the parent to the scene
                
    beatNodeParent.position = gbIsIPad ? ccp(beatNodeSize.width / 2.0f, winSize.height - beatNodeSize.height * 2.5f ) : ccp(beatNodeSize.width / 2.0f, winSize.height - (beatNodeSize.height / 2.0f + 16) );
    
    [controlParent_ addChild:beatNodeParent z: UI_CONTROL_Z_BEATNODE_PARENT];
 
    [self setBeatUIVisibility: 0];
}


// determine which beat sprites are visible based on the number of beats in 
// the current set
-(void) setBeatUIVisibility: (float) fadeTime
{
    int iBeatSetID = scoop->getBeatSet();
    ScoopBeatSet *bs = ScoopLibrary::Library().beatSetWithID( iBeatSetID );
    int iNumBeats = 0;
    if ( bs )
    {
        iNumBeats = bs->getNumBeats();
    }
    
    int iCount = 0;
    for ( CCSprite *curSprite in beatNodes_ )
    {
        int targetOpacity = 0;
        if ( iCount < iNumBeats )
        {
            targetOpacity = 255;
        }
        
        if ( fadeTime < .001 )
        {
            curSprite.opacity = targetOpacity;
        }
        else
        {
            [curSprite runAction: [CCFadeTo actionWithDuration: fadeTime opacity: targetOpacity ]];                
        }
        
        ++iCount;
    }
}


//
//
-(NSString *) beatSpriteNameForSet: (int) iSet index: (int) iIndex frameIndex: (int) frameIndex
{
    if ( frameIndex == 3 )
    {
        // frame 4 is the same as frame 3
        frameIndex = 2;
    }
    
    return getPlatformResourceName( [NSString stringWithFormat:@"set_%d_%d_0000%d", iSet, iIndex, frameIndex ], @"png" );
          
}


//////////////////////////////////////////////////////////////
// save load buttons
//////////////////////////////////////////////////////////////

//
// removes all save/load ui from the scene
-(void) clearSaveLoadUI
{
 
    if ( saveLoadParent_ )    
    {
        [saveLoadParent_ removeFromParentAndCleanup:true];
        saveLoadParent_ = nil;                
    }
    
    if ( existingSaveNodes_  )
    {
        [existingSaveNodes_  release];
        existingSaveNodes_  = nil;
    }
    
    
    
    
}


//
//
-(CCSprite *) createSavedScoopNode: (CGPoint) pos uid: (int) uniqueID
{
    

    // for safety
    if ( uniqueID > maxSaves() )
    {
        uniqueID %= maxSaves(); 
        uniqueID = MAX(1, uniqueID);
    }
    
    
    CCSprite *curSaveLoadNode = [CCSprite spriteWithFile: getPlatformResourceName( [NSString stringWithFormat: @"%d_00029", uniqueID], @"png" ) ];
    
    
    
    curSaveLoadNode.position = pos;
    //[curSaveLoadNode setIsEnabled: true];
    
    [saveLoadParent_ addChild:curSaveLoadNode z: UI_CONTROL_Z_NONDRAGGED];
    [existingSaveNodes_ addObject:curSaveLoadNode];                        
    
    curSaveLoadNode.tag = uniqueID;
    
    return curSaveLoadNode;

}

//
//
-(void) createSaveLoadUI
{
 
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    SettingsManager *man = [SettingsManager manager];
    
    
    // create the CCMenuItem objects for each saved scoop state
    
    int iNumSaves = man.numSavedScoopStates;
    

    if ( !existingSaveNodes_ )
    {
        existingSaveNodes_ = [[ NSMutableArray alloc] init ];
    }
    
    [existingSaveNodes_ removeAllObjects];
    
    
    // save / load
    //menuSaveLoad_ = [CCMenu menuWithItems:nil];
    saveLoadParent_ = [CCNode node];
    //menuSaveLoad_.position = ccp( winSize.width * .90f, winSize.height * 0.7f );
    
    [controlParent_ addChild: saveLoadParent_ z: UI_CONTROL_Z_SAVELOAD_PARENT];
    
    float curChildY = 0.0f;
        
    
    for ( int i = 0; i < iNumSaves; ++i )
    {
        if ( i >= maxSaves() )
        {
            break;
        }
        
        ScoopState * ss = [man scoopStateAtIndex:i];
        
        if ( ss )
        {            
            CCSprite * curSaveLoadNode = [self createSavedScoopNode: ccp( 0.0f, curChildY ) uid: ss->getUniqueID() ];            
            curChildY -= (curSaveLoadNode.contentSize.height + SAVE_LOAD_ICON_PADDING);
        }
                        
    }
    
    // create the sprite object for the "save new" option, although it may not be initially visible    
    NSString *saveFilename = getPlatformResourceName( @"sv_ready", @"png" );
    
    nodeSaveNew_ = [CCSprite spriteWithFile: saveFilename ];    
    
    nodeSaveNew_.position = ccp( 0.0f, curChildY );
    nodeSaveNew_.opacity = 0.0f;    // we're doing initial setup, so there shouldn't be save available
    nodeSaveNew_.tag = 99999;       // tag not used by other save nodes
    
    [saveLoadParent_ addChild:nodeSaveNew_ z: 1];            
    
    // the position of the save/load menu is based on the image size of this image
    saveLoadImageSize_ = nodeSaveNew_.contentSize;
    
    
    saveLoadParent_.position = gbIsIPad ?  ccp(winSize.width - saveLoadImageSize_.width / 2.0f, winSize.height - saveLoadImageSize_.height * 2.5f ) : ccp(winSize.width - saveLoadImageSize_.width / 2.0f, winSize.height - (saveLoadImageSize_.height / 2.0f + 16 ) );
    
    

    
}



// float the save/load icons to their proper positions based on save state.
// Save numbers stay put and save icons move
-(void) repositionSaveLoadUI
{
 
    for (CCSprite * curSprite in existingSaveNodes_)
    {
        
        CGPoint targetPt = [self calculatePositionForSaveLoadNode: curSprite];
        [curSprite runAction: [CCEaseSineInOut actionWithAction: [CCMoveTo actionWithDuration: UI_BUTTON_ACTION_ANIM_TIME position:targetPt]]];
     
    }

    CGPoint targetPt = [self calculatePositionForSaveLoadNode: nodeSaveNew_];
    [nodeSaveNew_ runAction: [CCEaseSineInOut actionWithAction: [CCMoveTo actionWithDuration: UI_BUTTON_ACTION_ANIM_TIME position:targetPt]]];
    
}

/*
//
//
-(void) refreshSaveNumbers
{
    [self performSelector:@selector(showSaveNumbers) withObject:nil afterDelay:UI_BUTTON_ACTION_ANIM_TIME];
}



// Shows or hides the various save numbers according to the number of saves currently 
// in the user settings
-(void) showSaveNumbers
{
    int iNumScoopSaves = [SettingsManager manager].numSavedScoopStates;
    
    int iCur = 0;
    for ( CCSprite *curNum in saveLoadNumbers_ )
    {
        int targetOpacity = 0;
        if ( iCur < iNumScoopSaves )
        {
            targetOpacity = 255;                       
        }
        
        [curNum runAction: [CCFadeTo actionWithDuration: UI_BUTTON_ACTION_ANIM_TIME opacity: targetOpacity ]];                
        ++iCur;
    }
}

*/

//
//
-(void) dragSave: (CGPoint) pt
{
    
    if ( nodeTouchedSave_ )
    {
        nodeTouchedSave_.position = [saveLoadParent_ convertToNodeSpace: pt]; // that's all!
    }
}

//
//
-(void) returnDraggedSave
{
    
    if ( nodeTouchedSave_ )
    {
        
        float dist = ccpDistance( nodeTouchedSave_.position, nodeTouchedSaveOriginalPt_);
        
        // UI_BUTTON_ACTION_TIME should correspond to the height of the window / 2.0... otherwise proportionate
        
   		CGSize size = [CCDirector sharedDirector].winSize;
        float timeForReturn = dist / size.height * UI_BUTTON_ACTION_ANIM_TIME * 2.0f;
        
        [nodeTouchedSave_ runAction: [CCEaseSineInOut actionWithAction: [CCMoveTo actionWithDuration: timeForReturn position:nodeTouchedSaveOriginalPt_]]];
        
    }
}

//
// helper
-(void) removeDeleteAnimNodes
{
    [self removeChildByTag:54321 cleanup:true];
}

//
//
-(void) deleteDraggedSave
{
    
    if ( nodeTouchedSave_ )
    {
        
        // create a dupe to do the delete anim
 
        CCSprite *spriteDupe = [CCSprite spriteWithTexture: [nodeTouchedSave_ texture] ];
        
        CGPoint pt = nodeTouchedSave_.position;
        
        pt = [nodeTouchedSave_.parent convertToWorldSpace: pt];        
        spriteDupe.position = pt;
                
        spriteDupe.opacity = 255;
        spriteDupe.visible = true;
        spriteDupe.tag = 54321;
        
        [self addChild:spriteDupe z: 1000];        
        
        
        CCFiniteTimeAction *action1 = [CCSpawn actionOne: [CCFadeOut actionWithDuration: DELETE_ANIM_DURATION] two: [CCScaleBy actionWithDuration:DELETE_ANIM_DURATION scale:0.90f]];
        CCFiniteTimeAction *action2 = [CCSequence actionOne:[CCDelayTime actionWithDuration:DELETE_ANIM_DURATION] two: [CCCallFunc actionWithTarget:self selector:@selector(removeDeleteAnimNodes)]];
        
        [spriteDupe runAction:[CCSpawn actionOne:action1 two:action2]];
        
        
        
        int idToDelete = nodeTouchedSave_.tag;
        
        // remove the save data
        [[SettingsManager manager] removeScoopStateWithID:idToDelete];

        [existingSaveNodes_ removeObject:nodeTouchedSave_];
           
        [nodeTouchedSave_ removeFromParentAndCleanup:true];
        nodeTouchedSave_ = nil;        
        
        
        [self repositionSaveLoadUI];
        
        // special case here - we made room again in the list - the save icon should
        // fade back in
        if ( [SettingsManager manager].numSavedScoopStates == (maxSaves()-1) && scoop->isDirty() )
        {
            [nodeSaveNew_ runAction: [CCFadeTo actionWithDuration: UI_BUTTON_ACTION_ANIM_TIME opacity: 255.0f ]];   
        }
         
        //[self refreshSaveNumbers];
        
    }
}



// helper
// -1 indicates the save new icon
-(CGPoint) calculatePositionForSaveLoadNodeWithID: (int) saveUID
{

    int iSaveIndex = [[SettingsManager manager] indexForScoopStateID: saveUID];
    if  ( saveUID == -1 )
    {
        iSaveIndex = [[SettingsManager manager] numSavedScoopStates];  // the save new button is last
    }
    
    return ccp( 0.0f, -iSaveIndex * ( saveLoadImageSize_.height + SAVE_LOAD_ICON_PADDING ) );
    // this value is relative to the save/load parent node

}

// Given a save/load node, what should its offset be from the parent node?  Loads are presented vertically
// in order, followed by the new save button
-(CGPoint) calculatePositionForSaveLoadNode: (CCNode *) n
{    
    int idToCheck = n.tag;
    if  ( n == nodeSaveNew_ )
    {
        idToCheck = -1;                
    }

    
    return [self calculatePositionForSaveLoadNodeWithID: idToCheck];    
}



//
// use has touched and released a load button
-(void) loadButtonPressed:  (id) sender
{
    CCSprite *sprite = sender;
    SettingsManager *man = [SettingsManager manager];

    
    int saveUID = sprite.tag;
    ScoopState *ss = [man scoopStateWithID:saveUID];
    
    if ( ss )
    {
    
        scoop->RestoreState( *ss );
        
        
        // any visual control adjustments so we're in sync with the recent load        
        [self positionTempoSlider: scoop->getNormalizedCurSpeed()];
        
        [self updateControls];                
        [self setBeatUIVisibility: UI_BUTTON_ACTION_ANIM_TIME];
        
        prevScoopDirty_ = false;        
        loadedSaveUID_ = saveUID;
        

        
        
       // NSLog( @"loaded scoop state\n" );
    
    }
    
    
}

//
// use has touched and released the save button
-(void) saveButtonPressed:  (id) sender
{
    
    SettingsManager *man = [SettingsManager manager];
    
    int iNewSaveID = [man createNewScoopState];
    ScoopState *ssNew = [man scoopStateWithID:iNewSaveID];
    
    if ( ssNew )
    {
        scoop->SaveState( *ssNew );
        
        [man save];
        
        CGPoint posNewSave = [self calculatePositionForSaveLoadNodeWithID: iNewSaveID];        
        CCSprite *createdSavedScoopNode = [self createSavedScoopNode: posNewSave uid: iNewSaveID];
        
        createdSavedScoopNode.opacity = 255.0f;
        
        // here we create the flipbook anim        
        CCAnimation * flipbookAnim = [CCAnimation animation];
        flipbookAnim.delay = 1/30.0f;
        
        for ( int iF = SAVE_ANIM_FRAME_FIRST; iF < SAVE_ANIM_FRAME_LAST; ++iF )
        {          
            
            NSString *curFile = getPlatformResourceName( [NSString stringWithFormat: @"%d_%05d", iNewSaveID, iF], @"png" );                        
            [flipbookAnim addFrameWithFilename: curFile ];
        }
                        
        id actionAnim = [CCAnimate actionWithAnimation: flipbookAnim];
        [createdSavedScoopNode runAction: actionAnim];        
        
        nodeSaveNew_.opacity = 0; // hide it.. it's being replaced by the new button animation
        [self repositionSaveLoadUI];
        
        //[self performSelector:@selector(showSaveNumbers) withObject:nil afterDelay:UI_BUTTON_ACTION_ANIM_TIME];
        
        loadedSaveUID_ = iNewSaveID;
        
        //NSLog( @"saved new scoop state!\n" );
    }
    
    
    
}
 
//
//
-(CCSprite *) getBeatAtPoint: (CGPoint) pt
{
    for (CCSprite * curSprite in beatNodes_)
    {
        if ( [self point: pt isWithinNode: curSprite] )
        {
            return curSprite;
        }
    }
    return nil;
}
               
//
//
-(CCSprite *) getSaveItemAtPoint: (CGPoint) pt
{
    for (CCSprite * curSprite in existingSaveNodes_)
    {
        if ( [self point: pt isWithinNode: curSprite] )
        {
            return curSprite;
        }
    }
    
    return nil;
}

//////////////////////////////////////////////////////////////
// general controls
//////////////////////////////////////////////////////////////


// This is a basic way of doing this (just code up what you need, all handled
// by this class). If we need more sophisticated behavior in the future we can create
// custom widget classes that can handle their own state and manage their
// own behavior.
-(void) createControls
{
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
    controlParent_ = [CCNode node];
    controlParent_.position = CGPointZero;
    [self addChild: controlParent_ z: 1];
	
    
    
    [self clearSaveLoadUI];
    [self createSaveLoadUI];
    
    // cursor
    cursor_ = [CCSprite spriteWithFile: getPlatformResourceName( @"main_crs", @"png" ) ];            
    
    
    [self addChild: cursor_ z: UI_CONTROL_Z_CURSOR];
    cursor_.opacity = 0;
    
    // beats
    [self createBeatUI];
    
    // create the ui divider bars
    
    uiDividerLeft_ = [CCSprite spriteWithFile:@"ui_divider.png" ];
    uiDividerRight_ = [CCSprite spriteWithFile:@"ui_divider.png" ];
    
    uiDividerLeft_.visible = uiDividerRight_.visible = gbIsIPad;
        
    // they're small squares... scale 'em up    
    // according to the design these should adapts based on certain factors - revisit if need be
    
    float hDivider = uiDividerLeft_.contentSize.height;    
    float dividerScaleY = winSize.height / hDivider * .80f;
    
    uiDividerLeft_.scaleY = dividerScaleY;
    uiDividerRight_.scaleY = dividerScaleY;
    
    float dividerPosFactor = 1.0f;
    if ( !gbIsIPad )
    {
        dividerPosFactor = 0.4f;
    }
    
    uiDividerLeft_.position = ccp( saveLoadImageSize_.width * UI_DIVIDER_SPACING_TO_ICON_SIZE * dividerPosFactor, winSize.height / 2.0f );
    uiDividerRight_.position = ccp( winSize.width - saveLoadImageSize_.width * UI_DIVIDER_SPACING_TO_ICON_SIZE * dividerPosFactor, winSize.height / 2.0f );
    
    [controlParent_ addChild: uiDividerLeft_ z: UI_CONTROL_Z_DIVIDERS];
    [controlParent_ addChild: uiDividerRight_ z: UI_CONTROL_Z_DIVIDERS];
        
    
    // general menu
    
    menuGeneral_ = [CCMenu menuWithItems:nil];
	menuGeneral_.position = CGPointZero;
    [controlParent_ addChild: menuGeneral_ z: UI_CONTROL_Z_GENERAL_BUTTONS];
    
    // persistent menu
    
    menuPersistent_ = [CCMenu menuWithItems:nil];
    menuPersistent_.position = CGPointZero;
    [self addChild: menuPersistent_ z: UI_CONTROL_Z_GENERAL_BUTTONS];
    

    // pause play        
    
    if ( gbIsIPad )
    {
        buttonPause_ = [CCMenuItemImage itemFromNormalImage:getPlatformResourceName( @"pause_btn", @"png" ) selectedImage:getPlatformResourceName( @"pause_btn", @"png" ) target:self selector:@selector( onPauseButton: ) ];
        buttonPause_.position = ccp( buttonPause_.contentSize.width/2.0f, buttonPause_.contentSize.height / 2.0f );
        buttonPause_.visible = true;
        
        buttonPlay_ = [CCMenuItemImage itemFromNormalImage:getPlatformResourceName( @"play_btn", @"png" ) selectedImage:getPlatformResourceName( @"play_btn", @"png" ) target:self selector:@selector( onPlayButton: ) ];
        buttonPlay_.position = buttonPause_.position;
        buttonPlay_.visible = false;
    }
    else
    {
        buttonPlay_ = buttonPause_ = nil;
    }
    
    // quantize mode on / off
    
        

    
    buttonQuantizeOn1_ = [CCMenuItemImage itemFromNormalImage:getPlatformResourceName( @"16_quant", @"png" ) selectedImage:getPlatformResourceName( @"16_quant", @"png" ) target:self selector:@selector( onQuantizeOn1: ) ];
    buttonQuantizeOn1_.visible = false;
    
    buttonQuantizeOn2_ = [CCMenuItemImage itemFromNormalImage:getPlatformResourceName( @"32_quant", @"png" ) selectedImage:getPlatformResourceName( @"32_quant", @"png" ) target:self selector:@selector( onQuantizeOn2: ) ];    
    buttonQuantizeOn2_.visible = false;
    
    buttonQuantizeOff_ = [CCMenuItemImage itemFromNormalImage:getPlatformResourceName( @"inf_smooth", @"png" ) selectedImage:getPlatformResourceName( @"inf_smooth", @"png" ) target:self selector:@selector( onQuantizeOff: ) ];    
    buttonQuantizeOff_.visible = true;
    

    CGPoint quantizePos = CGPointZero;
    CGPoint quantizePosInf = CGPointZero; 

    if ( gbIsIPad )
    {
        
        quantizePos = ccp( winSize.width - buttonQuantizeOn1_.contentSize.width/2.0f, buttonQuantizeOn1_.contentSize.height/2.0f  ); 
        quantizePosInf = ccp( winSize.width - buttonQuantizeOff_.contentSize.width/2.0f, buttonQuantizeOff_.contentSize.height/2.0f  );
    }
    else
    {
        quantizePos = ccp( winSize.width - buttonQuantizeOn1_.contentSize.width/2.0f, buttonQuantizeOn1_.contentSize.height/2.0f );
        quantizePosInf = ccp( winSize.width - buttonQuantizeOff_.contentSize.width/2.0f, buttonQuantizeOff_.contentSize.height/2.0f  );
    }
    
    buttonQuantizeOn1_.position = quantizePos;
    buttonQuantizeOn2_.position = quantizePos;
    buttonQuantizeOff_.position = quantizePosInf;

    
    if ( gbIsIPad )
    {

        float tempoYHeight = buttonPause_.position.y;
                
        // tempo slider
        sliderBG_ = [CCSprite spriteWithFile:getPlatformResourceName( @"tempo_sldr", @"png" ) ];
        sliderBG_.position = ccp( winSize.width / 2.0f, tempoYHeight );
        sliderBG_.opacity = 0;
        [controlParent_ addChild:sliderBG_ z: UI_CONTROL_Z_TEMPO_SLIDER_BG];
        
        // tempo slider control
        // since we want to deal with this on touch begin rather than touch end
        // we don't use a standard cc menu item
        sliderButton_ = [CCSprite spriteWithFile:getPlatformResourceName( @"no_csr_00000", @"png" ) ];
        sliderButton_.position = ccp( winSize.width / 2.0f, tempoYHeight + 14.0f );
        sliderButton_.opacity = 0;
        [controlParent_ addChild:sliderButton_ z: UI_CONTROL_Z_TEMPO_SLIDER_KNOB];	
                
        [self positionTempoSlider: scoop->getNormalizedCurSpeed() ];                
        
        // tempo button            

        tempoButton_ = [CCMenuItemImage itemFromNormalImage: getPlatformResourceName( @"tempo_btn", @"png" ) selectedImage:getPlatformResourceName( @"tempo_btn", @"png" ) target:self selector:@selector( onTempoButton: ) ];    
        tempoButton_.position = ccp( buttonPause_.position.x + buttonPause_.contentSize.width / 2.0f + tempoButton_.contentSize.width / 2.0f, buttonPause_.position.y );
        
    }
    else
    {
        tempoButton_ = nil;     
        sliderBG_ = nil;
        sliderButton_ = nil;
    }
    
    // various buttons    
    buttonBeatSet_ = [CCMenuItemImage itemFromNormalImage: getPlatformResourceName( @"add_drums_btn", @"png" ) selectedImage:getPlatformResourceName( @"add_drums_btn", @"png" ) target:self selector:@selector( onBeatSetButton: ) ];         
    
    if ( gbIsIPad )
    {
        buttonBeatSet_.position = ccp( buttonBeatSet_.contentSize.width / 2.0f, winSize.height - buttonBeatSet_.contentSize.height / 2.0f );
    }
    else
    {
        buttonBeatSet_.position = ccp( buttonBeatSet_.contentSize.width / 2.0f, buttonBeatSet_.contentSize.height / 2.0f );
    }
    
    if ( gbIsIPad )
    {
        buttonInfo_ = [CCMenuItemImage itemFromNormalImage: getPlatformResourceName( @"q_btn", @"png" ) selectedImage:getPlatformResourceName( @"q_btn", @"png" ) target:self selector:@selector( onInfoButton: ) ];    
        buttonInfo_.position = ccp( winSize.width - buttonInfo_.contentSize.width / 2.0f, winSize.height - buttonInfo_.contentSize.height / 2.0f );    
    }
    else
    {
        buttonInfo_ = nil;
    }
    
    
    // mute beats
    
    buttonMuteBeatsOff_ = [CCMenuItemImage itemFromNormalImage: getPlatformResourceName( @"drum_mute_off", @"png" ) selectedImage: getPlatformResourceName( @"drum_mute_off", @"png" ) target:self selector:@selector( onDrumMuteOn ) ];    
    buttonMuteBeatsOff_.visible = true;
    
    
    buttonMuteBeatsOn_ = [CCMenuItemImage itemFromNormalImage:getPlatformResourceName( @"drum_mute_on", @"png" ) selectedImage:getPlatformResourceName( @"drum_mute_on", @"png" ) target:self selector:@selector( onDrumMuteOff ) ];    
    buttonMuteBeatsOn_.visible = false;
    
    buttonMuteBeatsOff_.position = buttonMuteBeatsOn_.position = ccp( buttonMuteBeatsOff_.contentSize.width / 2.0f, buttonMuteBeatsOff_.contentSize.height * 1.5f );
    
    
    // platform-specific
//    if ( gbIsIPad )
//    {
//        trackSwapSprite_ = nil;
//    }
//    else
//    {
//        trackSwapSprite_ = [CCSprite spriteWithFile: getPlatformResourceName( @"swap_00000", @"png" ) ];  
//        trackSwapSprite_.position = ccp( winSize.width / 2.0f, winSize.height * .635f );   
//        trackSwapSprite_.opacity = 0;
//        [self addChild:trackSwapSprite_ z: 99999];
//    }
    
    [menuGeneral_ addChild:buttonBeatSet_ z: 1];
        
    if ( gbIsIPad )
    {
        [menuGeneral_ addChild:buttonInfo_ z: 1];
        [menuGeneral_ addChild:tempoButton_ z: 1];
        [menuGeneral_ addChild:buttonPause_ z: 1];
        [menuGeneral_ addChild:buttonPlay_ z: 1];
    }
    
    [menuGeneral_ addChild:buttonQuantizeOn1_ z:1];
    [menuGeneral_ addChild:buttonQuantizeOn2_ z:1];
    [menuGeneral_ addChild:buttonQuantizeOff_ z:1];
    [menuGeneral_ addChild:buttonMuteBeatsOff_ z:1];
    [menuGeneral_ addChild:buttonMuteBeatsOn_ z:1];
}


//
// perform any control updates per-frame
-(void) updateControls
{
    SettingsManager *man = [SettingsManager manager];
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGSize winSizePixels = [[CCDirector sharedDirector] winSizeInPixels];
    
    cursor_.opacity = scoop->writingIntoSelectedTrack() ? 255 : 0;
    CGPoint lastTouch = scoop->getLastTouch();
    CGPoint lastTouchLogical = [self convertPointPixelsToLogical: lastTouch];

    double time = CACurrentMediaTime();
    
     
    // constrain the cursor to the editing area
    CGRect bb = scoop->getWritingTrackBoundingBox( kCameraRotation );   
    
    float yLow = 0.0f;
    float yHigh = 0.0f;
    scoop->getSelectedTrackScreenYRange( yLow, yHigh );
    float yRangeHeight = yLow - yHigh;
    
    // since we're dealing with scoop coords, we deal in pixel
    // space.  then convert to UI/logical at the end
    
    CGPoint invertedLastTouchPixels = CGPointMake(winSizePixels.width - lastTouch.x, winSizePixels.height - lastTouch.y );
    
    // we need to modify since the bounding boxes are upside-down
    bb = CGRectMake( winSizePixels.width - bb.origin.x, winSizePixels.height - bb.origin.y, -bb.size.width, -bb.size.height );

    float xPos = MAX( invertedLastTouchPixels.x, bb.origin.x );
    xPos = MIN( xPos, bb.origin.x + bb.size.width );
    
    float yPos = MAX( invertedLastTouchPixels.y, bb.origin.y );
    yPos = MIN( yPos, bb.origin.y + yRangeHeight );

    // now we quantize in the y dir
    int focusTrack = scoop->focusTrack();
    if ( focusTrack != Scoop_FocusNone )
    {
        float normalVal = (yPos - bb.origin.y ) / yRangeHeight;
        normalVal = scoop->quantizeYVal( normalVal , focusTrack );
        yPos = normalVal * yRangeHeight + bb.origin.y;
    }
    
    CGPoint logicalPoint = [self convertPointPixelsToLogical: CGPointMake(xPos, yPos) ];
    
    if ( scoop->getScoopOrientation() == eScoopLandscape )
    {                                
        cursor_.position = logicalPoint;                
    }
    else
    {                
        cursor_.position  = ccp( winSize.width / 2.0f, logicalPoint.y );
    }
    
    [self updateBeatControls];
    
    // handle the tempo control update        
    if ( lastTempoTouchTime_ > 0 )
    {
        if ( CACurrentMediaTime() - lastTempoTouchTime_ >= TEMPO_DISAPPEAR_TIME_THRESHOLD )
        {            
            [self showTempoSlider:false];           
        }
    }
    
    
    if ( man.numSavedScoopStates >= maxSaves() )
    {
        // maxed out on saves
        nodeSaveNew_.opacity = 0;
    }
    else
    {
        
        if ( scoop->getScoopOrientation() == eScoopPortrait &&
             time - timeLastDirtyVisibleChanged_ > SAVE_VISIBLE_TIME_THRESHOLD )
        {
            
            // update the save node alpha to correspond with the dirty state of the scoop
            if ( ( nodeSaveNew_.opacity != 255 && scoop->isDirty() ) )
            {            
                // the scoop has been edited
                [nodeSaveNew_ runAction: [CCFadeTo actionWithDuration: UI_BUTTON_ACTION_ANIM_TIME opacity: 255.0f ]];                
                timeLastDirtyVisibleChanged_ = time;
            }
            else if ( ( nodeSaveNew_.opacity != 0 && !scoop->isDirty()) )
            {
                // the scoop returned to a non-dirty state
                [nodeSaveNew_ runAction: [CCFadeTo actionWithDuration: UI_BUTTON_ACTION_ANIM_TIME opacity: 0.0f ]];
                timeLastDirtyVisibleChanged_ = time;
            }

            
        }

        
       
    }
    
    if ( scoop->isDirty() ) 
    {
        loadedSaveUID_ = -1;
    }
    
    // should any of the saved setting icons be highlighted? (i.e. indicate we are currently viewing their saved state)
    
    

    
    // ensure highlight state is correct and z-value is correct
    for( CCSprite *curSprite in existingSaveNodes_ )
    {
        
        int iID = curSprite.tag;
        
        // what is the "active" texture?        
        NSString *activeTexName = getPlatformResourceName( [NSString stringWithFormat: @"sv_%d", iID  ], @"png" );        
                
        // what is the "inactive" texture?
        NSString *inactiveTexName = getPlatformResourceName( [NSString stringWithFormat: @"%d_00029", iID ], @"png" );           
        
        
        CCTexture2D *saveTexture = [[CCTextureCache sharedTextureCache] textureForKey:inactiveTexName ];
        CCTexture2D *saveSelectTexture = [[CCTextureCache sharedTextureCache] textureForKey: activeTexName ];
        
        // ensure the textures are in the cache
        if ( saveTexture == nil )
        {
            saveTexture = [[CCTextureCache sharedTextureCache] addImage: inactiveTexName ];
        }
        
        if ( saveSelectTexture == nil )
        {
            saveSelectTexture = [[CCTextureCache sharedTextureCache] addImage: activeTexName ];
        }
        
        
        CCTexture2D *curTexture = [curSprite texture];
        
        if ( curSprite.tag == loadedSaveUID_ )
        {
            
            if ( curTexture == saveTexture )
            {
                [curSprite setTexture: saveSelectTexture];
            }
            
        }
        else
        {
            if ( curTexture != saveTexture )
            {
                [curSprite setTexture: saveTexture];
            }
            
        }
        
        
        int curZ = curSprite.zOrder;
        int targetZ = (curSprite == nodeTouchedSave_ ? UI_CONTROL_Z_DRAGGED : UI_CONTROL_Z_NONDRAGGED );
        
        if ( targetZ != curZ )
        {            
            [[curSprite parent] reorderChild:curSprite z:targetZ];            
        }
    }
    
    buttonPause_.visible = !scoop->isPaused();
    buttonPlay_.visible = !buttonPause_.visible;

    
    [self updateBPMIndicator];
    
}



//
//
-(void) hidePopover
{
    
    if ( gbIsIPad && popControllerBeatSets_ )
    {
        [popControllerBeatSets_ dismissPopoverAnimated: true];
        [popControllerBeatSets_ release];
        popControllerBeatSets_ = nil;
    }      
    
}
//
// completes the dismiss operation so we aren't
// doing it in a delegate callback
-(void) doDismissBeatSetView
{

    
    if ( gbIsIPad )
    {
        [self hidePopover];
    }      
    else
    {
        // let's not dismiss the iphone view automatically
        //[mainViewController_ dismissModalViewControllerAnimated:true];
    }
    
    [self scoopSetPaused: false];
    
    ScoopLibrary& lib = ScoopLibrary::Library();    
    ScoopBeatSet * newBS = lib.beatSetWithID( pendingBeatSetID_ );
        
    if ( newBS && scoop->getBeatSet() != pendingBeatSetID_ )
    {
        scoop->setBeatSet( pendingBeatSetID_ );
        assert( newBS->getNumBeats() > 0 );
        
        // what beat from the set should we start with?
        // just choose the first in the set
        scoop->setCurBeat( newBS->getBeatAt(0)->getBeatUID() );
        
        [self setBeatUIVisibility: UI_BUTTON_ACTION_ANIM_TIME];
        
    }

    

}

//
// only called when the user dismisses the popover by touching elsewhere,
// not by selecting a new 
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self scoopSetPaused: false];
}

//
// ScoopBeatSetIDTarget
-(void) onBeatSetIDSelected: (int) beatSetID
{
    pendingBeatSetID_ = beatSetID;
    
    [self performSelector: @selector( doDismissBeatSetView ) withObject:nil afterDelay:.01f];
        
}

-(void) onTempoChanged: (float) normalizedTempo
{
    scoop->setSpeed( normalizedTempo );
}

-(float) getNormalizedTempo
{
    return scoop->getNormalizedCurSpeed();
}



//
// 
-(void) onBeatSetButton: (id) sender
{
    
    [self showTempoSlider: false]; // any touch besides tempo slider hides it    
    //CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    
    pendingBeatSetID_ = -1;
    int iBeatSetID = scoop->getBeatSet();
    ScoopBeatSet * bsActive = ScoopLibrary::Library().beatSetWithID( iBeatSetID );
    if ( bsActive )
    {
            
        int iActiveIndex = bsActive->getUID()-1;

        UINavigationController * navigationController = nil;
        
        if ( gbIsIPad )
        {    
            
            beatController_.selectedSetIndex_ = iActiveIndex;            
            navigationController = [[UINavigationController alloc] initWithRootViewController:beatController_];
            navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
            
            popControllerBeatSets_ = [[UIPopoverController alloc] initWithContentViewController: navigationController];            
           
            int popAdjust = 0;
            if ( [SettingsManager manager].purchasedBeatSet1_ )
            {
                popAdjust = -1; // avoid last white line
            }
            popControllerBeatSets_.popoverContentSize = CGSizeMake(320, BEAT_SELECT_VIEW_PURCHASED_HEIGHT + navigationController.navigationBar.frame.size.height - 7 + popAdjust );  // for some reason the nav height calculation is off by 7 pixels        
            popControllerBeatSets_.delegate = self;
            
            
            CGRect popoverRect = CGRectMake( buttonBeatSet_.contentSize.width / 2.0f, buttonBeatSet_.contentSize.height / 2.0f, 1, 1);
            
            //        // have to special case this since our GL view doesn't rotate
            //        if ( currentOrientation_ == UIDeviceOrientationPortraitUpsideDown )
            //        {
            //            popoverRect = CGRectMake( winSize.width - buttonBeatSet_.contentSize.width / 2.0f, winSize.height - buttonBeatSet_.contentSize.height / 2.0f, 1, 1);
            //        }
            
            
            
            
            // for now let's try crossfading
            //scoop->setPaused(true);
            
            [popControllerBeatSets_ presentPopoverFromRect:popoverRect inView: [[CCDirector sharedDirector] openGLView] permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
        }
        else 
        {            
            
             navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewPhone_];
             navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
            settingsViewPhone_.beatSetIDDelegate_ = self;
            [mainViewController_ presentModalViewController: navigationController animated:TRUE];
            
        }
        
        
        [navigationController release];
    }
    
}


//
//
//-(void) displayPhoneTrackSwapAnim: (float) duration
//{
//        
//    if ( !gbIsIPad )
//    {
//        trackSwapSprite_.opacity = 255;
//        [trackSwapSprite_ runAction:[CCFadeOut actionWithDuration: duration]];
//    }
//}


//
//
-(void) cleanupInfoScreen
{
    //[infoScreen_ removeFromParentAndCleanup:true];
    //infoScreen_ = nil;
    
    if ( menuInfo_ )
    {
        [menuInfo_ removeFromParentAndCleanup:true];
    }
    
    menuInfo_ = nil;
    infoScreen_ = nil;

}

//
//
-(void) clearInfoScreen 
{
    if ( infoScreen_ )
    {
        [infoScreen_ runAction: [CCSequence actionOne: [CCFadeOut actionWithDuration: INFO_SCREEN_FADE_TIME] two: [CCCallFunc actionWithTarget:self selector: @selector( cleanupInfoScreen ) ] ]];  
        
        [self scoopSetPaused: savedPauseVal_];

    }
    
}


//
//
-(void) onInfoButton: (id) sender
{
    
    [self showTempoSlider: false]; // any touch besides tempo slider hides it
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    
    if ( menuInfo_ )
    {
        [menuInfo_ removeFromParentAndCleanup:true];
    }
    
    savedPauseVal_ = scoop->isPaused();
    [self scoopSetPaused: true];
    
    menuInfo_ = [CCMenu menuWithItems:nil];
    menuInfo_.position = CGPointZero;
    [self addChild: menuInfo_ z: 999999999];
    
    infoScreen_ = [CCMenuItemImage itemFromNormalImage:getPlatformResourceName( @"info", @"png" ) selectedImage:getPlatformResourceName( @"info", @"png" ) target:self selector:@selector( clearInfoScreen ) ];
    [menuInfo_ addChild: infoScreen_ z: 1];
    
    
    infoScreen_.position = CGPointMake(winSize.width / 2.0f, winSize.height / 2.0f );    
    [infoScreen_ runAction: [CCFadeIn actionWithDuration: INFO_SCREEN_FADE_TIME]];
    
    
    
    /*
    //////////////////////////////
    //  temporary: show tuning controls
    //////////////////////////////
    
    
    if ( gbIsIPad )
    {    
        
        
                
        UIPopoverController *pc = [[UIPopoverController alloc] initWithContentViewController: controllerAudioTuning_];
        pc.popoverContentSize = CGSizeMake(700, 300);                        
        CGRect popoverRect = CGRectMake( winSize.width, 0, 1, 1);
        
        [pc presentPopoverFromRect:popoverRect inView: [[CCDirector sharedDirector] openGLView] permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
    }

    */
    
    

}


- (void) scoopSetPaused: (bool) bPause
{
    if ( scoop && (bPause != scoop->isPaused()) )
    {
        scoop->setPaused(bPause);
    }

    // no longer using
    
//    if ( !bPause )
//    {
//        // process queued up rotation messages
//        
//        for (NSMutableDictionary *params in savedRotateData_ )
//        {
//            [self doScoopWillRotate: params];
//        }
//        
//        [savedRotateData_ removeAllObjects];
//        
//    }
}

//
//
- (bool) justBecameActiveAgain
{
    double activeDelta = CACurrentMediaTime() - timeLastBecameActive_;
    //NSLog( @"active delta: %f\n", activeDelta );

    return activeDelta < 0.5 && timeLastResignedActive_ > 0.0f;    
}

@end
