//
//  Melon.h
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

@interface Melon : CCSprite

// Whether this melon is visible on the board.
@property (nonatomic, assign) BOOL isActive;

// Whether this melon has a number label/ can possibly act as a bomb.
@property (nonatomic, assign) BOOL isLabeled;

// The number on the label.
@property (nonatomic, assign) NSInteger numLabel;

// Current column of the melon.
@property (nonatomic, assign) NSInteger colPos;

// Current row of the melon.
@property (nonatomic, assign) NSInteger rowPos;

// Stores the column where the row of horizontal neighbors starts.
@property (nonatomic, assign) NSInteger horizNeighborStartCol;

// Stores the row where the column of vertical neighbors starts.
@property (nonatomic, assign) NSInteger verticalNeighborStartRow;

// Stores the column where the row of horizontal neighbors ends.
@property (nonatomic, assign) NSInteger horizNeighborEndCol;

// Stores the row where the column of vertical neighbors ends
@property (nonatomic, assign) NSInteger verticalNeighborEndRow;

- (id)initMelons;

@end
