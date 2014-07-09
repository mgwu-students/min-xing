//
//  Melon.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Melon.h"

@implementation Melon

- (instancetype)initMelons {
    
    self = [super initWithImageNamed:@"MyGameAssets/melon_temp.png"];
    
    if (self) {
        self.isActive = NO;
//        self.isLabeled = NO;
    }
    return self;
}

int(^updateMelonLabel)(int label) = ^int(int label) {
    return label;
};

- (void)setIsActive:(BOOL)newState
{
    _isActive = newState;
    self.visible = _isActive;

}

@end
