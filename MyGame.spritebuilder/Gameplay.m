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
  CCNode *_obstacleIcon;
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)didLoadFromCCB {
    _grid.updateLabel = ^(int label){
        _numLabel.string = [NSString stringWithFormat:@"%d", label];
    };
    
}

@end
