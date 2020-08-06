
//  main.m
//  Gravilux
//
//  Created by Colin Roache on 9/7/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GraviluxAppDelegate.h"
#include "Gravilux.h"
Gravilux	*gGravilux = NULL;
int main(int argc, char *argv[])
{
	@autoreleasepool {
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([GraviluxAppDelegate class]));
	}
}
