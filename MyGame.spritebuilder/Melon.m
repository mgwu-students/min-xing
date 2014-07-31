//
//  Melon.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Melon.h"

static NSString *regularMelon = @"MyGameAssets/watermelon_temp.png";
static NSString *winterMelon = @"MyGameAssets/wintermelon.png";
static NSString *winterMelonFirstHit = @"MyGameAssets/wintermelonFirstHit.png";
static NSString *winterMelonSecondHit = @"MyGameAssets/wintermelonSecondHit.png";
static NSString *bomb = @"MyGameAssets/bomb_temp.png";

@implementation Melon {
    CCSprite *_melonSprite;
}

- (void)makeMelon:(int)melonType
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
        case MelonTypeBomb:
            _melonSprite.spriteFrame = [CCSpriteFrame frameWithImageNamed:bomb];
            break;
        default:
            break;
    }
}

// Overriding setter.
- (void)setType:(MelonType)type
{
    _type = type;
    [self makeMelon:type];
}

// Overriding scale.
- (void)setScale:(float)tileSize
{
    _melonSprite.scale =  tileSize / _melonSprite.contentSizeInPoints.height;
}

// Makes the melon wobble.
- (void)wobble
{
    [self.animationManager runAnimationsForSequenceNamed:@"wobbleTimeline"];
}

// Removes the melon with particle effects.
- (void)explodeOrChangeFrame
{
    // Change frame for winter melons (unless it's the third hit).
    if (self.type == MelonTypeWinter)
    {
        self.type = MelonTypeWinterFirstHit;
    }
    else if (self.type == MelonTypeWinterFirstHit)
    {
        self.type = MelonTypeWinterSecondHit;
    }
    else if (self.type == MelonTypeWinterSecondHit)
    {
        self.type = MelonTypeWinterThirdHit;
    }
    else
    {
        
        // Remove melon with explosion effects.
        CCParticleSystem *explosion;
        
        // Different particle effects for melon and bomb.
        if (self.type == MelonTypeBomb)
        {
            explosion = (CCParticleSystem *)[CCBReader load:@"BombExplosion"];
        }
        else
        {
            explosion = (CCParticleSystem *)[CCBReader load:@"MelonExplosion"];
        }
        // Clean up particle effect.
        explosion.autoRemoveOnFinish = YES;
        
        // Place the particle effect at the melon's center.
        explosion.position = ccp(self.position.x + self.contentSizeInPoints.width / 2, self.position.y +
                                 self.contentSizeInPoints.height / 2);
        
        // Add the particle effect to the same node the melon is on and remove the destroyed melon.
        [self.parent addChild:explosion];
    }
}

@end