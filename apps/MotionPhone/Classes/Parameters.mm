/*
 *  Parameters.cpp
 *  Bubble Harp
 *
 *  Created by Scott Snibbe on 5/9/10.
 *  Copyright 2010 Scott Snibbe. All rights reserved.
 *
 */

#import "Parameters.h"
#import "mcanvas.h"
#import <QuartzCore/QuartzCore.h>
#import "SnibbeUtils.h"
#import "MShape.h"
#import "MShapeLibrary.h"

#define kPrefsExistKey @"prefsExist"
#define kBrushShapeIDKey @"brushShapeID"
#define kBrushOrientKey @"brushOrient"
#define kBrushFillKey @"brushFill"
#define kBrushWidthKey @"brushWidth"
#define kToolbarShownKey @"toolbarShown"
#define kFBAccessToken @"FBAccessTokenKey"
#define kFBExpirationDate @"FBExpirationDateKey"
#define kFadeStrokes @"mp_fade_strokes"
#define kDrawingHideUI @"mp_drawing_hides_ui"
#define kConstantOutlineWidth @"mp_constant_outline_width"

NSString * keyArchiveBgColor = @"mp_bgcolor";
NSString * keyArchiveFgColor = @"mp_fgcolor";
NSString * keyArchiveShapeID = @"mp_shapeID";
NSString * keyArchiveBrushOrient = @"mp_brushOrient";
NSString * keyArchiveBrushFill = @"mp_brushFill";
NSString * keyArchiveBrushWidth = @"mp_brushWidth";
NSString * keyArchiveMinFrameTime = @"mp_minFrameTime";
NSString * keyArchiveFrameDir = @"mp_frameDir";



//#define NBRUSHTYPES 5
//#define TOOLBAR_BRUSH_ICON_SIZE 26

/*
static NSString *kFilledIconNames[] = {
	@"line-filled-button.png", 
	@"square-filled-button.png",
	@"triangle-filled-button.png",
	@"circle-filled-button.png",
	@"chevron-filled-button.png"
};

static NSString *kUnfilledIconNames[] = {
	@"line-line-button.png", 
	@"square-line-button.png",
	@"triangle-line-button.png",
	@"circle-line-button.png",
	@"chevron-line-button.png"
};

static NSString *kFilledOrientIconNames[] = {
	@"line-filled-orient-button.png", 
	@"square-filled-orient-button.png",
	@"triangle-filled-orient-button.png",
	@"circle-filled-orient-button.png",
	@"chevron-filled-orient-button.png"
};

static NSString *kUnfilledOrientIconNames[] = {
	@"line-line-orient-button.png", 
	@"square-line-orient-button.png",
	@"triangle-line-orient-button.png",
	@"circle-line-orient-button.png",
	@"chevron-line-orient-button.png"
};
 */

Parameters::Parameters()
{	
    // load brush icons
    //filledIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
    //unfilledIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
    //filledOrientIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
    //unfilledOrientIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
    sessionParamsDirty_ = false;
    facebookAccessToken_ = nil;
    facebookExpirationDate_ = nil;
    
    fadeStrokes_ = DEFAULT_FADE_STROKES;
    drawingHidesUI_ = DEFAULT_DRAWING_HIDES_UI;
    constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;
        
    //[filledIcons retain];
    //[unfilledIcons retain];
    //[filledOrientIcons retain];
    //[unfilledOrientIcons retain];
    
    // load array of brush icons for all possible states
//    for (int i=0; i < NBRUSHTYPES; i++) {
//        [filledIcons addObject:[UIImage imageNamed:kFilledIconNames[i]]];	
//        [unfilledIcons addObject:[UIImage imageNamed:kUnfilledIconNames[i]]];	
//        [filledOrientIcons addObject:[UIImage imageNamed:kFilledOrientIconNames[i]]];	
//        [unfilledOrientIcons addObject:[UIImage imageNamed:kUnfilledOrientIconNames[i]]];
//    }
	
    buildColorTable();
    buildDefaultColorPalette( &colorPalette_ );    
	setDefaults();
}

//
//
Parameters::~Parameters()
{
    if ( colors_ )
    {
        delete [] colors_;
    }
    
    if ( colorPalette_ )
    {
        delete [] colorPalette_;
    }
}


//
//
bool Parameters::saveIfDirty() 
{
    if ( sessionParamsDirty_ ) 
    {        
        return save(); 
    }
    
    return false;
}

