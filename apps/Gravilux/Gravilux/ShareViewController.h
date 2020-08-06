//
//  ShareViewController.h
//  Gravilux
//
//  Created by Colin Roache on 11/3/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "SHKSharer.h"

#define WATERMARK_SCREENSHOT	1
#define WATERMARK_IMAGE			@"symbol.png"
#define WATERMARK_ALPHA			0.8f
#define WATERMARK_OFFSET_X		19
#define WATERMARK_OFFSET_Y		24

//@interface ShareViewController : UIViewController<SHKSharerDelegate> {
@interface ShareViewController : UIViewController {
	IBOutlet UIButton *facebookButton;
	IBOutlet UIButton *twitterButton;
	IBOutlet UIButton *emailButton;
	IBOutlet UIButton *photosButton;
	
@private
	GLuint		*imageBuffer_;
	UIImage		*renderedImage_;
	float		contentScaleFactor;
}
- (IBAction)share:(id)sender;

@end
