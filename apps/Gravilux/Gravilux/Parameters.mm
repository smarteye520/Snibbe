/*
 *  Parameters.cpp
 *  gravilux
 *
 *  Created by Scott Snibbe on 2/27/10.
 *  Copyright 2010 Scott Snibbe. All rights reserved.
 *
 */

#include "Parameters.h"
#import "UIDeviceHardware.h"

#define KEY_STARSIZE @"starSize"
#define KEY_GRAVITY @"gravity"
#define KEY_COLS @"columns"
#define KEY_ROWS @"rows"
#define KEY_HEAT @"heat"
#define KEY_ANTIGRAVITY @"antigravity"
#define KEY_HEATCOLOR @"heatColor"
#define KEY_COLOR @"color"
#define KEY_EXISTS @"prefsExist1_3"

#define KEYSTRING(STR,N) [NSString stringWithFormat:@"%@%d", (STR), (N)]

Parameters::Parameters(Gravilux *app)
{
	app_ = app;
	
	UIDeviceHardware *h=[[UIDeviceHardware alloc] init];
	deviceString_ = [h platformString];  
	[deviceString_ retain];
	[h release];
	
	setDefaults();
	galleryMode_ = galleryModeLocked_ = NO; // don't let this one get reset
	useColorsWalk_ = false;
	
	setInteractionTime();
}

bool Parameters::savePreset(int num)
{
	
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	[prefs setFloat:gravity_ forKey:KEYSTRING(KEY_GRAVITY,num)];  
	[prefs setInteger:cols_ forKey:KEYSTRING(KEY_COLS,num)];  
	[prefs setInteger:rows_ forKey:KEYSTRING(KEY_ROWS,num)]; 
	//[prefs setBool:heat_ forKey:KEYSTRING(KEY_HEAT,num)];     // currently not used in program 
	[prefs setBool:antigravity_ forKey:KEYSTRING(KEY_ANTIGRAVITY,num)];
	[prefs setBool:heatColor_ forKey:KEYSTRING(KEY_HEATCOLOR,num)];
	[prefs setFloat:starSize_ forKey:KEYSTRING(KEY_STARSIZE,num)];
	
	for (int i=0; i<3; i++) {
		[prefs setFloat:colors_[i].r forKey:[NSString stringWithFormat:@"%@%d_i%d_red", KEY_COLOR, num, i]];
		[prefs setFloat:colors_[i].g forKey:[NSString stringWithFormat:@"%@%d_i%d_green", KEY_COLOR, num, i]];
		[prefs setFloat:colors_[i].b forKey:[NSString stringWithFormat:@"%@%d_i%d_blue", KEY_COLOR, num, i]];
	}
	
	[prefs synchronize];
	
	return true;
}

bool Parameters::loadPreset(int num, bool colorsOnly)
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	if (!colorsOnly) {
		float f;
		
		f = [prefs floatForKey:KEYSTRING(KEY_GRAVITY,num)];  
		if (f != 0) setGravity(f);
		
		int r = [prefs integerForKey:KEYSTRING(KEY_COLS,num)];  
		int c = [prefs integerForKey:KEYSTRING(KEY_ROWS,num)]; 
		if (r != 0 && c != 0) setSize(r,c);
		
		//[prefs setBool:heat_ forKey:KEYSTRING(KEY_HEAT,num)];     // currently not used in program 
		setAntigravity([prefs boolForKey:KEYSTRING(KEY_ANTIGRAVITY,num)]);
		setHeatColor([prefs boolForKey:KEYSTRING(KEY_HEATCOLOR,num)]);
		f = [prefs floatForKey:KEYSTRING(KEY_STARSIZE,num)];
		if (f != 0) setStarSize(f);
	}
	
	for (int i=0; i<3; i++) {
		colors_[i].r = [prefs floatForKey:[NSString stringWithFormat:@"%@%d_i%d_red", KEY_COLOR, num, i]];
		colors_[i].g = [prefs floatForKey:[NSString stringWithFormat:@"%@%d_i%d_green", KEY_COLOR, num, i]];
		colors_[i].b = [prefs floatForKey:[NSString stringWithFormat:@"%@%d_i%d_blue", KEY_COLOR, num, i]];
	}
	
	[prefs synchronize];
	
	return true;
}

bool Parameters::save()
{

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

	savePreset(0);	// 0 is one that's loaded on launch, but only colors
	
	[prefs synchronize];

	//dumpUserDefaults();
	
	return true;
}

