/*
 *  ScoopDefs.h
 *  Scoop
 *
 *  Created by Graham McDermott on 3/15/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#ifndef __SCOOP_DEFS_H__
#define __SCOOP_DEFS_H__

#define VOLUME_GRAPH_INDEX 2
#define PITCH_GRAPH_INDEX 0
#define FILTER_GRAPH_INDEX 1
#define NUM_VALUE_GRAPHS 3

#define MIN_CROWN_PIXEL_HEIGHT 4

#define GRAPH_SIZE (16*40)

// quantize pitch on the y axis 
#define MAX_NUM_QUANTIZE_STEPS 32

#define MAX_NUM_TOUCH_SMOOTHING 10

// quantize in time 
#define QUANTIZE_STEPS_PITCH_1 16
#define QUANTIZE_STEPS_VOLUME_1 16
#define QUANTIZE_STEPS_FILTER_1 16

#define QUANTIZE_STEPS_PITCH_2 32
#define QUANTIZE_STEPS_VOLUME_2 32
#define QUANTIZE_STEPS_FILTER_2 32

#define INITIAL_FADE_UP_DURATION 2.0f

#define MIN_TIME_BETWEEN_UI_HIDE_SHOW 1.0f
#define TIME_IN_ORIENTATION_BEFORE_SCOOP_WRAP 0.5f

#define SYNTH_VOL_MAX 0.1f

#define QUANTIZE_STEPS_PITCH_Y_DIR 24
#define PITCH_SHIFT_RANGE 24
#define PITCHSHIFT_BASE	-12

#define WRAP_SCENE_TRANSFORMATION_DURATION 0.5f

// time delay for orientation processing so we don't pass through intermediate phases
#define SAVE_VISIBLE_TIME_THRESHOLD 0.7f

#define LANDSCAPE_SCENE_SCALE 0.8f

#define DELETE_ANIM_DURATION 0.5f

#define NUM_BEATS_PER_LOOP 8
#define MAX_BPM 140.0f
#define MIN_BPM 60.0f

#define FILTER_RESONANCE 4.0
#define MIN_FILTER_CUTOFF 177.61
#define MAX_FILTER_CUTOFF 3999.04

#define MAX_SAVED_SCOOPS_IPAD 12
#define MAX_SAVED_SCOOPS_IPHONE 4

#define SAVE_ANIM_FRAME_FIRST 0
#define SAVE_ANIM_FRAME_LAST 29

#define MAX_BEATS_PER_SET_IPAD 6
#define MAX_BEATS_PER_SET_IPHONE 4

#define NUM_BEAT_FRAMES 4
#define NUM_BEAT_FRAME_ANIM_CYCLES_PER_AUDIO_CYCLE 8
#define BEAT_FRAME_INDEX_DEFAULT 2

#define UI_CONTROL_Z_SAVELOAD_PARENT 10
#define UI_CONTROL_Z_BEATNODE_PARENT 10
#define UI_CONTROL_Z_TEMPO_SLIDER_BG 6
#define UI_CONTROL_Z_GENERAL_BUTTONS 4
#define UI_CONTROL_Z_TEMPO_SLIDER_KNOB 7
#define UI_CONTROL_Z_DIVIDERS 2
#define UI_CONTROL_Z_CURSOR 1000

// these z values are relative to saveload parent
#define UI_CONTROL_Z_DRAGGED 20
#define UI_CONTROL_Z_NONDRAGGED 10

#define SAVE_LOAD_ICON_PADDING 0
#define BEAT_SET_ICON_PADDING 0
#define SAVE_LOAD_NUMBER_PADDING_RIGHT 8.0f

#define UI_TEMPO_FADE_TIME 0.3f
#define UI_BUTTON_ACTION_ANIM_TIME 0.6f
#define UI_DRAG_DIST_THRESHOLD 30.0f

#define UI_DIVIDER_VERTICAL_COVERAGE 0.80f
#define UI_DIVIDER_SPACING_TO_ICON_SIZE 1.6f

#define MAX_SCOOP_BEAT_FILENAME_LEN 128
#define MAX_SCOOP_BEAT_DESCRIPTION_LEN 256

#define TEMPO_DISAPPEAR_TIME_THRESHOLD 8.0f
#define BEAT_CROSSFADE_TIME 0.6f
#define BEAT_VOL 1.0f

#define UI_ORIENTATION_CHANGED_FADE_TIME .50f

#define CURSOR_WIDTH 15
#define LANDSCAPE_EDIT_NON_QUANTIZE_WIDTH 8

// estimate regarding latency to use in correcting playhead position.
// update with actual measurements if possible
#define ESTIMATED_AUDIO_LATENCY 0.1f

#define BEAT_SELECT_VIEW_PURCHASED_HEIGHT 312

#define INFO_SCREEN_FADE_TIME 0.3f

#define BEAT_TABLE_CELL_HEIGHT 52.0f


// flurry events

// flurry events
extern NSString * gEventSharedFB;
extern NSString * gEventSharedTwitter;
extern NSString * gEventSharedEmail;
extern NSString * gEventSavedCameraRoll;
extern NSString * gEventProIAP;
extern NSString * gEventIOSVersion;
extern NSString * gEventParamIOSVersionNumber;

// to add...
// which beat sets are most popular?



#endif // __SCOOP_DEFS_H__