//
//  Grid.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Grid.h"
#import "Melon.h"
#import "Bomb.h"

// Grid size.
static const int GRID_ROWS = 5;
static const int GRID_COLUMNS = 5;

// # of times a wintermelon should be cleared before removing it from the board.
static const int NUM_OF_HITS_BEFORE_BREAK = 2;
// Chance to get a bomb melon.
static const float BOMB_CHANCE = 0.1;
// Chance to get a wintermelon.
static const float INITIAL_WINTERMELON_CHANCE = 0.22;

@implementation Grid {
    NSMutableArray *_gridArray;
    float _cellWidth;
    float _cellHeight;
    int _melonLabel;
    float _chanceToGetWintermelon;
    float _chanceToGetBomb;
    float _chance;
}


- (void)onEnter
{
    [super onEnter];
    
    [self setupGrid];
    
    _chanceToGetWintermelon = INITIAL_WINTERMELON_CHANCE + BOMB_CHANCE;
    _chanceToGetBomb = BOMB_CHANCE;
    
    [self updateMelonLabel];
    
    self.userInteractionEnabled = YES;
}

- (void)setupGrid
{
    _cellWidth = self.contentSize.width / GRID_COLUMNS;
    _cellHeight = self.contentSize.height / GRID_ROWS;

    // Initializes the grid and uses NSNull objects as placeholders.
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
    int currentRow = touchLocation.y / _cellHeight;
    int currentCol = touchLocation.x / _cellWidth;
 
    // Prevent duplicate touches.
    if (_gridArray[currentRow][currentCol] != [NSNull null]) {
        return;
    }
    
    Melon *thisMelon;
    
    if (_chance <= _chanceToGetBomb) {
        [self explodeMelonsAdjacentToRow:currentRow andCol:currentCol];
    }
    else if (_chance <= _chanceToGetWintermelon) {
        thisMelon = [[Melon alloc] initWinterMelon];
        [self positionMelon:thisMelon atRow:currentRow andCol:currentCol];
    }
    else {
        // Regular green melon.
         thisMelon = [[Melon alloc] initMelon];
        [self positionMelon:thisMelon atRow:currentRow andCol:currentCol];
        
        // Count row and column neighbors, and remove neighbors if necessary.
        [self countRow:currentRow andCol:currentCol NeighborsOfMelon:thisMelon];
        [self checkToRemoveNeighborsOfMelon:thisMelon atRow:currentRow andCol:currentCol];
    }
    
    [self updateMelonLabel];
}

// Remove the melons surounding the bomb
- (void)explodeMelonsAdjacentToRow:(int)row andCol:(int)col
{
    for (int i = row - 1; i <= row + 1; i++) {
        // Boundary check.
        if (i < 0 || i >= GRID_ROWS) {
            return;
        }
        for (int j = col - 1; j <= col + 1; j++) {
            // Boundary check.
            if (j < 0 || j >= GRID_COLUMNS) {
                break;
            }
            // Remove melon.
            if (_gridArray[i][j] != [NSNull null]) {
                [self removeNeighborAtX:i Y:j];
            }
        }
    }
}

// Put a melon on the board at the specified position in the array.
- (void)positionMelon:(Melon *)melon atRow:(int)row andCol:(int)col
{
    melon.anchorPoint = ccp(0, 0);
    melon.position = ccp (col * _cellWidth, row * _cellHeight);
    [self addChild: melon];
    _gridArray[row][col] = melon;
}

// Updates the melon's number label.
// TODO: Updae Icon
- (void) updateMelonLabel
{
    _chance = drand48(); // Random float between 0 and 1.
    
    if (_chance <= _chanceToGetBomb) {
        self.updateLabel(99); // TESTING ONLY
    }
    else if (_chance <= _chanceToGetWintermelon) {
        self.updateLabel(0); // TESTING ONLY
    }
    else {
        _melonLabel = arc4random_uniform(GRID_COLUMNS) + 1; // Random int btw 1 & GRID_COLUMNS
        self.updateLabel(_melonLabel);
    }
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
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove that column/row.
- (void)checkToRemoveNeighborsOfMelon:(Melon *)currentMelon atRow:(int)currentMelonRow andCol:(int)currentMelonCol
{
    int numVerticalNeighbors = currentMelon.verticalNeighborEndRow - currentMelon.verticalNeighborStartRow + 1;
    int numHorizNeighbors = currentMelon.horizNeighborEndCol - currentMelon.horizNeighborStartCol + 1;

    // Remove all vertical neighbors.
    if (_melonLabel == numVerticalNeighbors)
    {
        for (int i = currentMelon.verticalNeighborStartRow; i <= currentMelon.verticalNeighborEndRow; i++) {
            [self removeNeighborAtX:i Y:currentMelonCol];
        }
    }
    // Remove all horizontal neighbors.
    if (_melonLabel == numHorizNeighbors)
    {
        for (int j = currentMelon.horizNeighborStartCol; j <= currentMelon.horizNeighborEndCol; j++) {
            [self removeNeighborAtX:currentMelonRow Y:j];
        }
    }
}

// Removes a melon at the specificed position.
- (void)removeNeighborAtX:(int)xPos Y:(int)yPos
{
    if (_gridArray[xPos][yPos] == [NSNull null]) {
        return;
    }
    
    Melon *melonToBeRemoved = _gridArray[xPos][yPos];
    
    // Change the wintermelon picture upon 1st and 2nd hit.
    if (melonToBeRemoved.isWinterMelon && melonToBeRemoved.numOfHits < NUM_OF_HITS_BEFORE_BREAK) {
        [self winterMelonGotHit:melonToBeRemoved atRow:xPos andCol:yPos];
    }
    else {
        // Completely remove melon from board.
        [self melonRemoved:melonToBeRemoved];
        _gridArray[xPos][yPos] = [NSNull null];
    }
}

// Handles winter melon hits.
- (void)winterMelonGotHit:(Melon *)winterMelon atRow:(int)x andCol:(int)y
{
    winterMelon.numOfHits++;

    // Display different images depending on how many times it's been hit.
    switch (winterMelon.numOfHits)
    {
        case 1: {
            [winterMelon removeFromParent]; // Remove original.
            Melon *winterMelonFirstHit = [[Melon alloc]initWinterMelonFirstHit]; // New picture.
            [self positionMelon:winterMelonFirstHit atRow:x andCol:y];
            winterMelonFirstHit.numOfHits = 1;
            break;
        }
        case 2: {
            [winterMelon removeFromParent];
            Melon *winterMelonSecondHit = [[Melon alloc]initWinterMelonSecondHit];
            [self positionMelon:winterMelonSecondHit atRow:x andCol:y];
            winterMelonSecondHit.numOfHits = 2;
        }
        default:
            break;
    }
}


- (void)melonRemoved:(Melon *)melon
{
    // Load particle effect.
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"MelonExplosion"];
    // Clean up particle effect.
    explosion.autoRemoveOnFinish = YES;
    // Place the particle effect at the melon's center.
    explosion.position = ccp(melon.position.x + melon.contentSizeInPoints.width / 2, melon.position.y +
                             melon.contentSizeInPoints.height / 2);
    // Add the particle effect to the same node the seal is on.
    [melon.parent addChild:explosion];
    
    // Remove the destroyed melon.
    [melon removeFromParent];
}

@end
