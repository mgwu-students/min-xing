//
//  GameState.h
//  MyGame
//
//  Created by Min Xing on 8/3/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameState : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign) int highScore;
@property (nonatomic, assign) BOOL tutorialCompleted;

@end
