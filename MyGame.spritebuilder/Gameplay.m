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
}

- (id)init
{
    self = [super init];
    
    if (self) {
//        int (^makeSum)(float A,float B) = ^int(float A,float B) {
//            return (int)(A + B);
//        };
//        
//        int ans = makeSum(5,8);
//        
//        NSLog(@"answer is %d",ans);
//        
//        void (^printHello)() = ^{
//            NSLog(@"Hello");
//        };
//        
//        printHello();
    }
    
    return self;
}

- (void)didLoadFromCCB {
    _grid.updateLabel = ^(int label){
        _numLabel.string = [NSString stringWithFormat:@"%d", label];
    };
}

@end
