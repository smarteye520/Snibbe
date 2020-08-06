/*
 *  Parameters.h
 *  Motion Phone
 *
 *  Created by Scott Snibbe on 5/3/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#pragma once

#include "defs.h"

class MShape;

// iPad defaults
#define DEFAULT_BRUSH           0
#define DEFAULT_ORIENT          true
#define DEFAULT_FILL            true
#define DEFAULT_WIDTH           40.0f
#define DEFAULT_ALPHA           1.0f
#define DEFAULT_MAX_BRUSHES     1000

#define DEFAULT_WIDTH_IPHONE                20.0f

#define DEFAULT_WIDTH_IPHONE_RETINA         40.0f

#define STARTUPSCREEN_DELAY 2.0f


class Parameters {
public:
	Parameters();
	~Parameters();
    
    bool saveIfDirty();
	bool save();
	bool load();
    
	bool saveToArchive(NSKeyedArchiver *archiver);
	bool loadFromArchive(NSKeyedUnarchiver *unarchiver);
	
    void loadSettingsBundleParams();
    
	void setDefaults(bool update=false); // whether to update app
	
    // settings for this session
	NSString*	splashString() { return splashString_; }
		
	float	getStartupScreenDelay() { return startupScreenDelay_; }

	bool	galleryMode() { return galleryMode_; }
	void	setGalleryMode(bool m) { galleryMode_ = m; }
	
	bool	galleryModeLocked() { return galleryModeLocked_; }
	void	setGalleryModeLocked(bool m) { galleryMode_ = galleryModeLocked_ = m; }
    
    int		maxBrushes()	{ return maxBrushes_; }
	void	setMaxBrushes(int mb) { maxBrushes_ = mb; }
    
    MotionPhoneTool	tool() { return tool_; }
	void            setTool( MotionPhoneTool t);
    
    void       setFBCredentials( NSString * accessToken, NSDate * expiration );
    NSString * getFBAccessToken();
    NSDate *   getFBExpirationDate();
    
    // keeping for backwards compat
    
    void          setBGColorIndex(int i);    
    void          setFGColorIndex(int i);     
    
    
    
    void          setFGColor(const MColor &c);
    void          setBGColor(const MColor &c);
        
    void          getFGColor(MColor &c) { c[0] = fgColor_[0]; c[1] = fgColor_[1]; c[2] = fgColor_[2]; c[3] = fgColor_[3];  }
    void          getBGColor(MColor &c) { c[0] = bgColor_[0]; c[1] = bgColor_[1]; c[2] = bgColor_[2]; c[3] = bgColor_[3];  }
    
    
    
    // settings saved out between sessions
    MShape *brushShape()     { return brushShape_; }
    void    setBrushShape( MShape * brushShape )    { brushShape_ = brushShape; }
    void    setBrushShape( ShapeID brushShapeID );
    
    bool	brushOrient()	{ return brushOrient_; }
	void	setBrushOrient(bool o);

    bool	brushFill()	{ return brushFill_; }
	void	setBrushFill(bool f);

    float	brushWidth() { return brushWidth_; }
	void	setBrushWidth(float bw);
    
//    float	brushAlpha() { return brushAlpha_; }
//	void	setBrushAlpha(float ba) { brushAlpha_ = ba; }
	
    bool    toolbarShown() { return toolbarShown_; }
    void    setToolbarShown( bool bShown );
    
    bool    fpsShown() { return fpsShown_; }
    void    setFPSShown( bool bShown ) { fpsShown_ = bShown; }
    
    double	minFrameTime() { return minFrameTime_; }
	void	setMinFrameTime(double t);
	
    bool    atMaxFrameRate() { return minFrameTime_ <= (MIN_FRAME_TIME_MIN + .001f); }
    bool    allowMultipleSamplesPerFrameAtCurrentFramerate() { return minFrameTime_ > FRAME_TIME_ABOVE_WHICH_ALLOW_MULTIPLE_STROKES_PER_FRAME; }
    
    int	    frameDir() { return frameDir_; }
	void	setFrameDir(int dir );
 
    bool    fadeStrokes() { return fadeStrokes_; }                             
    bool    drawingHidesUI() { return drawingHidesUI_; }
    bool    constantOutlineWidth() { return constantOutlineWidth_; }
    
    // utility methods
    //UIImage*    getToolImage(int i, bool small=false);
    
    // query a random color from the original palette of the MotionPhone iOS prototype
    MColor * randomPaletteColor();
    
private:
	NSString	*splashString_;
	int         maxBrushes_;
	bool        brushOrient_, brushFill_, galleryMode_, galleryModeLocked_;
	float       brushWidth_/*, brushAlpha_*/;
	float       cornerTouch_, startupScreenDelay_;
    MShape *    brushShape_;
    bool        toolbarShown_;
    bool        fpsShown_;
    double      minFrameTime_;
    int         frameDir_;    
    bool        fadeStrokes_;
    bool        drawingHidesUI_;
    bool        constantOutlineWidth_;                      
    
    NSString *  facebookAccessToken_;
    NSDate * facebookExpirationDate_;
                             
    MotionPhoneTool tool_;
    bool        sessionParamsDirty_; // the values that we write out to prefs between sessions
    
    MColor      *colorPalette_;
    
    // keeping for backwards compat
    MColor      *colors_;
    //int         bgColorIndex_, fgColorIndex_;
    
    MColor fgColor_;
    MColor bgColor_;
    
    //NSMutableArray     *filledIcons, *unfilledIcons, *filledOrientIcons, *unfilledOrientIcons;
    
    UIImage *scaleImage(UIImage *image, CGSize newSize);
    void buildColorTable();
    void buildDefaultColorPalette( MColor ** colors );
};