bool Parameters::load()
{
	
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	bool prefsExist = [prefs boolForKey:KEY_EXISTS];
	
	if (prefsExist) {
		
		// load  presets 0 (default) - colors only
		// other settings are default at launch, and whatever they are at the moment
		// $$ - now load everything on launch for persistence: 12/2011
		loadPreset(0, false);

	} else {
		[prefs setBool:true forKey:KEY_EXISTS];
		
		saveDefaultPresets();
		save();	// save out defaults
	}
	
	return true;
}

bool Parameters::saveDefaultPresets()
{
	setDefaults(false);
	savePreset(0);
	
	// choose some nice defaults for presets 1, 2, 3, and 4 $$$$
	setAntigravity(false);
	setHeatColor(false);
	setGravity(4.0);
	setSize(120, 120);
	setStarSize(1);
	if ([deviceString_ isEqualToString:@"iPhone 1G"] ||
		[deviceString_ isEqualToString:@"iPhone 3G"] ||
		[deviceString_ isEqualToString:@"iPod Touch 1G"] ||
		[deviceString_ isEqualToString:@"iPod Touch 2G"]) {
		setSize(90, 90);
	}
	savePreset(1);
	
	setAntigravity(true);
	setHeatColor(true);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		setGravity(1.3);
	} else {
		setGravity(2.3);
	}
	setSize(91, 91);
	setStarSize(1.5);
	SETCOLOR(colors_[0], 0, 0.35, 0.8);
	SETCOLOR(colors_[1], 0.9375,0.9375,0.9375);
	SETCOLOR(colors_[2], 0.92,0.28,0.88);
	
	if ([deviceString_ isEqualToString:@"iPhone 1G"] ||
		[deviceString_ isEqualToString:@"iPhone 3G"] ||
		[deviceString_ isEqualToString:@"iPod Touch 1G"] ||
		[deviceString_ isEqualToString:@"iPod Touch 2G"]) {
		setGravity(3.3);
		setSize(90, 90);
	}
	
	savePreset(2);
	
	setAntigravity(false);
	setHeatColor(true);
	setGravity(6);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		setSize(106,106);
	} else {
		setSize(75,75);
	}
	setStarSize(1.85);
	SETCOLOR(colors_[0], 1,0,0);
	SETCOLOR(colors_[1], 0.2,1,1);
	SETCOLOR(colors_[2], 0.875,0,1);
	savePreset(3);

	setAntigravity(false);
	setHeatColor(false);
	setGravity(50);
	setSize(100,100);
	setStarSize(1);
	if ([deviceString_ isEqualToString:@"iPhone 1G"] ||
		[deviceString_ isEqualToString:@"iPhone 3G"] ||
		[deviceString_ isEqualToString:@"iPod Touch 1G"] ||
		[deviceString_ isEqualToString:@"iPod Touch 2G"]) {
		setSize(90, 90);
	}
	
	savePreset(4);
	
	// restore settings to defaults
	loadPreset(0,false);
	return true;
}

void Parameters::setColors(Color* colors)
{
	for (int c = 0; c < nColors(); c++) {
		colors_[c].r = colors[c].r;
		colors_[c].g = colors[c].g;
		colors_[c].b = colors[c].b;
	}
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"ParametersDidUpdateColorsNotification" object:[NSNotificationCenter defaultCenter]];
}

void Parameters::getColors(Color* colors)
{
	Color* colorSource = useColorsWalk_?colorsWalk_:colors_;
	for (int c = 0; c < nColors(); c++) {
		colors[c].r = colorSource[c].r;
		colors[c].g = colorSource[c].g;
		colors[c].b = colorSource[c].b;
	}
}

void Parameters::setColorsWalk(ColorSet colors)
{
	
	colorsWalk_[0].r = colors.slow.r;
	colorsWalk_[0].g = colors.slow.g;
	colorsWalk_[0].b = colors.slow.b;
	colorsWalk_[1].r = colors.medium.r;
	colorsWalk_[1].g = colors.medium.g;
	colorsWalk_[1].b = colors.medium.b;
	colorsWalk_[2].r = colors.fast.r;
	colorsWalk_[2].g = colors.fast.g;
	colorsWalk_[2].b = colors.fast.b;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ParametersDidUpdateColorsNotification" object:[NSNotificationCenter defaultCenter]];
}

void Parameters::setColorSource(bool fromColorWalk)
{
	useColorsWalk_ = fromColorWalk;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ParametersDidUpdateColorsNotification" object:[NSNotificationCenter defaultCenter]];
};

