//
//  Melon.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Melon.h"

@implementation Melon

static NSString *regularMelon = @"MyGameAssets/melon_temp.png";
static NSString *winterMelon = @"MyGameAssets/wintermelon_temp.png";
static NSString *winterMelonFirstHit = @"MyGameAssets/wintermelonFirstHit_temp.png";
static NSString *winterMelonSecondHit = @"MyGameAssets/wintermelonSecondHit_temp.png";

// Initializes a regular green melon.
- (instancetype)initMelon
{
    self = [super initWithImageNamed:regularMelon];
    
    if (self) {
        self.isWinterMelon = NO;
    }

    return self;
}

// Initializes a blue winter melon.
- (instancetype)initWinterMelonWithImageString:(NSString*)imgString
{
    self = [super initWithImageNamed:imgString];
    
    if (self) {
        self.isWinterMelon = YES;
        self.numOfHits = 0;
    }
    
    return self;
}

// Different images for different states of a winter melon.
- (instancetype)initWinterMelon
{
    return [self initWinterMelonWithImageString:winterMelon];
}

- (instancetype)initWinterMelonFirstHit
{
    return [self initWinterMelonWithImageString:winterMelonFirstHit];
}

- (instancetype)initWinterMelonSecondHit
{
    return [self initWinterMelonWithImageString:winterMelonSecondHit];
}

@end