//
//
bool Parameters::save()
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// don't write out eraser state
	
    int iBrushShapeID = -1;
    if ( brushShape_ )
    {
        iBrushShapeID = brushShape_->getShapeID();
    }
    
    [prefs setBool:true forKey:kPrefsExistKey];  
    [prefs setInteger:iBrushShapeID forKey:kBrushShapeIDKey];
    [prefs setBool:brushOrient_ forKey:kBrushOrientKey];
    [prefs setBool:brushFill_ forKey:kBrushFillKey];
 	[prefs setFloat:brushWidth_ forKey:kBrushWidthKey];
	[prefs setBool:toolbarShown_ forKey:kToolbarShownKey];    
    
    [prefs setObject:facebookAccessToken_ forKey:kFBAccessToken];
    [prefs setObject:facebookExpirationDate_ forKey:kFBExpirationDate];
    [prefs setBool:fadeStrokes_ forKey:kFadeStrokes];
    [prefs setBool:drawingHidesUI_ forKey:kDrawingHideUI];
    [prefs setBool:constantOutlineWidth_ forKey:kConstantOutlineWidth];
    
	[prefs synchronize];
	
	//SSLog(@"saving params");
	
    sessionParamsDirty_ = false;
	return true;
}

bool Parameters::load()
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//	int i;
//	float f;
		
    //SSLog(@"loading params");
    
	if ([prefs boolForKey:kPrefsExistKey]) {
                      
        int iShapeID = [prefs integerForKey:kBrushShapeIDKey];
        
		setBrushShape( iShapeID );
        setBrushOrient([prefs boolForKey:kBrushOrientKey]);
        setBrushFill([prefs boolForKey:kBrushFillKey]);
        setBrushWidth([prefs floatForKey:kBrushWidthKey]);
        setToolbarShown( [prefs boolForKey: kToolbarShownKey] );

        if ( [prefs objectForKey: kFadeStrokes] )
        {
            fadeStrokes_ = [prefs boolForKey: kFadeStrokes];
        }
        
        if ( [prefs objectForKey: kDrawingHideUI] )            
        {        
            drawingHidesUI_ = [prefs boolForKey:kDrawingHideUI];
        }
        
        if ( [prefs objectForKey: kConstantOutlineWidth] )
        {
            constantOutlineWidth_ = [prefs boolForKey: kConstantOutlineWidth];    
        }
        
        
        
        
        
        id accessToken = [prefs objectForKey: kFBAccessToken];
        id expirationDate = [prefs objectForKey:kFBExpirationDate];
        
        setFBCredentials( accessToken, expirationDate );

        
	} else {
		// write out for first time
		save();
	}
    
    sessionParamsDirty_ = false;

	return true;
}

bool Parameters::saveToArchive(NSKeyedArchiver *archiver)
{	
    
    if ( archiver )
    {
    
        // background/forground color

        unsigned int bgAsInt = 0;
        MCOLOR_TO_INT32(bgColor_, bgAsInt);
        
        unsigned int fgAsInt = 0;
        MCOLOR_TO_INT32(fgColor_, fgAsInt);
        
        [archiver encodeInteger:bgAsInt forKey: keyArchiveBgColor];
        [archiver encodeInteger:fgAsInt forKey: keyArchiveFgColor];
        
        if ( brushShape_ )
        {
            [archiver encodeInteger:brushShape_->getShapeID() forKey:keyArchiveShapeID];
        }
        
        [archiver encodeBool:brushOrient_ forKey:keyArchiveBrushOrient];
        [archiver encodeBool:brushFill_ forKey:keyArchiveBrushFill];
        [archiver encodeFloat:brushWidth_ forKey:keyArchiveBrushWidth];
        [archiver encodeDouble:minFrameTime_ forKey:keyArchiveMinFrameTime];
        [archiver encodeInteger:frameDir_ forKey:keyArchiveFrameDir];      
        
        // skipping FB credentials here
    }
    
    
	
	return true;
}


