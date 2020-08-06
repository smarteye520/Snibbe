//
//  MPGradientController.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/5/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPGradientController.h"
#import "defs.h"
@implementation MPGradientController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    
    
    UIImage * imageGradient = [UIImage imageNamed: @"square_gradient.png"];
    
    imageViewGradient_ = [[UIImageView alloc] initWithImage: imageGradient];
    
    
    float portraitWidth = [[UIScreen mainScreen] bounds].size.width;
    float portraitHeight = [[UIScreen mainScreen] bounds].size.height;
    
    self.view.frame = CGRectMake(0, 0, portraitWidth, portraitHeight);
    imageViewGradient_.frame = self.view.frame;
            
    [self.view addSubview: imageViewGradient_];
    [self.view bringSubviewToFront: imageViewGradient_];
        
    imageViewGradient_.hidden = true;
    imageViewGradient_.alpha = 0.0f;


    bShowingGradient_ = false;
    
    
    
    
    [super viewDidLoad];
    
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}



//
// shart showing a "busy" animation on top of the main view
- (void) startShowingGradient: (float) fadeDuration
{
    
    
    if ( !bShowingGradient_ )
    {                        
        
        bShowingGradient_ = true;
        
        imageViewGradient_.alpha = 0.0f;
        imageViewGradient_.hidden = false;
        
        // fade it in
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration: fadeDuration];
        
        imageViewGradient_.alpha = 1.0f;
        
        [UIView commitAnimations];
        
        
        
        
        
    }
}


//
//
- (void) doStopShowingGradient
{

    
    //[imageViewGradientPending_ removeFromSuperview]; // don't release this one - we reuse it
    
    //imageViewGradientPending_.exclusiveTouch = false;
    
    imageViewGradient_.hidden = true;
    bShowingGradient_ = false;
    
    //[self sendViewToBack];
}


//
// stop showing a "busy" animation on top of the main view
- (void) stopShowingGradient: (float) fadeDuration
{
    
    
    //NSLog(@"stopping pending anim\n" );
    
    // fade it out
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: fadeDuration];
    
    imageViewGradient_.alpha = 0.0f;
    
    [UIView commitAnimations];        
    
    
    [self performSelector: @selector(doStopShowingGradient) withObject:nil afterDelay: fadeDuration];

    
}


//
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
}


@end
