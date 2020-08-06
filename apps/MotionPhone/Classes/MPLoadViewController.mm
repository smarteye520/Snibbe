//
//  MPLoadViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPLoadViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "defs.h"
#import "MPSaveLoad.h"
#import "SnibbeUtils.h"
#import "UIImage+SnibbeTransformable.h"
#import "UIImage+SnibbeMaskable.h"

#ifdef MOTION_PHONE_MOBILE
const float screenShotImageWidth = 296.0f;
const float screenShotImageWidthImageHeight = 296.0f;
#else
const float screenShotImageWidth = 213.0f;
#endif

const float dividerWidth = 12.0f;

// private interface
@interface MPLoadViewController()

- (int) getSavePage;
- (int) saveIndexForPage: (int) page;
- (void) setupScrolling;
- (void) testPageArrows;
- (void) updatePageArrows;
- (void) updateActionButtonVisibility;

@end



@implementation MPLoadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//
//
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];    
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
    
    
    if ( IS_IPAD )
    {
        viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS;
    }
    
    scrollView_ = nil;
    scrollViewDummy_ = nil;
    iLastPage_ = -1;
    
    imageViewRight_.alpha = imageViewLeft_.alpha = 0.0f;
    
    buttonDelete_.alpha = 0.0f;
    buttonLoad_.alpha = 0.0f;
    
    [self updateActionButtonVisibility];
    
    [self setupScrolling];
    [self testPageArrows];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];                
    [self updateViewBackground: viewMainBG_];
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
	return NO;
}

//
//
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
 
    [scrollView_ setContentOffset: scrollView.contentOffset];
            
    [self testPageArrows];    
}

#pragma mark IBAction methods

//
//
- (IBAction) onLoadButton: (id) sender
{    
    
    int iSaveIndex = [self getSavePage];
    int iNumSaves = [[MPSaveLoad getSL] numSaves];
    iSaveIndex = [self saveIndexForPage: iSaveIndex];
    
    SSLog( @"load requested: %d of %d saves\n", iSaveIndex, iNumSaves );
    
    if ( iSaveIndex >= 0 && iSaveIndex < iNumSaves )
    {    
        [[MPSaveLoad getSL] loadSaveAtIndex: iSaveIndex];
    }
    
}

//
//
- (IBAction) onDeleteButton: (id) sender
{
  
    
    int iSaveIndex = [self getSavePage];
    int iNumSaves = [[MPSaveLoad getSL] numSaves];
    iSaveIndex = [self saveIndexForPage: iSaveIndex];
    
    SSLog( @"delete requested: %d of %d saves\n", iSaveIndex, iNumSaves );
    
    if ( iSaveIndex >= 0 && iSaveIndex < iNumSaves )
    {    
        [[MPSaveLoad getSL] deleteSaveAtIndex: iSaveIndex];
        [self setupScrolling];
        [self updatePageArrows];
        [self updateActionButtonVisibility];
        iLastPage_ = -1;
    }
        
}



//
//
- (int) getSavePage
{
    if ( [scrollViewDummy_.subviews count] == 0 )
    {
        return -1;
    }
    else if ( [scrollViewDummy_.subviews count] == 1 )
    {
        return 0;
    }
    else
    {    
    
        float offset = scrollViewDummy_.contentOffset.x + .1f;
        float pageSize = screenShotImageWidth + dividerWidth;
        
        int pageIndex = offset / pageSize;
        int iNumSaves = [[MPSaveLoad getSL] numSaves];
        
        pageIndex = MAX( pageIndex, 0 );
        pageIndex = MIN( pageIndex, iNumSaves - 1 );
        
        return pageIndex;                
        
    }        
    
}

//
// we display saves in reverse order, so flip it
- (int) saveIndexForPage: (int) page
{
    int iNumSaves = [[MPSaveLoad getSL] numSaves];
        
    if ( page >= 0 && page < iNumSaves )
    {    
        return iNumSaves - page - 1;            
    }
    
    return -1;
}



