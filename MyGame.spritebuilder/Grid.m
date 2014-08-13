//
//  Grid.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Grid.h"
#import "Tile.h"

static const int GRID_ROWS = 5;
static const int GRID_COLUMNS = 5;
static const float MARGIN = 1.0;

@implementation Grid {
    NSMutableArray *_gridArray;
}

#pragma mark - Initialize

- (instancetype)init
{
    self = [super init];
    
    [self setupGrid];
    
    return self;
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
    
    self.cellWidth = self.contentSizeInPoints.width / GRID_COLUMNS;
    self.cellHeight = self.contentSizeInPoints.height / GRID_ROWS;
    
    float x = 0;
    float y = 0;

    // Initializes the grid and uses NSNull objects as placeholders.
    _gridArray = [NSMutableArray array];
    for (int i = 0; i < GRID_ROWS; i++)
    {
        _gridArray[i] = [NSMutableArray array];
        x = 0;
        
        for (int j = 0; j < GRID_COLUMNS; j++)
        {
            _gridArray[i][j] = [NSNull null];
            
            // Adds a tile picture onto the grid.
            Tile *tile = [[Tile alloc] initTile];
            tile.anchorPoint = ccp(0, 0);
            tile.position = ccp (x, y);
            
            // Scale the tile to fit the grid.
            tile.scale = self.cellHeight / (tile.contentSizeInPoints.height + MARGIN);
            
            [self addChild:tile];
            
            x += (self.cellWidth + MARGIN);
        }
        y += (self.cellHeight + MARGIN);
    }
}

#pragma mark - Check/Get Objects

// Checks if a specified position on the grid is [NSNull null].
- (BOOL)hasObjectAtRow:(int)row andCol:(int)col
{
    if (_gridArray[row][col] != [NSNull null])
    {
        return YES;
    }
    return NO;
}

// Checks if more than half of the board is filled with objects.
- (BOOL)boardIsMoreThanHalfFull
{
    int totalObjects = 0;
    
    for (int row = 0; row < GRID_ROWS; row++)
    {
        for (int col = 0; col <GRID_COLUMNS; col++)
        {
            if ([self hasObjectAtRow:row andCol:col])
            {
                totalObjects++;
            }
        }
    }
    
    if (totalObjects <= GRID_COLUMNS * GRID_ROWS)
    {
        return NO;
    }

    return YES;
}

// Returns the object stored at the specified position.
- (id)getObjectAtRow:(int)row andCol:(int)col
{
    return _gridArray[row][col];
}

#pragma mark - Add/Position Objects

// Adds an object to the board.
- (void)addObject:(id)object toRow:(int)row andCol:(int)col asChild:(BOOL)addChild
{
    _gridArray[row][col] = object;
    
    if (addChild)
    {
        [self addChild:object];
        
        [self positionNode:object atRow:row andCol:col];
    }
}

// Position an object at the specified position on the board.
- (void)positionNode:(CCNode *)node atRow:(int)row andCol:(int)col
{
    node.position = ccp (col * (self.cellWidth + MARGIN), row * (self.cellHeight + MARGIN));
    
    // See Melon class for overriding scale setter.
    node.scale = self.cellWidth;
    
    node.anchorPoint = ccp(0, 0);
}

#pragma mark - Remove Objects

// Removes reference to the object stored at the specified position.
- (void)removeObjectAtX:(int)xPos Y:(int)yPos fromParent:(BOOL)removeChild
{
    if (_gridArray[xPos][yPos] != [NSNull null])
    {
        if (removeChild)
        {
            [_gridArray[xPos][yPos] removeFromParent];
        }
    
        _gridArray[xPos][yPos] = [NSNull null];
    }
}

// Removes all objects on board.
- (void)clearBoardAndRemoveChildren:(BOOL)remove
{
    for (int i = 0; i < GRID_ROWS; i++)
    {
        for (int j = 0; j < GRID_COLUMNS; j++)
        {
            [self removeObjectAtX:i Y:j fromParent:remove];
        }
    }
}

// Remove the neighbor objects surounding the current object.
- (int)removeNeighborsAroundObjectAtRow:(int)row andCol:(int)col fromParent:(int)remove
{
    int totalRemoved = 0;
    
    for (int i = row - 1; i <= row + 1; i++)
    {
        for (int j = col - 1; j <= col + 1; j++)
        {
            // Boundary check.
            if (i >= 0 && i < GRID_ROWS && j >= 0 && j < GRID_COLUMNS)
            {
                [self removeObjectAtX:i Y:j fromParent:remove];
                
                totalRemoved++;
            }
        }
    }
    
    return totalRemoved;
}

#pragma mark - Debugging

- (void)printBoardState
{
    for (int row = 0; row < GRID_ROWS; row++)
    {
        CCLOG(@"\n");
        for (int col = 0 ; col < GRID_COLUMNS; col++)
        {
            CCLOG(@"%d ", _gridArray[row][col] != [NSNull null]);
        }
    }
}

@end