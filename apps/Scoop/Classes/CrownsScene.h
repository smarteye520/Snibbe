//
//  HelloWorldScene.h
//  Scoop
//
//  Created by Scott Snibbe on 7/18/10.
//  Copyright Scott Snibbe 2010. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
//#import "Box2D.h"
//#import "GLES-Render.h"
#import "Scoop.h"
#import "BeatListController.h"
#import "SettingsViewPhone.h"

#import "UIViewControllerAudioTuning.h"


typedef enum
{
	eNormal = 1,
	eTrackingTempo,      // dragging the tempo slider
    eTouchedSaveNew,     // touch down on the save new scoop button
    eTouchedSavedScoop,  // touch down on a load button and haven't moved past the drag distance threshold
    eDraggingSavedScoop, // dragging a load button and we've moved past the drag distance threshold
    eTouchedBeat,        // down down on a beat button
	
} ScoopUIInputState;



// HelloWorld Layer
@interface Crowns : CCLayer <UIPopoverControllerDelegate, ScoopBeatSetIDTarget>
{
	//b2World* world;
	//GLESDebugDraw *m_debugDraw;
	Scoop				*scoop;
	ofxMSAShape3D		*shape3D;

    bool                retinaEnabled_;
	UIDeviceOrientation currentOrientation_;
	float				landscapeBaseYVal_;
	float				landscapeBaseXVal_;
	int                 pendingBeatSetID_;
    
    
	ScoopUIInputState   inputState_;
    bool                prevScoopDirty_;            // was the scoop dirty on the last frame?
    
    
    UIViewController    *mainViewController_;       // the app's top level view controller associated with the gl view
    UIPopoverController *popControllerBeatSets_;
    
    BeatListController *beatController_;    // for iPad
    SettingsViewPhone  *settingsViewPhone_; // for iPhone
    
    UIViewControllerAudioTuning *controllerAudioTuning_;
    
    // tracking that allows us to smoothly resize the gl view
    // over the course of the rotation
    bool                resizingView_;
    CGRect              resizingViewRectBegin_;
    CGRect              resizingViewRectEnd_;
    double              resizingViewTimeBegin_;
    double              resizingViewTimeEnd_;
    
    NSMutableDictionary * savedOpacityState_;
    bool                  uiHidden_;
    double                timeUIHidden_;
    double                timeUIRestored_;
    double                timeOrientationChangedToPortrait_;
    double                timeOrientationChangedToLandscape_;
    double                timeLastDirtyVisibleChanged_;
    UIDeviceOrientation   pendingDeviceOrientation_;
    
    // cocos-2d based UI functionality    
    
    CCNode              *controlParent_;
    CCSprite            *cursor_;
    
    // general
    CCMenu              *menuGeneral_;              // general parent menu object for any normal buttons
    CCMenu              *menuPersistent_;           // menu that doesn't disappear in landscape
    
    // quantize mode button
    CCMenuItemImage     *buttonQuantizeOn1_;
    CCMenuItemImage     *buttonQuantizeOn2_;    
    CCMenuItemImage     *buttonQuantizeOff_;
    
	// tempo slider
	CCSprite			*sliderBG_;
	CCSprite            *sliderButton_;
    CCMenuItemImage     *tempoButton_;

    // button mute beats
    CCMenuItemImage     *buttonMuteBeatsOff_;
    CCMenuItemImage     *buttonMuteBeatsOn_;
    
    double               lastTempoTouchTime_;
    
    double               timeLastBecameActive_;
    double               timeLastResignedActive_;
    
    CCSprite            *uiDividerLeft_;
    CCSprite            *uiDividerRight_;
    
    // pause play
    CCMenuItemImage     *buttonPause_;
    CCMenuItemImage     *buttonPlay_;
        
    // save / load nodes
    // not using menu b/c desired behavior doesn't conform to 
    // CCMenuItem behavior... have to special case the behavior
    // "buttons that also drag"
    
    CCNode              *saveLoadParent_;    
    NSMutableArray      *existingSaveNodes_;    
    //NSMutableArray      *saveLoadNumbers_;    
    CCSprite            *nodeSaveNew_;
    CCSprite            *nodeTouchedSave_;
    CGPoint             nodeTouchedSaveOriginalPt_; // in node's frame or reference
    
    CGSize              saveLoadImageSize_;         // dimensions for save/load sprites 
    int                 loadedSaveUID_;             // unique ID of the last loaded save

    // drum patterns
    NSMutableArray      *beatNodes_;
    CCSprite            *nodeTouchedBeat_;      
    
    // in-app purchase
    CCMenuItemImage     *buttonBeatSet_;
        
    // more info
    CCMenuItemImage     *buttonInfo_;  
    
    NSMutableArray      *savedRotateData_;
    
    // platform specific
    //CCSprite            *trackSwapSprite_;
    	
    CCMenu              *menuInfo_;
    CCMenuItem          *infoScreen_;
    bool                savedPauseVal_;
    
    int                 drawDelay_;
    bool                isActive_;
    
    int                 numTouchEventsInCurSequence_;
    float               touchesY_[MAX_NUM_TOUCH_SMOOTHING];

}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene: (bool) bRetina withViewController: (UIViewController *) vc;

-(void) setRetinaEnabled: (bool) bEnabled;

@property (nonatomic, assign) UIViewController * mainViewController_;

// adds a new sprite at a given coordinate
//-(void) addNewSpriteWithCoords:(CGPoint)p;



@end
