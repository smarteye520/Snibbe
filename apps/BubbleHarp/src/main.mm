

#import <UIKit/UIKit.h>
#import "BubbleHarpAppDelegate.h"
#include "BubbleHarp.h"
#include "Parameters.h"
#include "defs.h"

BubbleHarp *gBubbleHarp=nil;
Parameters *gParams=nil;

int main(int argc, char *argv[]) {
	
    @autoreleasepool {
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([BubbleHarpAppDelegate class]));
	}
        
}

