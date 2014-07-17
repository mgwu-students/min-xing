//
//  Melon.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Melon.h"
static NSString *regularMelon = @"MyGameAssets/melon_temp.png";
static NSString *winterMelon = @"MyGameAssets/wintermelon_temp.png";
static NSString *winterMelonFirstHit = @"MyGameAssets/wintermelonFirstHit_temp.png";
static NSString *winterMelonSecondHit = @"MyGameAssets/wintermelonSecondHit_temp.png";

@implementation Melon {
    CCSprite *_melonSprite;
}

- (void)changeMelon:(int)melonType
{
    switch (melonType)
    {
        case MelonTypeRegular:
            _melonSprite.spriteFrame = [CCSpriteFrame frameWithImageNamed:regularMelon];
            break;
        case MelonTypeWinter:
            _melonSprite.spriteFrame = [CCSpriteFrame frameWithImageNamed:winterMelon];
            break;
        case MelonTypeWinterFirstHit:
            _melonSprite.spriteFrame = [CCSpriteFrame frameWithImageNamed:winterMelonFirstHit];
            break;
        case MelonTypeWinterSecondHit:
            _melonSprite.spriteFrame = [CCSpriteFrame frameWithImageNamed:winterMelonSecondHit];
            break;
        default:
            break;
    }
}

// Overriding setter method.
- (void)setType:(MelonType)type
{
    _type = type;
    [self changeMelon:type];
}

// Makes the melon wobble.
- (void)wobble
{
    [self.animationManager runAnimationsForSequenceNamed:@"wobbleTimeline"];
}

// Stops melon from wobbling.
// Makes the melon wobble.
- (void)stopWobble
{
    [self.animationManager runAnimationsForSequenceNamed:@"defaultTimeline"];
}

@end