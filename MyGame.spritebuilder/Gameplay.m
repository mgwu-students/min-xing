//
//  Gameplay.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "Grid.h"

@implementation Gameplay {
    Grid *_grid;
    CCLabelTTF *_numLabel;
//    CCSprite *_winterMelonIcon;
//    CCSprite *_bombIcon;
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)didLoadFromCCB
{
    __weak Gameplay *weakSelf = self;
    _grid.updateLabel = ^(int label){
        if (weakSelf) {
            Gameplay *strongSelf = weakSelf;
            strongSelf->_numLabel.string = [NSString stringWithFormat:@"%d", label];
        }
    };
}

- (void)restart
{
     [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

@end
