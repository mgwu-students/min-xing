//
//  Grid.h
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

typedef void(^updateMelonLabel)(int label);
//typedef void(^setIconVisible) (int icon);

typedef NS_ENUM(NSInteger, IconType) {
    IconTypeMelon,
    IconTypeBomb,
    IconTypeObstacle
};

@interface Grid : CCSprite

@property (nonatomic, copy) updateMelonLabel updateLabel;
//@property (nonatomic, copy) setIconVisible updateIcon;
@property (nonatomic, assign) int obstacle;
@property (nonatomic, assign) int bomb;

@end
