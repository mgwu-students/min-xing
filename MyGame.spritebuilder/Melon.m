//
//  Melon.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Melon.h"

@implementation Melon

- (instancetype)initMelon
{
    self = [super initWithImageNamed:@"MyGameAssets/melon_temp.png"];
    
    if (self) {
        self.isActive = YES; // TESTING ONLY
        self.isObstacleMelon = NO;
        self.isExplosiveMelon = NO;
    }
    return self;
}

- (instancetype)initExplosiveMelon
{
    self = [super initWithImageNamed:@"MyGameAssets/bomb_temp.png"];
    
    if (self) {
        self.isExplosiveMelon = YES;
        self.isObstacleMelon = NO;
    }
    return self;
}

- (instancetype)initObstacleMelon
{
    self = [super initWithImageNamed:@"MyGameAssets/obstacle_temp.png"];
    
    if (self) {
        self.isObstacleMelon = YES;
        self.isExplosiveMelon = NO;
    }
    return self;
}

- (void)setIsActive:(BOOL)newState
{
    _isActive = newState;
    self.visible = _isActive;
    
}

@end
