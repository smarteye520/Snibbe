/* $Id: defs.H,v 1.3 1993/10/16 17:35:38 sss Exp $ */

/* defs.H
   Author: Scott S. Snibbe
  (c) 1989-2010 Scott Snibbe
 */

#pragma once

/* Includes 
 */



#include <math.h>
#include <stdlib.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#include "ofxMSAShape3D.h"


////////////////////////////////////////
// define this for performance mode builds
////////////////////////////////////////

//#define PERFORMANCE_MODE
//#define PERFORMANCE_MODE_COLORS

// Globals

class MCanvas;
extern MCanvas *gMCanvas;
class Parameters;
extern Parameters *gParams;
class MBrush;
extern MBrush *gMBrush;
@class Facebook;
extern Facebook * gFacebook;
extern float gContentScaleFactor;

extern UIDeviceOrientation gDeviceOrientation;
extern float gWinScaleDefaultX;

extern NSString * gNotificationFirstValidOrientation;
extern NSString * gNotificationGlobalOrientationChanged;

extern NSString * gNotificationAppDidEnterBG;
extern NSString * gNotificationUnableToBeginMatch;
extern NSString * gNotificationBeginMatch;
extern NSString * gNotificationEndMatch;
extern NSString * gNotificationMatchPlayersChanged;
extern NSString * gNotificationMultiplayerButtonPressed;
extern NSString * gNotificationFinalizeMultiplayerInit;

extern NSString * gNotificationRequestEraseCanvas;
extern NSString * gNotificationRequestGoHome;
extern NSString * gNotificationRequestUndo;
extern NSString * gNotificationToolModeChanged;
extern NSString * gNotificationMinFrameTimeChanged;
extern NSString * gNotificationFrameDirChanged;
extern NSString * gNotificationBrushWidthChanged;
extern NSString * gNotificationBrushOrientChanged;
extern NSString * gNotificationBrushFillChanged;
extern NSString * gNotificationBrushShapeChanged;
extern NSString * gNotificationBGColorChanged;
extern NSString * gNotificationFGColorChanged;

extern NSString * gNotificationPendingBegin;
extern NSString * gNotificationPendingEnd;

extern NSString * gNotificationShowBlockingGradient;
extern NSString * gNotificationHideBlockingGradient;

extern NSString * gNotificationLoadedCanvas;
extern NSString * gNotificationSavedCanvas;

extern NSString * gNotificationRefreshMediaButton;

extern NSString * gNotificationShowFixedBlockingGradient;
extern NSString * gNotificationHideFixedBlockingGradient;

extern NSString * gNotificationFBLoggedOn;
extern NSString * gNotificationFBLoggedOff;

extern NSString * gNotificationToolbarShown;
extern NSString * gNotificationToolbarHidden;

extern NSString * gNotificationRequestFPSViewOnOff;
extern NSString * gNotificationRequestBrushViewOnOff;
extern NSString * gNotificationRequestColorViewOnOff;
extern NSString * gNotificationRequestRecordViewOnOff;
extern NSString * gNotificationRequestInfoViewOnOff;
extern NSString * gNotificationRequestHelpViewOnOff;
extern NSString * gNotificationRequestEssayViewOnOff;
extern NSString * gNotificationRequestSaveShareViewOnOff;
extern NSString * gNotificationRequestLoadViewOnOff;
extern NSString * gNotificationRequestMediaViewOnOff;

extern NSString * gNotificationFPSViewOn;
extern NSString * gNotificationFPSViewOff;
extern NSString * gNotificationColorViewOn;
extern NSString * gNotificationColorViewOff;
extern NSString * gNotificationBrushViewOn;
extern NSString * gNotificationBrushViewOff;
extern NSString * gNotificationRecordViewOn;
extern NSString * gNotificationRecordViewOff;
extern NSString * gNotificationInfoViewOn;
extern NSString * gNotificationInfoViewOff;
extern NSString * gNotificationEssayViewOn;
extern NSString * gNotificationEssayViewOff;
extern NSString * gNotificationHelpViewOn;
extern NSString * gNotificationHelpViewOff;
extern NSString * gNotificationSaveShareViewOn;
extern NSString * gNotificationSaveShareViewOff;
extern NSString * gNotificationLoadViewOn;
extern NSString * gNotificationLoadViewOff;
extern NSString * gNotificationMediaViewOn;
extern NSString * gNotificationMediaViewOff;

extern NSString * gNotificationCanvasTouchDown;

extern NSString * gNotificationDismissUIDeep;
extern NSString * gNotificationDismissUIDeepComplete;

// flurry events
extern NSString * gEventSharedFB;
extern NSString * gEventSharedTwitter;
extern NSString * gEventSharedEmail;
extern NSString * gEventSavedCameraRoll;
extern NSString * gEventStartedMultiplayer;
extern NSString * gEventIOSVersion;
extern NSString * gEventParamIOSVersionNumber;

extern bool gUseMultiSample;

// hacked performance mode globals