bool 
Parameters::loadFromArchive(NSKeyedUnarchiver *unarchiver)
{
    
    if ( unarchiver )
    {
        
        setBrushOrient( [unarchiver decodeBoolForKey: keyArchiveBrushOrient] );
        setBrushFill( [unarchiver decodeBoolForKey: keyArchiveBrushFill] );
        setBrushWidth( [unarchiver decodeFloatForKey: keyArchiveBrushWidth] );
        setMinFrameTime( [unarchiver decodeDoubleForKey: keyArchiveMinFrameTime] );
        setFrameDir( [unarchiver decodeIntegerForKey: keyArchiveFrameDir] );
        
        int shapeID = [unarchiver decodeIntegerForKey: keyArchiveShapeID];
        if ( [[MShapeLibrary lib] shapeForID: shapeID] )
        {
            setBrushShape( shapeID );
        }
        
    
        MColor bgColor;
        MColor fgColor;

        unsigned int bgColAsInt = 0;
        unsigned int fgColAsInt = 0;
        
        bgColAsInt = [unarchiver decodeIntegerForKey: keyArchiveBgColor];
        fgColAsInt = [unarchiver decodeIntegerForKey: keyArchiveFgColor];
        
        MCOLOR_FROM_INT32( bgColor, bgColAsInt );
        MCOLOR_FROM_INT32( fgColor, fgColAsInt );
        
        setBGColor( bgColor );
        setFGColor( fgColor );        
        
        // skipping FB credentials here
        
    }
    
	return true;
}

//
//
void Parameters::loadSettingsBundleParams()
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];    
	if ([prefs boolForKey: kPrefsExistKey]) 
    {        
        
        if ( [prefs objectForKey: kFadeStrokes] )
        {
            fadeStrokes_ = [prefs boolForKey: kFadeStrokes];
        }
        
        if ( [prefs objectForKey: kDrawingHideUI] )            
        {        
            drawingHidesUI_ = [prefs boolForKey:kDrawingHideUI];
        }
        
        if ( [prefs objectForKey: kConstantOutlineWidth] )
        {
            constantOutlineWidth_ = [prefs boolForKey: kConstantOutlineWidth];    
        }
                
	} 
    
    
}

void Parameters::setDefaults(bool update) // flag whether to update app
{
	// if a high resolution iPhone
	float scale = 1;
	
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) { // only available on iOS 4 and up
		scale = [[UIScreen mainScreen] scale];
	}
	
    // transient parameters
    startupScreenDelay_ = 0.0f;
    galleryMode_ = galleryModeLocked_ = NO; // don't let this one get reset
    maxBrushes_ = DEFAULT_MAX_BRUSHES;
    tool_ = MotionPhoneTool_Brush;
    
    // saved parameters    
    brushShape_ = 0;
    setBrushShape( ID_SHAPE_DEFAULT );
    
    brushOrient_ = DEFAULT_ORIENT;
    brushFill_ = DEFAULT_FILL;
    brushWidth_ = DEFAULT_WIDTH;
    //brushAlpha_ = DEFAULT_ALPHA;
    
    toolbarShown_ = false;
    fpsShown_ = false;
    
    fadeStrokes_ = DEFAULT_FADE_STROKES;
    drawingHidesUI_ = DEFAULT_DRAWING_HIDES_UI;
    constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;
    
    minFrameTime_ = MIN_FRAME_TIME_MIN;
    frameDir_ = 1;
    
    // random colors
    //bgColorIndex_ = (int) (arc4random() % NCOLORS);
    //fgColorIndex_ = (int) (arc4random() % NCOLORS);
    
    // $$$ compare value and if too close choose new fg color
    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)	// iPad
	{
		splashString_ = [NSString stringWithFormat:@"Default-Portrait.png"];
		
		startupScreenDelay_ = STARTUPSCREEN_DELAY;
        
	}
	else // iPhone
	{
		splashString_ = [NSString stringWithFormat:@"Default.png"];

		// Specific settings for running on high res retina iPhone
        
		if (scale > 1) {

			startupScreenDelay_ = STARTUPSCREEN_DELAY;
            brushWidth_ = DEFAULT_WIDTH_IPHONE_RETINA;
            
		} else {
            // older low-res iPhone (360x480)
            
            startupScreenDelay_ = 0.0;	// no delay on older iPhones, because there's a built-in delay
            brushWidth_ = DEFAULT_WIDTH_IPHONE;
 
        }
	}
	
	if (!galleryModeLocked()) galleryMode_ = NO;
}



