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
@property (nonatomic, assign) int cellWidth;
@property (nonatomic, assign) int cellHeight;

- (BOOL)isNullAtRow:(int)row andCol:(int)col;
- (void)positionNode:(CCNode *)node atRow:(int)row andCol:(int)col;
- (void)addObject:(id)object toRow:(int)row andCol:(int)col;
- (id)getObjectAtRow:(int)row andCol:(int)col;
- (void)removeObjectAtX:(int)xPos Y:(int)yPos;
- (void)removeNeighborsAroundObjectAtRow:(int)row andCol:(int)col;

@end
