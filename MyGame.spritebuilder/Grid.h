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
- (BOOL)boardIsMoreThanHalfFull;
- (id)getObjectAtRow:(int)row andCol:(int)col;

- (void)positionNode:(CCNode *)node atRow:(int)row andCol:(int)col;
- (void)addObject:(id)object toRow:(int)row andCol:(int)col;

- (void)removeObjectAtX:(int)xPos Y:(int)yPos;
- (int)removeNeighborsAroundObjectAtRow:(int)row andCol:(int)col;
- (void)clearBoard;

@end
