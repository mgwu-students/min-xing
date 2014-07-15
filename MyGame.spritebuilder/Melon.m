//
//  Melon.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Melon.h"

@implementation Melon

static NSString *wintermelon = @"MyGameAssets/wintermelon_temp.png";
static NSString *wintermelonFirstHit = @"MyGameAssets/wintermelonFirstHit_temp.png";
static NSString *wintermelonSecondHit = @"MyGameAssets/wintermelonSecondHit_temp.png";

- (instancetype)initMelon
{
    self = [super initWithImageNamed:@"MyGameAssets/melon_temp.png"];
    
    if (self) {
        self.isWinterMelon = NO;
    }

    return self;
}

- (instancetype)initWinterMelonWithImageString:(NSString*)imgString
{
    self = [super initWithImageNamed:imgString];
    
    if (self) {
        self.isWinterMelon = YES;
        self.numOfHits = 0;
    }
    
    return self;
}

- (instancetype)initWinterMelon
{
    return [self initWinterMelonWithImageString:wintermelon];
}

- (instancetype)initWinterMelonFirstHit
{
    return [self initWinterMelonWithImageString:wintermelonFirstHit];
}

- (instancetype)initWinterMelonSecondHit
{
    return [self initWinterMelonWithImageString:wintermelonSecondHit];
}

@end
