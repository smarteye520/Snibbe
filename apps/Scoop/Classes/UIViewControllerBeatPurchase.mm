//
//  UIViewControllerBeatPurchase.m
//  Scoop
//
//  Created by Graham McDermott on 4/4/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "UIViewControllerBeatPurchase.h"
#import "ScoopDefs.h"
#import "ScoopUtils.h"
#import "SnibbeStore.h"

@implementation UIViewControllerBeatPurchase

@synthesize imageViewBackground_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.title = @"Purchase";
        
    }
    return self;
}

- (void)dealloc
{
    [imageViewBackground_ release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [imageViewBackground_ release];
    imageViewBackground_ = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//
//
- (void)viewWillAppear:(BOOL)animated {
    
    CGSize size = CGSizeMake( 320, BEAT_SELECT_VIEW_PURCHASED_HEIGHT );
    self.contentSizeForViewInPopover = size;
    
    float pad = 12.0f;
    
    // position the explanation at the bottom
    
    float explainYPos = self.view.frame.size.height - (labelExplain_.frame.size.height + pad );        
    labelExplain_.frame = CGRectMake( labelExplain_.frame.origin.x, explainYPos, labelExplain_.frame.size.width, labelExplain_.frame.size.height );
    
    // position the buy button above the explanation
    float buttonYPos = labelExplain_.frame.origin.y - pad - buttonBuy_.frame.size.height;            
    buttonBuy_.frame = CGRectMake( buttonBuy_.frame.origin.x, buttonYPos, buttonBuy_.frame.size.width, buttonBuy_.frame.size.height );

    float extraiPhoneCopyY = 0.0f;
    if ( !gbIsIPad )
    {
        extraiPhoneCopyY = 70.0f;
    } 
    
    // position the copy above
    float copyYPos = buttonBuy_.frame.origin.y - pad - extraiPhoneCopyY - labelCopy_.frame.size.height;            
    labelCopy_.frame = CGRectMake( labelCopy_.frame.origin.x, copyYPos, labelCopy_.frame.size.width, labelCopy_.frame.size.height );
            
    buttonBuy_.enabled = true;
    
    [super viewWillAppear:animated];
    
}
 
//
//
- (void) setImageName: (NSString *) imageName
{
    UIImage * newImage = [UIImage imageNamed:imageName];
    imageViewBackground_.image = newImage;
}

//
//
- (void) setCopy: (NSString *) copy
{
    labelCopy_.text = copy;    
}

//
//
- (IBAction)onTouchedBuy:(id)sender 
{
    
    if ( [[SnibbeStore store] canMakePurchases] )
    {
        [[SnibbeStore store] purchaseProduct:kInAppPurchaseBeatSet1ProductId];
        //buttonBuy_.enabled = false; // only allow to be hit once per visit to this view (avoids spamming the purchase request queue)
    }
    else
    {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Unable to reach store" message:@"Sorry, we're unable to process purchases at the moment.  Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
        [av show];
        [av release];
    }
  

    
}
@end
