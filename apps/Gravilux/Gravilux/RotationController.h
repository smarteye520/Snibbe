//
//  RotationController.h
//  Gravilux
//
//  Created by Colin Roache on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InterfaceViewController.h"
@interface RotationController : UIViewController {
	@private
	InterfaceViewController		*interfaceVC;
	UIInterfaceOrientation			lastValidDeviceOrientation;
}

@end
