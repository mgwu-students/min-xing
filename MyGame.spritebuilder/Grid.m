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
    
    [self setupGrid];
    
    self.userInteractionEnabled = YES;
    
    // First melon label: random number between 1 and GRID_COLUMNS.
    _melonLabel = arc4random_uniform(GRID_COLUMNS) + 1;
    self.updateLabel(_melonLabel);
    
    _chanceToGetObstacle = INITIAL_OBSTACLE_CHANCE;
}

- (void)setupGrid
{
    _cellWidth = self.contentSize.width / GRID_COLUMNS;
    _cellHeight = self.contentSize.height / GRID_ROWS;
 
    _gridArray = [NSMutableArray array];
    for (int i = 0; i < GRID_ROWS; i++) {
        _gridArray[i] = [NSMutableArray array];
        
        for (int j = 0; j < GRID_COLUMNS; j++) {
            _gridArray[i][j] = [NSNull null]; // placeholder
        }
    }
}

// A melon appears when the user touches the screen.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Get the x, y coordinates of the touch and make a Melon at that location.
    CGPoint touchLocation = [touch locationInNode:self];
    int melonRow = touchLocation.y / _cellHeight;
    int melonCol = touchLocation.x / _cellWidth;
    
//    CCLOG(@"melonRow, melonCol %d %d", melonRow, melonCol);
    
    Melon *thisMelon = [self makeMelon: REGULAR_MELON atRow:melonRow andCol:melonCol];
    
    // Update neighbor counts and remove neighbors if necessary.
    [self countRow:melonRow andCol:melonCol NeighborsOfMelon:thisMelon];
    [self checkToRemoveNeighborsOfMelon:thisMelon atRow:melonRow andCol:melonCol];
    
    // Get a random number for the next melon.
    _melonLabel = arc4random_uniform(GRID_COLUMNS) + 1;
    self.updateLabel(_melonLabel);
}

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
    melon.position = ccp (col * _cellWidth, row * _cellHeight);
    [self addChild: melon];
    
    _gridArray[row][col] = melon;
    
    return melon;
}

// Updates the number of horizontal and vertical neighbors of a melon.
- (void)countRow:(int)row andCol:(int)col NeighborsOfMelon: (Melon*)currentMelon
{
    // Initialize positions.
    currentMelon.verticalNeighborStartRow = row;
    currentMelon.verticalNeighborEndRow = row;
    currentMelon.horizNeighborStartCol = col;
    currentMelon.horizNeighborEndCol = col;
    
    // Count the active melons to the right of the current melon.
    for (int right = col + 1; right < [_gridArray count]; right++)
    {
        if (_gridArray[row][right] != [NSNull null]) {
            currentMelon.horizNeighborEndCol++;
        }
        else {
            break; // Only count contiguous melons.
        }
    }
    
    // Count the active melons to the left of the current melon.
    for (int left = col - 1; left >= 0; left--)
    {
        if (_gridArray[row][left] != [NSNull null]) {
            currentMelon.horizNeighborStartCol--;
        }
        else {
            break;
        }
    }
    
    // Count the active melons below the current melon.
    for (int down = row + 1; down < [_gridArray[row] count]; down++)
    {
        if (_gridArray[down][col] != [NSNull null]) {
            currentMelon.verticalNeighborEndRow++;
        }
        else {
            break;
        }
    }
    
    // Count the active melons above the current melon.
    for (int up = row - 1; up >= 0 ; up--)
    {
        if (_gridArray[up][col] != [NSNull null]) {
            currentMelon.verticalNeighborStartRow--;
        }
        else {
            break;
        }
    }
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove that column/row.
- (void)checkToRemoveNeighborsOfMelon:(Melon *)currentMelon atRow:(int)currentMelonRow andCol:(int)currentMelonCol
{
    int numVerticalNeighbors = currentMelon.verticalNeighborEndRow - currentMelon.verticalNeighborStartRow + 1;
    int numHorizNeighbors = currentMelon.horizNeighborEndCol - currentMelon.horizNeighborStartCol + 1;
    
//    CCLOG(@"vertical neighbors: %d", numVerticalNeighbors);
//    CCLOG(@"horizontal neighbors: %d", numHorizNeighbors);

    // Remove all vertical neighbors.
    if (_melonLabel == numVerticalNeighbors)
    {
        for (int i = currentMelon.verticalNeighborStartRow; i <= currentMelon.verticalNeighborEndRow; i++)
        {
            [self removeNeighborAtX:i Y:currentMelonCol];
        }
    }
    // Remove all horizontal neighbors.
    if (_melonLabel == numHorizNeighbors)
    {
        for (int j = currentMelon.horizNeighborStartCol; j <= currentMelon.horizNeighborEndCol; j++)
        {
            [self removeNeighborAtX:currentMelonRow Y:j];
        }
    }
}

// Removes a melon at the specificed position.
- (void)removeNeighborAtX:(int)xPos Y:(int)yPos
{
//    CCLOG(@"x, y: %d %d", xPos, yPos);
    if (_gridArray[xPos][yPos] != [NSNull null]) {
        Melon *melonToBeRemoved = _gridArray[xPos][yPos];
        [melonToBeRemoved removeFromParent];
        _gridArray[xPos][yPos] = [NSNull null];
    }
}
@end
