//
//  Melon.h
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

@interface Melon : CCSprite

@property (nonatomic, assign) BOOL isActive;

// Whether this melon is a cluster explosion melon.
@property (nonatomic, assign) BOOL isExplosiveMelon;

// Whether this melon is an obstacle.
@property (nonatomic, assign) BOOL isObstacleMelon;

// Stores the column where the row of horizontal neighbors starts.
@property (nonatomic, assign) int horizNeighborStartCol;

// Stores the row where the column of vertical neighbors starts.
@property (nonatomic, assign) int verticalNeighborStartRow;

// Stores the column where the row of horizontal neighbors ends.
@property (nonatomic, assign) int horizNeighborEndCol;

// Stores the row where the column of vertical neighbors ends
@property (nonatomic, assign) int verticalNeighborEndRow;

- (id)initMelon;
- (id)initExplosiveMelon;
- (id)initObstacleMelon;

@end
