/*
 *  Parameters.h
 *  gravilux
 *
 *  Created by Scott Snibbe on 2/27/10.
 *  Copyright 2010 Scott Snibbe. All rights reserved.
 *
 */

#pragma once

#include "Gravilux.h"
#include "defs.h"

#define DEFAULT_STARSIZE 1.0
#define DEFAULT_GRAVITY 3.1
#define DEFAULT_ROWS 56
#define DEFAULT_COLUMNS 56
#define DEFAULT_HEAT NO
#define DEFAULT_ANTIGRAVITY NO
#define DEFAULT_CORNER_TOUCH 0.2
#define DEFAULT_NCOLORS 3
#define DEFAULT_HEATSCALE 0.00025
#define MIN_STARSIZE 1.0
#define MAX_STARSIZE 2.0
#define MAX_ROWS 120
#define STARTUPSCREEN_DELAY 2.0
#define MAX_GRAVITY 50.0
#define MIN_GRAVITY 0.1
#define MAX_TYPE_LENGTH 140

// older iPhones
#define DEFAULT_GRAVITY_OLDPHONES 4.4
#define MAX_ROWS_OLDPHONES 90

#define DEFAULT_STARSIZE_IPAD 1.0
#define DEFAULT_GRAVITY_IPAD 1.3
#define DEFAULT_ROWS_IPAD 80
#define DEFAULT_COLUMNS_IPAD 80
#define DEFAULT_ROWS_IPAD2 120
#define DEFAULT_COLUMNS_IPAD2 120
#define DEFAULT_HEAT_IPAD NO
#define DEFAULT_ANTIGRAVITY_IPAD NO
#define DEFAULT_CORNER_TOUCH_IPAD 0.1
#define DEFAULT_HEATSCALE_IPAD 0.00005
#define MIN_STARSIZE_IPAD 1.0
#define MAX_STARSIZE_IPAD 3.0
#define MAX_ROWS_IPAD 140

// high res iPhones
#define DEFAULT_STARSIZE_HIPHONES 1.0
#define MIN_STARSIZE_HIPHONES 1.0
#define DEFAULT_GRAVITY_HIPHONES 3.0

class Parameters {
public:
	Parameters(Gravilux *app);
	
	void setInteractionTime() { lastInteractionTime_ = CFAbsoluteTimeGetCurrent(); }
	double getTimeSinceLastInteraction() { return CFAbsoluteTimeGetCurrent() - lastInteractionTime_; }
	
	bool save();
	bool load();
	bool savePreset(int num);
	bool loadPreset(int num, bool colorsOnly);
	void setDefaults(bool update=false); // whether to update app
	
	float	gravity() { return gravity_; }
	void	setGravity(float g) { gravity_ = g; }
	
	int		rows() { return rows_; }
	int		cols() { return cols_; }
	void	setSize(int r, int c) { rows_ = r; cols_ = c; app_->initGrains(); }

	void	setStarSize(float s) { 
		starSize_ = s;
		
		app_->setStarSize(deviceStarSize());
	}
	float	starSize() { return starSize_; }
	float	maxRows()	{ return maxRows_; }
	
	float	deviceStarSize() {
		if ([deviceString_ isEqualToString:@"iPhone 1G"] ||
			[deviceString_ isEqualToString:@"iPhone 3G"] ||
			[deviceString_ isEqualToString:@"iPod Touch 1G"] ||
			[deviceString_ isEqualToString:@"iPod Touch 2G"]) {
			return starSize_+1; 
		} else {
			return starSize_; 
		}
	}
	float	maxStarSize() { 
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			return MAX_STARSIZE_IPAD; 
		else 
			return MAX_STARSIZE;
	}
	float	minStarSize() { 
		return minStarSize_;
	}
	bool	heat() { return heat_; }
	void	setHeat(bool h) { heat_ = h; app_->showHeat(heat_); }
	
	bool	heatColor() { return heatColor_; }
	void	setHeatColor(bool h) { heatColor_ = h; }

	float	heatScale() { return heatScale_; }
	void	setHeatScale(float hs) { heatScale_ = hs; }
	
	bool	antigravity() { return antigravity_; }
	void	setAntigravity(bool a) { antigravity_ = a; }
	
	NSString*	settingsString() { return settingsString_; }
	NSString*	splashString() { return splashString_; }

	bool	galleryMode() { return galleryMode_; }
	void	setGalleryMode(bool m) { galleryMode_ = m; }
	
	bool	galleryModeLocked() { return galleryModeLocked_; }
	void	setGalleryModeLocked(bool m) { galleryMode_ = galleryModeLocked_ = m; }
	
	bool	music() { return music_; }
	void	setMusic(bool m) { music_ = m; }
	
	float	cornerTouch() { return cornerTouch_; }
	
	float	pdfLineWidth() { return 1.0; }
	float	pdfDotSize() { return 1.25; }
	float	pdfPointWidth() {
		CGSize screenSize = ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size;
		return (float)screenSize.width/(float)screenSize.height*10*72;
	}
	float	pdfPointHeight() { return 10*72; } // 10" x 72dpi	
	
	void	getColors(Color* colors);
	void	setColors(Color* colors);
	void	setColorsWalk(ColorSet colors);
	void	setColorSource(bool fromColorWalk);
	void	setDefaultColors();
	int		nColors() { return DEFAULT_NCOLORS;}
	
	float	getStartupScreenDelay() { return startupScreenDelay_; }
	
	void	dumpUserDefaults();

private:
	
	bool saveDefaultPresets(); // on first launch

	Gravilux *app_;
	NSString	*settingsString_, *splashString_, *deviceString_;
	float	gravity_, heatScale_;
	float	starSize_, minStarSize_;
	int		rows_, cols_, maxRows_;
	bool	heat_, heatColor_;
	bool	music_, galleryMode_, galleryModeLocked_;
	bool	antigravity_;
	float	cornerTouch_;
	float	startupScreenDelay_;
	Color	colors_[3], colorsWalk_[3];
	bool	useColorsWalk_;
	bool	proEnabled_;
	double	lastInteractionTime_;
};