//
//  defs.mm
//  MotionPhone
//
//  Created by Graham McDermott on 1/25/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#include "defs.h"


// definitions of global objects

Parameters *gParams;    // global Parameters
MCanvas *gMCanvas;      // global MCanvas
MBrush *gMBrush;        // global MBrush
Facebook * gFacebook;   // global Facebook
bool gUseMultiSample = false; // global use multi-sample
UIDeviceOrientation gDeviceOrientation = UIDeviceOrientationPortrait;
float gWinScaleDefaultX = 1.0f;
float gContentScaleFactor = 1.0f;

NSString * gNotificationFirstValidOrientation = @"first_valid_orientation";
NSString * gNotificationGlobalOrientationChanged = @"global_orientation_changed";

NSString * gNotificationAppDidEnterBG = @"app_did_enter_bg";
NSString * gNotificationBeginMatch = @"match_did_begin";
NSString * gNotificationUnableToBeginMatch = @"unable_to_begin_match";
NSString * gNotificationEndMatch = @"match_did_end";
NSString * gNotificationMatchPlayersChanged = @"match_players_changed";
NSString * gNotificationMultiplayerButtonPressed = @"onMultiPlayerButtonPressed";
NSString * gNotificationFinalizeMultiplayerInit = @"finalize_multiplayer_init";

NSString * gNotificationRequestEraseCanvas = @"request_erase_canvas";
NSString * gNotificationRequestGoHome = @"request_go_home";
NSString * gNotificationRequestUndo = @"request_undo";
NSString * gNotificationToolModeChanged = @"onToolModeChanged";
NSString * gNotificationMinFrameTimeChanged = @"min_frame_time_changed";
NSString * gNotificationFrameDirChanged = @"frame_dir_changed";

NSString * gNotificationBrushWidthChanged = @"brush_width_changed";
NSString * gNotificationBrushOrientChanged = @"brush_orient_changed";
NSString * gNotificationBrushFillChanged = @"brush_fill_changed";
NSString * gNotificationBrushShapeChanged = @"brush_shape_changed";
NSString * gNotificationBGColorChanged = @"bg_color_changed";
NSString * gNotificationFGColorChanged = @"fg_color_changed";

NSString * gNotificationPendingBegin = @"mp_pending_begin";
NSString * gNotificationPendingEnd = @"mp_pending_end";

NSString * gNotificationShowBlockingGradient = @"mp_show_blocking_gradient";
NSString * gNotificationHideBlockingGradient = @"mp_hide_blocking_gradient";

NSString * gNotificationShowFixedBlockingGradient = @"mp_show_fixed_blocking_gradient";
NSString * gNotificationHideFixedBlockingGradient = @"mp_hide_fixed_blocking_gradient";

NSString * gNotificationFBLoggedOn = @"mp_facebook_logged_on";
NSString * gNotificationFBLoggedOff = @"mp_facebook_logged_off";

NSString * gNotificationToolbarShown = @"mp_toolbar_shown";
NSString * gNotificationToolbarHidden = @"mp_toolbar_hidden";

NSString * gNotificationLoadedCanvas = @"mp_loaded_canvas";
NSString * gNotificationSavedCanvas = @"mp_saved_canvas";

NSString * gNotificationRefreshMediaButton = @"mp_refresh_media_button";

NSString * gNotificationRequestFPSViewOnOff = @"request_fps_on_off";
NSString * gNotificationRequestColorViewOnOff = @"request_color_on_off";
NSString * gNotificationRequestBrushViewOnOff = @"request_brush_on_off";
NSString * gNotificationRequestRecordViewOnOff = @"request_record_on_off";
NSString * gNotificationRequestInfoViewOnOff = @"request_info_on_off";
NSString * gNotificationRequestHelpViewOnOff = @"request_help_on_off";
NSString * gNotificationRequestEssayViewOnOff = @"request_essay_on_off";
NSString * gNotificationRequestSaveShareViewOnOff = @"request_saveshare_on_off";
NSString * gNotificationRequestLoadViewOnOff = @"request_load_on_off";
NSString * gNotificationRequestMediaViewOnOff = @"request_media_picker_on_off";

NSString * gNotificationFPSViewOn = @"fps_view_on";
NSString * gNotificationFPSViewOff = @"fps_view_off";
NSString * gNotificationColorViewOn = @"color_view_on";
NSString * gNotificationColorViewOff = @"color_view_off";
NSString * gNotificationBrushViewOn = @"brush_view_on";
NSString * gNotificationBrushViewOff = @"brush_view_off";
NSString * gNotificationRecordViewOn = @"record_view_on";
NSString * gNotificationRecordViewOff = @"record_view_off";
NSString * gNotificationInfoViewOn = @"info_view_on";
NSString * gNotificationInfoViewOff = @"info_view_off";
NSString * gNotificationEssayViewOn = @"essay_view_on";
NSString * gNotificationEssayViewOff = @"essay_view_off";
NSString * gNotificationHelpViewOn = @"help_view_on";
NSString * gNotificationHelpViewOff = @"help_view_off";
NSString * gNotificationSaveShareViewOn = @"share_view_on";
NSString * gNotificationSaveShareViewOff = @"share_view_off";
NSString * gNotificationLoadViewOn = @"load_view_on";
NSString * gNotificationLoadViewOff = @"load_view_off";
NSString * gNotificationMediaViewOn = @"mediapicker_view_on";
NSString * gNotificationMediaViewOff = @"mediapicker_view_off";


NSString * gNotificationCanvasTouchDown = @"canvas_touch_down";

NSString * gNotificationDismissUIDeep = @"dismiss_ui_deep";
NSString * gNotificationDismissUIDeepComplete = @"dismiss_ui_deep_complete";

// flurry events

NSString * gEventSharedFB = @"shared facebook";
NSString * gEventSharedTwitter = @"shared twitter";
NSString * gEventSharedEmail = @"shared email";
NSString * gEventSavedCameraRoll = @"saved camera roll";
NSString * gEventStartedMultiplayer = @"started multiplayer";
NSString * gEventIOSVersion = @"ios version";
NSString * gEventParamIOSVersionNumber = @"ios version number";



// hacked performance mode globals
bool gDrawPerformanceFGColorIndicator = false;
bool gDrawPerformanceBrushSizeIndicator = false;
float gPerformanceFGColorIndicatorAlpha = 0.0f;
float gPerformanceBrushSizeIndicatorAlpha = 0.0f;


