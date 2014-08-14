//
//  Grid.h
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

@interface Grid : CCSprite

@property (nonatomic, assign) int numCols;
@property (nonatomic, assign) int numRows;
@property (nonatomic, assign) float cellWidth;
@property (nonatomic, assign) float cellHeight;

- (BOOL)hasObjectAtRow:(int)row andCol:(int)col;
- (id)getObjectAtRow:(int)row andCol:(int)col;
- (BOOL)boardIsMoreThanHalfFull;
- (BOOL)boardIsFull;

- (void)positionNode:(CCNode *)node atRow:(int)row andCol:(int)col;
- (void)addObject:(id)object toRow:(int)row andCol:(int)col asChild:(BOOL)addChild;

- (void)removeObjectAtX:(int)xPos Y:(int)yPos fromParent:(BOOL)removeChild;
- (void)clearBoardAndRemoveChildren:(BOOL)remove;
- (int)removeNeighborsAroundObjectAtRow:(int)row andCol:(int)col fromParent:(int)remove;

- (void)printBoardState;

@end
