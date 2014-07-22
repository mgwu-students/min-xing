//
//  Grid.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Grid.h"

static const int GRID_ROWS = 5;
static const int GRID_COLUMNS = 5;

@implementation Grid {
    NSMutableArray *_gridArray;
}

- (void)onEnter
{
    [super onEnter];
    
    [self setupGrid];
}

// Sets up a 2D grid.
- (void)setupGrid
{
    self.numCols = GRID_COLUMNS;
    self.numRows = GRID_ROWS;
    
    self.cellWidth = self.contentSize.width / GRID_COLUMNS;
    self.cellHeight = self.contentSize.height / GRID_ROWS;
    
    // Initializes the grid and uses NSNull objects as placeholders.
    _gridArray = [NSMutableArray array];
    for (int i = 0; i < GRID_ROWS; i++) {
        _gridArray[i] = [NSMutableArray array];
        
        for (int j = 0; j < GRID_COLUMNS; j++) {
            _gridArray[i][j] = [NSNull null];
        }
    }
}

// Checks if a specified position on the grid is [NSNull null].
- (BOOL)isNullAtRow:(int)row andCol:(int)col
{
    if (_gridArray[row][col] != [NSNull null]) {
        return NO;
    }
    return YES;
}

// Position an object at the specified position on the board.
- (void)positionNode:(CCNode *)node atRow:(int)row andCol:(int)col
{
    node.anchorPoint = ccp(0, 0);
    node.position = ccp (col * _cellWidth, row * _cellHeight);
}

// Adds an object to the board.
- (void)addObject:(id)object toRow:(int)row andCol:(int)col
{
    _gridArray[row][col] = object;
}

// Returns the object stored at the specified position.
- (id)getObjectAtRow:(int)row andCol:(int)col
{
    return _gridArray[row][col];
}

// Removes reference to the object stored at the specified position.
- (void)removeObjectAtX:(int)xPos Y:(int)yPos
{
    if (_gridArray[xPos][yPos] == [NSNull null]) {
        return;
    }
    [_gridArray[xPos][yPos] removeFromParent];
    _gridArray[xPos][yPos] = [NSNull null];
}

// Remove the neighbor objects surounding the current object.
- (void)removeNeighborsAroundObjectAtRow:(int)row andCol:(int)col
{
    for (int i = row - 1; i <= row + 1; i++) {
        for (int j = col - 1; j <= col + 1; j++) {
            // Boundary check.
            if (i < 0 || i >= GRID_ROWS || j < 0 || j >= GRID_COLUMNS) {
                break;
            }
            // Remove neighbor object.
            if (_gridArray[i][j] != [NSNull null]) {
                [self removeObjectAtX:i Y:j];
            }
        }
    }
}

@end