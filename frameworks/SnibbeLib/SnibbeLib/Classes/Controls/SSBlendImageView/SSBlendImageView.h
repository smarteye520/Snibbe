//
//  SSBlendImageView.h
//  SnibbeLib
//
//  Created by Graham McDermott on 6/26/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSBlendImageView : UIView
{
    UIImage * image_;
    CGBlendMode blendMode_;
}

@property (nonatomic, assign) CGBlendMode blendMode_;
@property (nonatomic, retain) UIImage * image_;

@end