UIImage *
Parameters::scaleImage(UIImage *image, CGSize newSize)
{
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext(); 
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

//
//
void Parameters::setTool( MotionPhoneTool t)
{
    tool_ = t;  
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationToolModeChanged object: nil];
}
    
    
//
//
void Parameters::setFBCredentials( NSString * accessToken, NSDate * expiration )
{
    if ( accessToken && expiration )
    {
        if ( facebookAccessToken_ )
        {
            [facebookAccessToken_ release];
            facebookAccessToken_ = nil;
        }
        
        if ( facebookExpirationDate_ )
        {
            [facebookExpirationDate_ release];
            facebookExpirationDate_ = nil;
        }
        
        facebookAccessToken_ = [accessToken retain];
        facebookExpirationDate_ = [expiration retain];
    }
    
    sessionParamsDirty_ = true;
}

//
//
NSString * Parameters::getFBAccessToken()
{
    return facebookAccessToken_;
}

//
//
NSDate * Parameters::getFBExpirationDate()
{
    return facebookExpirationDate_;
}


//
// Keeping for backwards compat
void          
Parameters::setBGColorIndex(int i)
{

    if ( i < NCOLORS )
    {
        setBGColor( colors_[i] );
    }
    
}

//
// Keeping for backwards compat
void          
Parameters::setFGColorIndex(int i)
{

    if ( i < NCOLORS )
    {
        setFGColor( colors_[i] );
    }
    
}

//
//
void Parameters::setFGColor(const MColor &c) 
{
    fgColor_[0] = c[0]; 
    fgColor_[1] = c[1]; 
    fgColor_[2] = c[2]; 
    fgColor_[3] = c[3]; 
    sessionParamsDirty_ = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFGColorChanged object:nil];  
}

//
//
void Parameters::setBGColor(const MColor &c) 
{ 
    bgColor_[0] = c[0]; 
    bgColor_[1] = c[1]; 
    bgColor_[2] = c[2]; 
    bgColor_[3] = c[3];  
    sessionParamsDirty_ = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationBGColorChanged object:nil];  
}

//
//
void Parameters::setMinFrameTime (double t)
{ 
    minFrameTime_ = t;     
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationMinFrameTimeChanged object:nil];
}

//
//
void Parameters::setFrameDir(int dir )
{
    frameDir_ = dir;
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFrameDirChanged object:nil];
}


/*
UIImage*    
Parameters::getToolImage(int i, bool small)
{
    UIImage *brushImage;
    
    if (!brushOrient()) {   
        // not orienting
        if (brushFill()) {
            // not orienting and filled
            brushImage = (UIImage*) [filledIcons objectAtIndex:i];
        } else {
            // not orienting and unfilled
            brushImage = (UIImage*) [unfilledIcons objectAtIndex:i];   
        }
    } else { 
        // orienting
        if (brushFill()) {
            // orienting and filled
            brushImage = (UIImage*) [filledOrientIcons objectAtIndex:i];
        } else {
            // orienting and unfilled
            brushImage = (UIImage*) [unfilledOrientIcons objectAtIndex:i];
        }
    }
    
    if (small) {
        // shrink down to toolbar icon size
        brushImage = scaleImage(brushImage, CGSizeMake(TOOLBAR_BRUSH_ICON_SIZE, TOOLBAR_BRUSH_ICON_SIZE));
    }
    
    return brushImage;
}
 */

//
//
MColor * Parameters::randomPaletteColor()
{
    if ( colorPalette_ )
    {
        const int nColors = COLORWIDTH * COLORHEIGHT;
        int iIndex = rand() % nColors;
        return &(colorPalette_[iIndex]);
    }
    
    return 0;
}


//
//
void Parameters::setBrushShape( ShapeID brushShapeID )
{
    if ( brushShape_ )
    {
        // we don't own the shape.. the library does
        brushShape_ = 0;
    }
    
    MShape * pShape = [[MShapeLibrary lib] shapeForID: brushShapeID];
    if ( !pShape )
    {
        pShape = [[MShapeLibrary lib] shapeForID: ID_SHAPE_DEFAULT];
    }
    
    setBrushShape( pShape );
    sessionParamsDirty_ = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationBrushShapeChanged object:nil];

    
}

//
//
void Parameters::setBrushOrient(bool o) 
{
    brushOrient_ = o; 
    sessionParamsDirty_ = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationBrushOrientChanged object:nil];
}


//
//
void Parameters::setBrushFill(bool f)
{
    brushFill_ = f; 
    sessionParamsDirty_ = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationBrushFillChanged object:nil];
}

//
//
void Parameters::setBrushWidth(float bw) 
{
    if (bw < MIN_BRUSH_WIDTH)
    {        
        bw = MIN_BRUSH_WIDTH; 
    }
    else if ( bw > MAX_BRUSH_WIDTH )
    {
        bw = MAX_BRUSH_WIDTH;
    }
    
    brushWidth_ = bw; 
    sessionParamsDirty_ = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationBrushWidthChanged object:nil];
}

