//
//  SnibbeDevice.m
//  SnibbeLib
//
//  Created by Graham McDermott on 1/23/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import "SnibbeDevice.h"

#include <sys/types.h>
#include <sys/sysctl.h>

// cached values
static NSString * strPlatform = nil;
static NSString * strPlatformString = nil;
static int cachedRam = -1;

@implementation SnibbeDevice


///////////////////////////
// platform
///////////////////////////

+ (NSString *) platform
{
    
    if ( strPlatform )
    {
        // use the cached version if we can
        return strPlatform;
    }
    
	int mib[2];
    size_t len;
	
	mib[0] = CTL_HW;
	mib[1] = HW_MACHINE;
	sysctl(mib, 2, NULL, &len, NULL, 0);
    char *machine = (char *) malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);    
    strPlatform = [[NSString stringWithCString:machine encoding:NSASCIIStringEncoding] retain];
    free(machine);    
    
    return strPlatform;
}


///////////////////////////
// platformString
///////////////////////////

+ (NSString *) platformString
{
    
    if ( strPlatformString )
    {
        return strPlatformString;
    }    
    
    NSString *pVerbosePlatform = [self platformStringMatch];
	if (pVerbosePlatform)
	{
        strPlatformString = [pVerbosePlatform retain];
	}
    else
    {
        strPlatformString = [[self platform] retain];
    }
    
    return strPlatformString;
    	
}

///////////////////////////
// platformStringMatch
///////////////////////////
+ (NSString *) platformStringMatch
{
    
    NSString *platform = [self platform];
    

    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4 (Verizon)";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (Wifi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad-3G (Wifi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad-3G (4G)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad-3G (4G)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return nil;
}
    
    
   

 
 
///////////////////////////
// amountOfRAM
///////////////////////////
+ (int) amountOfRAM
{
    if ( cachedRam > 0 )
    {
        return cachedRam;
    }
    
    NSString *pPlatform = [self platform];
    if ([pPlatform isEqualToString:@"iPhone1,1"]) 
    {        
        cachedRam = 128;
    }
    else if ([pPlatform isEqualToString:@"iPhone1,2"]) 
    {         
        cachedRam = 128;
    }
    else if ([pPlatform isEqualToString:@"iPhone2,1"])
    {        
        cachedRam = 256;
    }
    else if ([pPlatform isEqualToString:@"iPhone3,1"])
    {
        cachedRam = 512;
    }
    else if ([pPlatform isEqualToString:@"iPhone3,2"])
    {
        cachedRam = 512;
    }
    else if ( [pPlatform isEqualToString:@"iPhone4,1"] )
    {
        cachedRam = 512;     
    }
    else if ([pPlatform isEqualToString:@"iPod1,1"])
    {
        cachedRam = 128;
    }
    else if ([pPlatform isEqualToString:@"iPod2,1"])
    {        
        cachedRam = 128;
    }
    else if ([pPlatform isEqualToString:@"iPod3,1"])
    {            
        cachedRam = 256;
    }
    else if ([pPlatform isEqualToString:@"iPod4,1"])
    {
        cachedRam = 256;
    }
    else if ([pPlatform isEqualToString:@"iPad1,1"])
    {
        cachedRam = 256;
    }
    else if ([pPlatform isEqualToString:@"iPad2,1"])
    {
        cachedRam = 512;
    }
    else if ([pPlatform isEqualToString:@"iPad2,2"]) 
    {            
        cachedRam = 512;
    }
    else if ([pPlatform isEqualToString:@"iPad2,3"])   
    {            
        cachedRam = 512;
    }
    else if ([pPlatform isEqualToString:@"iPad2,4"])
    {
        cachedRam = 512;
    }
    else if ([pPlatform isEqualToString:@"iPad3,1"])
    {
        cachedRam = 1024;
    }
    else if ([pPlatform isEqualToString:@"iPad3,2"])
    {
        cachedRam = 1024;
    }
    else if ([pPlatform isEqualToString:@"iPad3,3"])
    {
        cachedRam = 1024;
    }
    else if ([pPlatform isEqualToString:@"x86_64"])
    {
        cachedRam = 512;
    }
    else if ([pPlatform isEqualToString:@"i386"])
    {            
        cachedRam = 512;
    }
    else 
    {        
        cachedRam = 512;
    }
    
    return cachedRam;
}




@end
