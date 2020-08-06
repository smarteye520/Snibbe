//
//  SnibbeUtilsiOS.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 8/23/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeUtilsiOS.h"


#import <Twitter/TWTweetComposeViewController.h>

#pragma mark sharing helpers



//
// pass in version string, e.g. @"4.3.5"
bool iOSVersionAtLeast( NSString * version )
{
    NSString *curSysVer = [[UIDevice currentDevice] systemVersion];
    return [curSysVer compare:version options:NSNumericSearch] != NSOrderedAscending;
}


//
//
bool isPad()
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30200
    
    UIDevice* device = [UIDevice currentDevice];
    return ( device.userInterfaceIdiom == UIUserInterfaceIdiomPad );

#endif
    
    return false;
    
}

//
//
bool twitterSupported()
{
    return  NSClassFromString( @"TWRequest" ) != nil;
}

//
//
bool canTweet()
{
    return ( twitterSupported() && [NSClassFromString(@"TWTweetComposeViewController") canSendTweet] );
}


#pragma mark view helpers

//
//
void outputViewHierarchyRec( UIView *cur, NSString *prefix )
{
    if ( cur )
    {
        // printf avoids the NSLog prefix
        printf( "%s%s\n", [prefix UTF8String], [[cur description] UTF8String] );
        prefix = [NSString stringWithFormat: @"%@  ", prefix]; // add space to previx
        
        NSArray * subs = [cur subviews];
        for ( UIView * v in subs )
        {
            outputViewHierarchyRec( v, prefix );
        }
    }
}


void outputViewHierarchy( UIView * root )
{
    printf( "\nView hierarchy\n------------------------\n" );
    outputViewHierarchyRec( root, @"" );
    printf( "\n------------------------\n\n" );
}





#pragma mark color utils

//
// returns the maximum of R,G,B
float colorLuminance( CGColorRef colorToAnalyze )
{
    const CGFloat* components = CGColorGetComponents(colorToAnalyze);
    
    float maxComponent = MAX( components[0], components[1] );
    maxComponent = MAX( maxComponent, components[2] );
    
    
    return maxComponent;
}

//
// returns average of R,G,B
float colorBrightness( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	return (components[0] + components[1] + components[2]) / 3.;
}

//
//
float colorRed( CGColorRef colorToAnalyze )
{
    const CGFloat* components = CGColorGetComponents(colorToAnalyze);
    return components[0];
}

//
//
float colorGreen( CGColorRef colorToAnalyze )
{
    const CGFloat* components = CGColorGetComponents(colorToAnalyze);
    return components[1];
}

//
//
float colorBlue( CGColorRef colorToAnalyze )
{
    const CGFloat* components = CGColorGetComponents(colorToAnalyze);
    return components[2];
}

//
//
float colorAlpha( CGColorRef colorToAnalyze )
{
    const CGFloat* components = CGColorGetComponents(colorToAnalyze);
    return components[3];
}


//
//
float colorHue( CGColorRef colorToAnalyze )
{
    const CGFloat* components = CGColorGetComponents(colorToAnalyze);
    float r = components[0];
    float g = components[1];
    float b = components[2];
    
    // calculation from http://en.wikipedia.org/wiki/Hue
    float rads = atan2f( 2*r - g - b, sqrtf(3.0) * (g-b) );
    if ( rads < 0 )
    {
        rads += M_PI * 2;
    }
    
    return rads;
}


//
//
float colorSat( CGColorRef colorToAnalyze )
{
    const CGFloat* components = CGColorGetComponents(colorToAnalyze);
    float r = components[0];
    float g = components[1];
    float b = components[2];
    
    float maxVal = MAX( r, g );
    maxVal = MAX( maxVal, b );
    
    float minVal = MIN( r, g );
    minVal = MIN( minVal, b );
    
    float delta = maxVal - minVal;
    
    delta = MAX( delta, 0.0f );
    delta = MIN( delta, 1.0f );
    
    if ( maxVal > .0001 )
    {
        return delta / maxVal;
    }
    
    return 0.0f;
    
}



