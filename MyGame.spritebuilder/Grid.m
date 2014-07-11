//
//  Grid.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Grid.h"
#import "Melon.h"

// Grid size.
static const int GRID_ROWS = 5;
static const int GRID_COLUMNS = 5;
// Melon types.
static const int REGULAR_MELON = 0;
static const int OBSTACLE_MELON = 1;
static const int EXPLOSIVE_MELON = 2;
// Chance to get an obstacle melon.
static const int INITIAL_OBSTACLE_CHANCE= 0.12;
static const int MIDGAME_OBSTACLE_CHANCE = 0.24;

@implementation Grid {
    NSMutableArray *_gridArray;
    float _cellWidth;
    float _cellHeight;
    int _melonLabel;
    float _chanceToGetObstacle;
}

- (void)onEnter
{
    [super onEnter];
    
//    [self setupGrid];
    
    self.userInteractionEnabled = YES;
    
    // Set random starting number label for first melon.
    _melonLabel = arc4random_uniform(GRID_COLUMNS) + 1; // Random number between 1 and GRID_COLUMNS.
    self.updateLabel(_melonLabel);
    
    _chanceToGetObstacle = INITIAL_OBSTACLE_CHANCE;
    
    // Divide grid size by total cols/rows to figure out the width and height of each cell.
    _cellWidth = self.contentSize.width / GRID_COLUMNS;
    _cellHeight = self.contentSize.height / GRID_ROWS;
}

//- (void)setupGrid
//{
//    // Divide grid size by total cols/rows to figure out the width and height of each cell.
//    _cellWidth = self.contentSize.width / GRID_COLUMNS;
//    _cellHeight = self.contentSize.height / GRID_ROWS;
//    
//    float x = 0;
//    float y = 0;
//    
//    // Initialize the array as a blank NSMutableArray.
//    _gridArray = [NSMutableArray array];
//    
//    // Initialize melons.
//    for (int i = 0; i < GRID_ROWS; i++) {
//        _gridArray[i] = [NSMutableArray array];
//        x = 0;
//        
//        for (int j = 0; j < GRID_COLUMNS; j++) {
//            Melon *melon = [[Melon alloc] initMelon];
//            melon.anchorPoint = ccp(0, 0);
//            melon.position = ccp (x, y);
//            [self addChild: melon];
//            
//            _gridArray[i][j] = melon;
//            
//            x += _cellWidth;
//        }
//        y += _cellHeight;
//    }
//}

// Make a melon of type melonType at the specified position in the array.
- (Melon *)makeMelon:(int)melonType atRow:(int)row andCol:(int)col
{
    Melon *melon;
    switch (melonType) {
        case REGULAR_MELON:
            melon = [[Melon alloc] initMelon];
            break;
        case OBSTACLE_MELON:
            melon = [[Melon alloc] initObstacleMelon];
            break;
        case EXPLOSIVE_MELON:
            melon = [[Melon alloc] initExplosiveMelon];
            break;
        default:
            break;
    }
    melon.anchorPoint = ccp(0, 0);
    melon.position = ccp (row * _cellWidth, col * _cellHeight);
    [self addChild: melon];
    _gridArray[row][col] = melon;
    
    return melon;
}

// A melon appears when the user touches the screen.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Get the x, y coordinates of the touch and make a Melon at that location.
    CGPoint touchLocation = [touch locationInNode:self];
    Melon *thisMelon = [self makeMelon: REGULAR_MELON atRow:touchLocation.y / _cellHeight
                                andCol:touchLocation.x / _cellWidth];
    
//    Melon *thisMelon = [self melonForTouchPosition:touchLocation];
    
    thisMelon.isActive = YES;
    
    // Update neighbor counts.
    [self countRow:thisMelon.rowPos andCol:thisMelon.colPos NeighborsOfMelon:thisMelon];
    // Remove neighbors if necessary.
    [self checkToRemoveNeighborsOfMelon:thisMelon];
    
    // Get a random number for the next melon.
    _melonLabel = arc4random_uniform(GRID_COLUMNS) + 1;
    self.updateLabel(_melonLabel);
}

// Gets the row and column that was touched and returns the melon inside the cell.
- (Melon *)melonForTouchPosition:(CGPoint)touchPosition
{
    int row = touchPosition.y / _cellHeight;
    int column = touchPosition.x / _cellWidth;
    
    Melon *touchedMelon =_gridArray[row][column];
    touchedMelon.rowPos = row;
    touchedMelon.colPos = column;
    
    return touchedMelon;
}

// Updates the number of horizontal and vertical neighbors of a melon.
- (void)countRow:(int)row andCol:(int)col NeighborsOfMelon: (Melon*)currentMelon
{
    // Initialize positions.
    currentMelon.verticalNeighborStartRow = currentMelon.rowPos;
    currentMelon.verticalNeighborEndRow = currentMelon.rowPos;
    currentMelon.horizNeighborStartCol = currentMelon.colPos;
    currentMelon.horizNeighborEndCol = currentMelon.colPos;
    
    // Count the active melons to the right of the current melon.
    for (int right = col + 1; right < [_gridArray count]; right++)
    {
        Melon *neighborMelon = _gridArray[row][right];
        if (neighborMelon.isActive) {
            currentMelon.horizNeighborEndCol++;
        }
        else {
            break; // Only count contiguous melons.
        }
    }
    
    // Count the active melons to the left of the current melon.
    for (int left = col - 1; left >= 0; left--)
    {
        Melon *neighborMelon = _gridArray[row][left];
        if (neighborMelon.isActive) {
            currentMelon.horizNeighborStartCol--;
        }
        else {
            break;
        }
    }
    
    // Count the active melons below the current melon.
    for (int down = row + 1; down < [_gridArray[row] count]; down++)
    {
        Melon *neighborMelon = _gridArray[down][col];
        if (neighborMelon.isActive) {
            currentMelon.verticalNeighborEndRow++;
        }
        else {
            break;
        }
    }
    
    // Count the active melons above the current melon.
    for (int up = row - 1; up >= 0 ; up--)
    {
        Melon *neighborMelon = _gridArray[up][col];
        if (neighborMelon.isActive) {
            currentMelon.verticalNeighborStartRow--;
        }
        else {
            break;
        }
    }
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove that column/row.
- (void)checkToRemoveNeighborsOfMelon: (Melon *)currentMelon
{
    int numVerticalNeighbors = currentMelon.verticalNeighborEndRow - currentMelon.verticalNeighborStartRow + 1;
    int numHorizNeighbors = currentMelon.horizNeighborEndCol - currentMelon.horizNeighborStartCol + 1;

    // Remove all vertical neighbors.
    if (_melonLabel == numVerticalNeighbors)
    {
        for (int i = currentMelon.verticalNeighborStartRow; i <= currentMelon.verticalNeighborEndRow; i++)
        {
            [self removeNeighborAtX:i Y:currentMelon.colPos];
        }
    }
    // Remove all horizontal neighbors.
    if (_melonLabel == numHorizNeighbors)
    {
        for (int j = currentMelon.horizNeighborStartCol; j <= currentMelon.horizNeighborEndCol; j++)
        {
            [self removeNeighborAtX:currentMelon.rowPos Y:j];
        }
    }
}

// Removes a melon at the specificed position.
- (void)removeNeighborAtX:(int)xPos Y:(int)yPos
{
    Melon *melonToBeRemoved = _gridArray[xPos][yPos];
    melonToBeRemoved.isActive = NO;
}

@end