//
//
- (void) setupScrolling
{
    int iNumSaves = [[MPSaveLoad getSL] numSaves];
    
    //SSLog( @"setup scrolling: %d saves..\n", iNumSaves );
    
    if ( !scrollView_ )
    {
        scrollView_ = [[UIScrollView alloc] init];
        scrollViewDummy_ = [[UIScrollView alloc] init];
        
        [self.view addSubview: scrollView_];
        [self.view addSubview: scrollViewDummy_];
        
        scrollView_.showsHorizontalScrollIndicator = false;
        scrollView_.showsVerticalScrollIndicator = false;
        scrollViewDummy_.showsHorizontalScrollIndicator = false;
        scrollViewDummy_.showsVerticalScrollIndicator = false;
        
        [scrollView_ release];
        [scrollViewDummy_ release]; 
        
        if ( IS_IPAD )
        {
            scrollView_.frame = CGRectMake( 30.0f, 18.0f, self.view.frame.size.width - 12.0f - 36.0f, 284.0f );        
            scrollViewDummy_.frame = CGRectMake( 30.0f, 18.0f, 225.0f, 284.0f );        
        }
        else
        {
            const float pad = 12.0f;            
            scrollView_.frame = CGRectMake( pad, pad, self.view.frame.size.width - pad, self.view.frame.size.height - viewBlackBar_.frame.size.height - ( pad * 2 ) );        
            scrollViewDummy_.frame = scrollView_.frame;
            
    
        }
        
    }
    else
    {
        // start over
        for (UIView *view in scrollViewDummy_.subviews ) {
            [view removeFromSuperview];
        }
        
        for (UIView *view in scrollView_.subviews ) {
            [view removeFromSuperview];
        }
        
    }
    
    
    
    
    float curImagePos = 0.0f; //dividerWidth * 0.5f;
    
    for ( int i = iNumSaves-1; i >= 0; --i )
    {
        UIImage * saveImage = [[MPSaveLoad getSL] screenShotForSaveAtIndex:i];
        
        if ( saveImage )
        {
            
            
            UIImageView *iv = [[UIImageView alloc]initWithImage: saveImage];
            iv.frame = CGRectMake( curImagePos, 0.0f, screenShotImageWidth, scrollView_.frame.size.height );
            

#ifdef MOTION_PHONE_MOBILE
            
            


            
            UIView * imageParent = [[UIView alloc] initWithFrame: iv.frame];
            [imageParent addSubview: iv];
            
            float imageHeight = screenShotImageWidthImageHeight;
            float imageWidth = imageHeight * (saveImage.size.width / saveImage.size.height);
            
            iv.frame = CGRectMake(0.0f, 0.0f, imageWidth, imageHeight);
            iv.center = imageParent.center;            
            
            [scrollView_ addSubview: imageParent];
            [imageParent release];
#else
     
            [scrollView_ addSubview: iv];
#endif

            
            //SSLog( @"adding image: index %d, frame: %@\n", i, NSStringFromCGRect(iv.frame) );
            
            [scrollView_ addSubview: iv];
            [iv release];
            
            UIView * viewDummy = [[UIView alloc] init];
            viewDummy.frame = iv.frame;
            [scrollViewDummy_ addSubview: viewDummy];
            [viewDummy release];
            
            curImagePos += dividerWidth;
            curImagePos += screenShotImageWidth;
            
            
        }
        
        
    }
    
    [scrollView_ setContentSize: CGSizeMake( curImagePos + dividerWidth, scrollView_.frame.size.height )];
    [scrollViewDummy_ setContentSize: CGSizeMake( curImagePos + dividerWidth, scrollView_.frame.size.height )];
    
    scrollViewDummy_.clipsToBounds = true;
    scrollView_.clipsToBounds = true;
    
    scrollViewDummy_.pagingEnabled = true;
    scrollView_.userInteractionEnabled = false;
    
    
    scrollViewDummy_.delegate = self;
    
    [self.view bringSubviewToFront: scrollView_];
    [self.view bringSubviewToFront: scrollViewDummy_];
    [self.view bringSubviewToFront: buttonDelete_];
    [self.view bringSubviewToFront: buttonLoad_];
    [self.view bringSubviewToFront: imageViewLeft_];
    [self.view bringSubviewToFront: imageViewRight_];
}

//
//
- (void) testPageArrows
{
    int iCurPage = [self getSavePage];
    
    if ( iCurPage != iLastPage_ )
    {
        
        // update our arrows
        [self updatePageArrows];
        
    }
    
    iLastPage_ = iCurPage;

}


//
//
- (void) updatePageArrows
{

    
    const float arrowMaxAlpha = 0.75f;
    
    int iCurPage = [self getSavePage];
    int iNumSaves = [[MPSaveLoad getSL] numSaves];
    
    // SSLog( @"cur page: %d, num saves: %d\n", iCurPage, iNumSaves );
    
    [UIView beginAnimations: @"arrow update" context:nil];
    [UIView setAnimationDuration: 0.5f];
    [UIView setAnimationBeginsFromCurrentState:true];

    imageViewLeft_.alpha = iCurPage > 0 ? arrowMaxAlpha : 0.0f;
    imageViewRight_.alpha = iCurPage < iNumSaves-1 ? arrowMaxAlpha : 0.0f;
    
    [UIView commitAnimations];
}


//
//
- (void) updateActionButtonVisibility
{

    int iNumSaves = [[MPSaveLoad getSL] numSaves];
    
    [UIView beginAnimations: @"action button vis" context:nil];
    [UIView setAnimationDuration: 0.33f];
    
    buttonLoad_.alpha = iNumSaves > 0 ? 1.0f : 0.0f;    
    buttonDelete_.alpha = iNumSaves > 0 ? 1.0f : 0.0f;
    
    [UIView commitAnimations];
    
}


//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
}


// we want this whole view to suck up touches so they aren't passed down to the 
// eagl view

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
