//
//  VisualizerTableViewController.h
//  Gravilux
//
//  Created by Colin Roache on 10/31/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VisualizerTableViewController : UITableViewController {
	@private
	UITableViewCell*	forceEmitterCell;
	UIImage*			trackMinImage;
	UIImage*			trackMaxImage;
	NSArray*			thumbImages;
}
- (IBAction)adjustEmitter:(id)sender;
@end
