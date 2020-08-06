//
//  SnibbeUtilsiOS.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/23/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__SnibbeUtilsiOS__
#define __SnibbeLib__SnibbeUtilsiOS__

#import "UIKit/UIKit.h"
#import "SnibbeUtils.h"



#ifdef SS_LOG_ENABLED

#define SSLog(fmt, ...) NSLog(fmt, ## __VA_ARGS__)

#else

#define SSLog( fmt, ...) // silence

#endif


// device and version helpers

extern "C" bool iOSVersionAtLeast( NSString * version );
extern "C" bool isPad();

//sharing helpers
extern "C" bool twitterSupported();
extern "C" bool canTweet();

// view helpers
extern "C" void outputViewHierarchy( UIView * root );




// color utils
extern "C" float colorLuminance( CGColorRef colorToAnalyze );
extern "C" float colorBrightness( CGColorRef colorToAnalyze );

extern "C" float colorRed( CGColorRef colorToAnalyze );
extern "C" float colorGreen( CGColorRef colorToAnalyze );
extern "C" float colorBlue( CGColorRef colorToAnalyze );
extern "C" float colorAlpha( CGColorRef colorToAnalyze );

extern "C" float colorHue( CGColorRef colorToAnalyze );
extern "C" float colorSat( CGColorRef colorToAnalyze );


// some point ultility functions if we don't want to pull in all of cocos2d

inline float CGPointLen( const CGPoint p )
{
    return sqrtf (p.x * p.x + p.y * p.y);
}

inline CGPoint CGPointSub( const CGPoint p1, const CGPoint p2 )
{
    return CGPointMake( p1.x - p2.x, p1.y - p2.y );
}

inline CGPoint CGPointAdd( const CGPoint p1, const CGPoint p2 )
{
    return CGPointMake( p1.x + p2.x, p1.y + p2.y );
}

inline CGPoint CGPointMult( const CGPoint p1, const float s )
{
    return CGPointMake( p1.x * s, p1.y * s );
}

inline CGFloat ccpDistance(const CGPoint p1, const CGPoint p2)
{
	return CGPointLen( CGPointSub(p1, p2) );
}

inline CGPoint CGPointNorm( const CGPoint p )
{
    return CGPointMult( p, 1.0f/CGPointLen(p));
}

inline CGFloat CGPointDot(const CGPoint v1, const CGPoint v2)
{
	return v1.x*v2.x + v1.y*v2.y;
}

inline float CGPointAngle( CGPoint vec1, CGPoint vec2 )
{
    float dot = CGPointDot( CGPointNorm(vec1), CGPointNorm(vec2) );
	float angle = acosf( dot );
	if( fabs(angle) < FLT_EPSILON )
    {
        return 0.0f;
    }
    
	return angle;
}

inline CGPoint CGRectCenter( const CGRect r )
{
    return CGPointMake( r.origin.x + r.size.width * 0.5f, r.origin.y + r.size.height * .5f );
}


#endif /* defined(__SnibbeLib__SnibbeUtilsiOS__) */