extern bool gDrawPerformanceFGColorIndicator;
extern bool gDrawPerformanceBrushSizeIndicator;
extern float gPerformanceFGColorIndicatorAlpha;
extern float gPerformanceBrushSizeIndicatorAlpha;


// types
typedef void * MTouchKeyT;
typedef int ShapeID;


typedef enum
{
    eActionBrush = 1,
    eActionUndo,
    eActionClear,
    eActionBGColor,
    eActionUpdateBrushVals,
    eActionMessage,
    
} MPActionT;


typedef enum {
    MotionPhoneTool_Brush,
    MotionPhoneTool_Hand    
} MotionPhoneTool;


// Constants

const int X = 0;
const int Y = 1;

#define MOTION_PHONE_APP_ID_PAD 373089458
#define MOTION_PHONE_APP_ID_PHONE 496373354

#define USE_GAMECENTER 0

#if USE_GAMECENTER
#define PEER_2_PEER 0
#else
#define PEER_2_PEER 1
#endif

#define USE_MULTIPLAYER_LABELS 0

#define PIOVER2 1.570796327
#define PI 3.141592654
#define TWOPI 6.283185308
#define DEGREES_TO_RADIANS 0.0174532925 

#define N_FRAMES 30

// defaults

#define DEFAULT_CONSTANT_OUTLINE_WIDTH true
#define DEFAULT_FADE_STROKES true
#define DEFAULT_DRAWING_HIDES_UI true

// multiplayer / networking

#define NETWORK_DEBUG_OUTPUT 0
#define NETWORK_SPEED_UPDATE_INTERVAL 60.0f

#define MULTIPLAYER_NUM_PLAYERS_MIN 2
#define MULTIPLAYER_NUM_PLAYERS_MAX 4

#define ACTION_SHAPE_ID_BYTES 4
#define ACTION_POINT_BYTES 8
#define ACTION_FLOAT_BYTES 4
#define ACTION_INT_BYTES 4
#define ACTION_CHAR_BYTES 4
#define ACTION_COLOR_BYTES 4

#define PLAYER_LABEL_FADE_TIME 0.5f
// colors
// for 2d array of colors on-screen

#ifdef PERFORMANCE_MODE_COLORS

#define COLORWIDTH 14
#define COLORHEIGHT 8

#else

#define COLORWIDTH 28
#define COLORHEIGHT 14


#endif

#define NCOLORS (COLORWIDTH * COLORHEIGHT)

typedef float  MColor[4];

// shapes, strokes and brushes

#ifdef MOTION_PHONE_MOBILE

#define MIN_BRUSH_WIDTH 2.0f
#define MAX_BRUSH_WIDTH 75.0f

#else

#define MIN_BRUSH_WIDTH 2.0f
#define MAX_BRUSH_WIDTH 120.0f

#endif

#define MAX_POLYGON_POINTS 20

#define MAX_STRETCH_LARGEST_BRUSH 3.0f
#define MAX_STRETCH_MID_BRUSH 2.0f
#define MAX_STRETCH_SMALLEST_BRUSH 10.0f

#define BRUSH_STRETCH_MIDPOINT 0.10



#define THETA_FILTER 0.4f
#define MIN_DIST_ORIENT_UPDATE 2.0f
#define MIN_DIST_ORIENT_UPDATE_SQUARED ( MIN_DIST_ORIENT_UPDATE * MIN_DIST_ORIENT_UPDATE )

#define MIN_DIST_ORIENT_SECOND_TOUCH 7.0f
#define MIN_DIST_ORIENT_SECOND_TOUCH_SQUARED ( MIN_DIST_ORIENT_SECOND_TOUCH * MIN_DIST_ORIENT_SECOND_TOUCH )

#define FRAME_NUM_THETA_FILTER_BEGIN 5
#define FRAME_NUM_ORIENT_DIST_TEST_BEGIN 5

#define MIN_RADIANS_WRAP_AROUND (TWOPI * 0.90f)
#define ID_SHAPE_DEFAULT 1

#define UNINIT_ORIENTATION -2000.0f
#define MAX_TEXTURE_LENGTH_NAME 128

#define MBrushType_NUM 5

#define NUM_TOUCH_FADE_FRAMES 8

#define MIN_FRAME_TIME_MIN ( (1.0f / 60.0f) * .98f )        // ~60 FPS
#define MIN_FRAME_TIME_MAX ( MIN_FRAME_TIME_MIN * 30.0f )   // ~2 FPS

#define MIN_FPS (1.0f / MIN_FRAME_TIME_MAX)
#define MAX_FPS (1.0f / MIN_FRAME_TIME_MIN)

#define FRAME_TIME_ABOVE_WHICH_ALLOW_MULTIPLE_STROKES_PER_FRAME .0217f

#define MIN_DISPLAY_FPS 2.0f
#define MAX_DISPLAY_FPS 60.0f

#define SESSION_VAR_SAVE_INTERVAL 1.0f

