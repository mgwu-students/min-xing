//
//  GameState.m
//  MyGame
//
//  Created by Min Xing on 8/3/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameState.h"

@implementation GameState

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        NSNumber *highScore = [[NSUserDefaults standardUserDefaults] objectForKey:
                               @"highScore"];
        self.highScore = [highScore integerValue];
    }
}

@end
