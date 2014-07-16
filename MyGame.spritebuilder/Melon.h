//
//  Melon.h
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"


@interface Melon : CCSprite

// Whether this melon is a winter melon.
@property (nonatomic, assign) BOOL isWinterMelon;

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

- (id)initMelon;
- (id)initWinterMelonWithImageString:(NSString*)imgString;
- (id)initWinterMelon;
- (id)initWinterMelonFirstHit;
- (id)initWinterMelonSecondHit;

@end