#define TIME_BG_FLASH 1.0f
#define BG_FLASH_PERCENT_FULL 0.01f



// general UI

#define SPLASH_FADE_DELAY 2.5f
#define SPLASH_FADE_DURATION 0.5f

#define PENDING_ANIM_FADE_TIME 1.0f
#define PENDING_ANIM_ROTATE_TIME 2.0f

#define TOOLBAR_ANIMATION_TIME 0.33f
#define TOOLBAR_ANIMATION_TIME_PHONE 0.33f
#define TOOLBAR_ANIMATION_TIME_CANVAS_TOUCHDOWN 0.1f
//#define TOOLBAR_FULL_OPACITY 0.75f
#define TOOLBAR_FULL_OPACITY 1.0f

#define UI_CORNER_RADIUS 6.0f
#define UI_CORNER_RADIUS_PHONE 30.0f

#define STATUS_MESSAGE_DURATION 2.0f
#define STATUS_MESSAGE_FADE_DURATION 1.0f

#define MIN_Z_SANITY_CHECK_INTERVAL 1.0f

#ifdef MOTION_PHONE_MOBILE
#define MAX_ACTIONS_SENT_PER_FRAME 250
#else
#define MAX_ACTIONS_SENT_PER_FRAME 1000
#endif

// sharing constants

#define MOTION_PHONE_YOUTUBE_DEVELOPER_KEY @"AI39si6sPsTZVIFnHbPauf3Gx1V45P7k4LvSAKBmeqWtTGRIhY9TeVOtQX9BnHWcjiQpJRQepCMUUf2wIoZWgc3nW9FHHsGM6A";


#define VIDEO_IMAGE_DESIRED_WIDTH_IPAD_LOW 640.0f
#define VIDEO_IMAGE_DESIRED_WIDTH_IPAD_HIGH 960.0f

#define VIDEO_IMAGE_DESIRED_WIDTH_IPHONE_LOW 480.0f
#define VIDEO_IMAGE_DESIRED_WIDTH_IPHONE_HIGH 960.0f

#define VIDEO_SHARE_NUM_LOOPS 15	
#define VIDEO_SHARE_NUM_LOOPS_CAMERA_ROLL 20

#define VIDEO_SHARE_FB_MAX_TIMESCALE 60
#define VIDEO_SHARE_TWITTER_MAX_TIMESCALE 60
#define VIDEO_SHARE_DEFAULT_MAX_TIMESCALE 60

#define VIDEO_SHARE_FRAME_INCREMENT_DEFAULT 1
#define VIDEO_SHARE_FRAME_INCREMENT_FB 1
#define VIDEO_SHARE_FRAME_INCREMENT_TWITTER 1

// only for facebook / twitter (no local or email)
#define VIDEO_OPTIMIZE_MAX_VIDEO_LENGTH 12.0f
#define VIDEO_OPTIMIZE_MIN_VIDEO_LENGTH 9.0f

#define VIDEO_DEFAULT_MAX_VIDEO_LENGTH 30.0f
#define VIDEO_DEFAULT_MIN_VIDEO_LENGTH 9.0f



#define MP_MATCHMAKING_TIMEOUT_SECONDS 30.0f


// Macros

#define IS_IPAD  (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define ARC4RANDOM_MAX      0x100000000LL
#define FRAND(A,B)  ((A) + floorf(((float)arc4random() / ARC4RANDOM_MAX) * ((B)-(A))))
#define glColor3f(r,g,b) glColor4f(r,g,b,1.0)
#define MCOLOR_COPY(D, S) { (D)[0] = (S)[0]; (D)[1] = (S)[1]; (D)[2] = (S)[2]; (D)[3] = (S)[3]; }
#define MCOLOR_SET(C, R, G, B, A) { (C)[0] = (R); (C)[1] = (G); (C)[2] = (B); (C)[3] = (A); }
#define MCOLOR_TO_INT32( COL, COL_INT ) { *(((unsigned char *) &COL_INT) + 0) = COL[0] * 255; \
                                          *(((unsigned char *) &COL_INT) + 1) = COL[1] * 255; \
                                          *(((unsigned char *) &COL_INT) + 2) = COL[2] * 255; \
                                          *(((unsigned char *) &COL_INT) + 3) = COL[3] * 255;  }


#define MCOLOR_FROM_INT32( COL, COL_INT ) { COL[0] = *(((unsigned char *) &COL_INT) + 0) / 255.0f; \
                                            COL[1] = *(((unsigned char *) &COL_INT) + 1) / 255.0f; \
                                            COL[2] = *(((unsigned char *) &COL_INT) + 2) / 255.0f; \
                                            COL[3] = *(((unsigned char *) &COL_INT) + 3) / 255.0f; }


#define SQUARE(A)	((A) * (A))
//#define MIN(A,B)	((A) < (B) ? (A) : (B))
//#define MAX(A,B)	((A) > (B) ? (A) : (B))
#define STREQL(S1, S2)  (!strcmp((S1), (S2)))








