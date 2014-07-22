//
//  Melon.h
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

// Types of melon.
typedef NS_ENUM(NSInteger, MelonType) {
    MelonTypeRegular,
    MelonTypeWinter,
    MelonTypeWinterFirstHit,
    MelonTypeWinterSecondHit,
    MelonTypeBomb
};

@interface Melon : CCNode

// For winter melons only: how many times it has been hit (attempt to clear).
@property (nonatomic, assign) int numOfHits;

// The melon's current row and column.
@property (nonatomic, assign) int row;
@property (nonatomic, assign) int col;

// Stores the column where the row of horizontal neighbors starts/ends.
@property (nonatomic, assign) int horizNeighborStartCol;
@property (nonatomic, assign) int horizNeighborEndCol;

// Stores the row where the column of vertical neighbors starts/ends.
@property (nonatomic, assign) int verticalNeighborStartRow;
@property (nonatomic, assign) int verticalNeighborEndRow;

// Type of melon.
@property (nonatomic, assign) MelonType type;

- (void)makeMelon:(int)melonType;
- (void)wobble;
- (void)stopWobble;
- (void)explode;

@end
