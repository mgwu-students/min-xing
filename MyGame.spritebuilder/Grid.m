//
//  Grid.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Grid.h"
#import "Melon.h"

static const int GRID_ROWS = 6;
static const int GRID_COLUMNS = 6;

@implementation Grid {
    NSMutableArray *_gridArray;
    float _cellWidth;
    float _cellHeight;
}

- (void)onEnter
{
    [super onEnter];
    
    [self setupGrid];
    
    // Accept touches on the grid.
    self.userInteractionEnabled = YES;
}

- (void)setupGrid
{
    // Divide the grid's size by the number of col/rows to figure out
    // the right width and height of each cell
    _cellWidth = self.contentSize.width / GRID_COLUMNS;
    _cellHeight = self.contentSize.height / GRID_ROWS;
    
    float x = 0;
    float y = 0;
    
    // Initialize the array as a blank NSMutableArray.
    _gridArray = [NSMutableArray array];
    
    // Initialize melons.
    for (int i = 0; i < GRID_ROWS; i++) {
        _gridArray[i] = [NSMutableArray array];
        x = 0;
        
        for (int j = 0; j < GRID_COLUMNS; j++) {
            Melon *melon = [[Melon alloc] initMelons];
            melon.anchorPoint = ccp(0, 0);
            melon.position = ccp (x, y);
            [self addChild: melon];
            
            _gridArray[i][j] = melon;
            
            x += _cellWidth;
        }
        
        y += _cellHeight;
    }
}


- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Get the x, y coordinates of the touch.
    CGPoint touchLocation = [touch locationInNode:self];
    // Get the Melon at that location.
    Melon *thisMelon = [self melonForTouchPosition:touchLocation];
    
    thisMelon.isActive = YES;
    
    thisMelon.numLabel = 5; // TESTING ONLY
    thisMelon.isLabeled = YES; // TESTING ONLY
    
    // Update neighbor counts.
    [self countRow:thisMelon.rowPos andCol:thisMelon.colPos NeighborsOfMelon:thisMelon];
    int numVerticalNeighbors = thisMelon.verticalNeighborEndRow - thisMelon.verticalNeighborStartRow + 1;
    int numHorizNeighbors = thisMelon.horizNeighborEndCol - thisMelon.horizNeighborStartCol + 1;
    
//    CCLOG(@"Num of vertical neighbors: %d", numVerticalNeighbors);
//    CCLOG(@"Num of horizontal neighbors: %d", numHorizNeighbors);
    
    // Remove all vertical neighbors.
    if (thisMelon.numLabel == numVerticalNeighbors) {
        for (int i = thisMelon.verticalNeighborStartRow; i <= thisMelon.verticalNeighborEndRow; i++) {
            Melon *neighborToRemove = _gridArray[i][thisMelon.colPos];
            neighborToRemove.isActive = NO;
        }
    }
    // Remove all horizontal neighbors.
    if (thisMelon.numLabel == numHorizNeighbors) {
        for (int j = thisMelon.horizNeighborStartCol; j <= thisMelon.horizNeighborEndCol; j++) {
            Melon *neighborToRemove = _gridArray[thisMelon.rowPos][j];
            CCLOG(@"Removing melon at pos: %d %d", thisMelon.rowPos, j);
            neighborToRemove.isActive = NO;
        }
    }
}

- (Melon *)melonForTouchPosition:(CGPoint)touchPosition
{
    // Get the row and column that was touched, return the Melon inside the cell.
    int row = touchPosition.y / _cellHeight;
    int column = touchPosition.x / _cellWidth;
    Melon *touchedMelon =_gridArray[row][column];
    touchedMelon.rowPos = row;
    touchedMelon.colPos = column;
    return touchedMelon;
}


- (void)countRow:(int)row andCol: (int)col NeighborsOfMelon: (Melon*)currentMelon
{
    
    // Initialize.
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
    for (int up = row - 1; up >= 0 ; up--) {
        Melon *neighborMelon = _gridArray[up][col];
        if (neighborMelon.isActive) {
            currentMelon.verticalNeighborStartRow--;
        }
        else {
            break;
        }
    }
}

// Removes a melon at the specificed position.
- (void)removeNeighborAtX:(int)xPos Y:(int)yPos
{
    Melon *melonToBeRemoved =  _gridArray[xPos][yPos];
    melonToBeRemoved.isActive = NO;
}

@end
