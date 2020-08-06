//
//  SKProduct+LocalizedPrice.m
//  Scoop
//
//  Created by Graham McDermott on 4/15/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "SKProduct+LocalizedPrice.h"


@implementation SKProduct (LocalizedPrice)

- (NSString *)localizedPrice
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:self.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:self.price];
    [numberFormatter release];
    return formattedString;
}

@end