void Parameters::setDefaultColors()
{
	/*
	colors_[0].r = colors_[0].g = colors_[0].b = 0;
	colors_[1].r = colors_[1].g = colors_[1].b = 0.5;
	colors_[2].r = colors_[2].g = colors_[2].b = 1.0;
	 */
	
	colors_[0].r = 1;
	colors_[0].g = 0.19;
	colors_[0].b = 0;
	
	colors_[1].r = 1;
	colors_[1].g = 0.95;
	colors_[1].b = 0.2;

	colors_[2].r = 0;
	colors_[2].g = 0.1;
	colors_[2].b = 0.4;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateUIColor" object:[NSNotificationCenter defaultCenter]];
}

void Parameters::setDefaults(bool update) // flag whether to update app
{
	CGSize screenSize = [[[UIApplication sharedApplication] keyWindow] bounds].size;
	
	// if a high resolution iPhone
	// $$$$ also detect os 4 
	float scale = 1;
	
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) { // only available on iOS 4 and up
		scale = [[UIScreen mainScreen] scale];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		// The device is an iPad running iPhone 3.2 or later.
		settingsString_ = [NSString stringWithFormat:@"interface-iPad"];
		splashString_ = [NSString stringWithFormat:@"Default-Portrait.png"];
		// $$$$ add cases for other 3 orientations

		starSize_ = DEFAULT_STARSIZE_IPAD;
		minStarSize_ = MIN_STARSIZE_IPAD;
		gravity_ = DEFAULT_GRAVITY_IPAD;
		if(![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) { // iPad 1
			rows_ = DEFAULT_ROWS_IPAD;
			cols_ = DEFAULT_COLUMNS_IPAD;
		} else  {
			rows_ = DEFAULT_ROWS_IPAD2;
			cols_ = DEFAULT_COLUMNS_IPAD2;
		}
		maxRows_ = MAX_ROWS_IPAD;
		heat_ = heatColor_ = DEFAULT_HEAT_IPAD;
		heatScale_ = DEFAULT_HEATSCALE_IPAD;
		antigravity_ = DEFAULT_ANTIGRAVITY_IPAD;
		cornerTouch_ = DEFAULT_CORNER_TOUCH_IPAD;
		music_ = NO;
		startupScreenDelay_ = STARTUPSCREEN_DELAY;

	}
	else // iPhone
	{
		// The device is an iPhone or iPod touch.
		settingsString_ = [NSString stringWithFormat:@"interface-iPhone"];
		splashString_ = [NSString stringWithFormat:@"Default.png"];
		
		starSize_ = DEFAULT_STARSIZE;
		minStarSize_ = MIN_STARSIZE;
		gravity_ = DEFAULT_GRAVITY;
		rows_ = DEFAULT_ROWS;
		cols_ = DEFAULT_COLUMNS;
		heat_ = heatColor_ = DEFAULT_HEAT;
		heatScale_ = DEFAULT_HEATSCALE;
		antigravity_ = DEFAULT_ANTIGRAVITY;
		cornerTouch_ = DEFAULT_CORNER_TOUCH;
		music_ = NO;
		startupScreenDelay_ = 0.0;	// no delay on older iPhones, because there's a built-in delay
		maxRows_ = MAX_ROWS;
		
		// Specific settings for running on high res iPhone
		if (scale > 1) {	
			starSize_ = DEFAULT_STARSIZE_HIPHONES;
			minStarSize_ = MIN_STARSIZE_HIPHONES;
			gravity_ = DEFAULT_GRAVITY_HIPHONES;
			startupScreenDelay_ = STARTUPSCREEN_DELAY;
		}
		
		// Specific settings for older (slower) devices
		if ([deviceString_ isEqualToString:@"iPhone 1G"] ||
			[deviceString_ isEqualToString:@"iPhone 3G"] ||
			[deviceString_ isEqualToString:@"iPod Touch 1G"] ||
			[deviceString_ isEqualToString:@"iPod Touch 2G"]) {
			gravity_ = DEFAULT_GRAVITY_OLDPHONES;
			maxRows_ = MAX_ROWS_OLDPHONES;
		}
		
	}
	
	setDefaultColors();
	
	if (update) {
		setStarSize(starSize_);
		setGravity(gravity_);
		setSize(rows_, cols_);
		setHeat(heat_);
		setAntigravity(antigravity_);
	}
}
void Parameters::dumpUserDefaults()
{
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *bundleId = [bundleInfo objectForKey: @"CFBundleIdentifier"];
	
	NSUserDefaults *appUserDefaults = [[NSUserDefaults alloc] init];
	NSLog(@"Start dumping userDefaults for %@", bundleId);
	NSLog(@"userDefaults dump:\n %@", [appUserDefaults persistentDomainForName: bundleId]);
	NSLog(@"Finished dumping userDefaults for %@", bundleId);
	[appUserDefaults release];
}