//
//
void Parameters::setToolbarShown( bool bShown )
{
    
    toolbarShown_ = bShown; 
    
    if ( bShown )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationToolbarShown object:nil];        
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationToolbarHidden object:nil];            
    }
        
}

static float
HLSValue(
		 float n1,
		 float n2,
		 float hue)
{
	if (hue > 360)
		hue -= 360;
	else if (hue < 0)
		hue += 360;
	
	if (hue < 60)
		return (n1 + (n2-n1) * hue/60);
	else if (hue < 180)
		return n2;
	else if (hue < 240)
		return (n1 + (n2 - n1) * (240 - hue)/60);
	else
		return n1;
}

static void
hls_to_rgb(
		   float   h,
		   float   l,
		   float   s,
		   float   *r,
		   float   *g,
		   float   *b)       // <<   h: 0-360, -1 for none, s: 0-1, v: 0-1
{
	float       m1, m2;
	
	if (l <= 0.5) {
		m2 = l * (1 + s);
	} else {
		m2 = l + s - l * s;
	}
	m1 = 2 * l - m2;
	
	if (s == 0) {
		*r = *g = *b = l;
	} else {
		*r = HLSValue(m1, m2, h+120);
		*g = HLSValue(m1, m2, h);
		*b = HLSValue(m1, m2, h-120);
	}
}


// This is being kept for backwards compatibility - primarily for
// the current performance mode code
void 
Parameters::buildColorTable()
{
    
#ifdef PERFORMANCE_MODE_COLORS
    
    int hi, li, i = 0;
	//float lums[4] = {0.7, 0.5, 0.3, 0.1};
	float lums[6] = { 0.9, 0.74, 0.58, 0.42, 0.26, 0.1 };
	float sats[1] = {.7};
    
    colors_ = new MColor [COLORWIDTH*COLORHEIGHT];
    
    
    for (li = 0; li < COLORHEIGHT * .75; li++) {
        int si = 0;
        
        for (hi = 0; hi < COLORWIDTH; hi++) {
            hls_to_rgb( ((float) hi) / COLORWIDTH * 360.0, lums[li], sats[si],
                       &colors_[i][0], &colors_[i][1], &colors_[i][2]);
            colors_[i][3] = 1.0; // alpha
            i++;
        }
        
	}
    
    // greys
    int nColors = COLORWIDTH*COLORHEIGHT;
    int iGrayStart = (COLORHEIGHT * .75) * COLORWIDTH;
    int iNumGrays = nColors - iGrayStart;
    
	for (i = iGrayStart; i < nColors; i++) {
		float grey = 1.0 - (float) (i-iGrayStart) / (iNumGrays-1);
		colors_[i][0] = colors_[i][1] = colors_[i][2] = grey;
        colors_[i][3] = 1.0; // alpha
	}

    
#else
    
    buildDefaultColorPalette( &colors_ );    
    
#endif
    
    

	
    
        

	
}

//
//
void Parameters::buildDefaultColorPalette( MColor ** colors )
{
    if ( colors )
    {
        int hi, li, si = 0, i = 0;
        //float lums[4] = {0.7, 0.5, 0.3, 0.1};
        float lums[8] = {0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1};
        float sats[2] = {0.8, 1};
        
        *colors = new MColor [COLORWIDTH*COLORHEIGHT];
        
        for (li = 0; li < COLORHEIGHT/2; li++) {
            for (si = 0; si < 2; si++) {
                for (hi = 0; hi < COLORWIDTH; hi++) {
                    hls_to_rgb( ((float) hi) / COLORWIDTH * 360.0, lums[li], sats[si],
                               &(*colors)[i][0], &(*colors)[i][1], &(*colors)[i][2]);
                    (*colors)[i][3] = 1.0; // alpha
                    i++;
                }
            }
        }
        
        // greys
        int nColors = COLORWIDTH*COLORHEIGHT;
        for (i = nColors-COLORWIDTH; i < nColors; i++) {
            float grey = 1.0 - (float) (i-(nColors-COLORWIDTH)) / COLORWIDTH;
            (*colors)[i][0] = (*colors)[i][1] = (*colors)[i][2] = grey;
            (*colors)[i][3] = 1.0; // alpha
        }
    }
    
}
