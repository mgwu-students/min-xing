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
static const float BOMB_CHANCE = 0.0;
// Chance to get a wintermelon.
static const float INITIAL_WINTERMELON_CHANCE = 0.22;


@implementation Grid {
    NSMutableArray *_gridArray;
    float _cellWidth;
    float _cellHeight;
    int _melonLabel; // Current melon number label.
    float _chanceToGetWintermelon;
    float _chanceToGetBomb;
    float _chance;
    Melon *currentMelon;
}


- (void)onEnter
{
    [super onEnter];
    
    [self setupGrid];
    
    [self updateMelonLabel];
    
    currentMelon = (Melon *)[CCBReader load:@"Melon"];
    
     _chanceToGetBomb = BOMB_CHANCE;
    _chanceToGetWintermelon = _chanceToGetBomb + INITIAL_WINTERMELON_CHANCE;
    
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

// Melon appears on touch.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Get the x, y coordinates of the touch and make a Melon at that location.
    CGPoint beginLocation = [touch locationInNode:self];
    int currentRow = beginLocation.y / _cellHeight;
    int currentCol = beginLocation.x / _cellWidth;

    currentMelon = (Melon *)[CCBReader load:@"Melon"];
    
    // Prevent duplicate touches.
    if (_gridArray[currentRow][currentCol] != [NSNull null]) {
        return;
    }
    
    if (_chance <= _chanceToGetBomb) {
        CCLOG(@"BOMB");
    }
    else {
        if (_chance <= _chanceToGetWintermelon) {
            CCLOG(@"Making winter melon.");
            // Changes the sprite frame to a winter melon.
            currentMelon.type = MelonTypeWinter;
        }
        else {
            // Only do this for regular green melon.
            // Count row and column neighbors.
            currentMelon.type = MelonTypeRegular;
            [self countNeighborsOf:currentMelon atRow:currentRow andCol:currentCol];
        }
        
        // Put melon on board.
        [self positionMelon:currentMelon atRow:currentRow andCol:currentCol];
        [self addChild: currentMelon];
    }
}

// Melon moves with touch.
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Centers the melon.
    currentMelon.anchorPoint = ccp(0.5, 0.5);
    
    //Follow finger movements.
    CGPoint currentLocation = [touch locationInNode:self];
    currentMelon.position = currentLocation;
    
    // TODO: Highlight passing grid.
}

// Melon gets added to the grid on release.
- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Get the x, y coordinates of the touch and make a Melon at that location.
    CGPoint endLocation = [touch locationInNode:self];
    int currentRow = endLocation.y / _cellHeight;
    int currentCol = endLocation.x / _cellWidth;
 
    // Prevent putting multiple objects at the same location.
    if (_gridArray[currentRow][currentCol] != [NSNull null]) {
        return;
    }
    
    // Special effect for bombs.
    if (_chance <= _chanceToGetBomb) {
        // Remove surrounding melons.
        [self explodeMelonsAdjacentToRow:currentRow andCol:currentCol];
    }
    else {
        // Add melon.
        [self positionMelon:currentMelon atRow:currentRow andCol:currentCol];
        _gridArray[currentRow][currentCol] = currentMelon;
        
        // Only do this for regular green melon.
        if (currentMelon.type == MelonTypeRegular) {
            // Remove row and column neighbors if necessary.
            [self checkToRemoveNeighborsOf:currentMelon atRow:currentRow andCol:currentCol];
        }
    }

    [self updateMelonLabel];
}

// Updates the current melon's row and column.
- (void)updateRowAndCol:(CGPoint)location
{
    currentMelon.row = location.y / _cellHeight;
    currentMelon.col = location.x / _cellWidth;
}

// Put a melon on the board at the specified position on the board..
- (void)positionMelon:(Melon *)melon atRow:(int)row andCol:(int)col
{
    melon.anchorPoint = ccp(0, 0);
    melon.position = ccp (col * _cellWidth, row * _cellHeight);
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
        // Generate random int btw 1 & GRID_COLUMNS
        _melonLabel = arc4random_uniform(GRID_COLUMNS) + 1;
        self.updateLabel(_melonLabel);
    }
}


// Remove the melons surounding the bomb
- (void)explodeMelonsAdjacentToRow:(int)row andCol:(int)col
{
    for (int i = row - 1; i <= row + 1; i++) {
        for (int j = col - 1; j <= col + 1; j++) {
            // Boundary check.
            if (i < 0 || i >= GRID_ROWS || j < 0 || j >= GRID_COLUMNS) {
                break;
            }
            // Remove melon.
            if (_gridArray[i][j] != [NSNull null]) {
                [self removeMelonAtX:i Y:j];
            }
        }
    }
}


// Updates the number of horizontal and vertical neighbors of a melon.
- (void)countNeighborsOf:(Melon*)melon atRow:(int)row andCol:(int)col
{
    // Initialize positions.
    melon.verticalNeighborStartRow = row;
    melon.verticalNeighborEndRow = row;
    melon.horizNeighborStartCol = col;
    melon.horizNeighborEndCol = col;
    
    // Count the active melons to the right of the current melon.
    for (int right = col + 1; right < [_gridArray count]; right++)
    {
        if (_gridArray[row][right] != [NSNull null]) {
//            [melon wobble];
            melon.horizNeighborEndCol++;
        }
        else {
            break; // Only count contiguous melons.
        }
    }
    
    // Count the active melons to the left of the current melon.
    for (int left = col - 1; left >= 0; left--)
    {
        if (_gridArray[row][left] != [NSNull null]) {
//            [melon wobble];
            melon.horizNeighborStartCol--;
        }
        else {
            break;
        }
    }
    
    // Count the active melons above the current melon.
    for (int up = row - 1; up >= 0 ; up--)
    {
        if (_gridArray[up][col] != [NSNull null]) {
//            [melon wobble];
            melon.verticalNeighborStartRow--;
        }
        else {
            break;
        }
    }
    
    // Count the active melons below the current melon.
    for (int down = row + 1; down < [_gridArray[row] count]; down++)
    {
        if (_gridArray[down][col] != [NSNull null]) {
//            [melon wobble];
            melon.verticalNeighborEndRow++;
        }
        else {
            break;
        }
    }
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove that column/row.
- (void)checkToRemoveNeighborsOf:(Melon *)melon atRow:(int)row andCol:(int)col
{
    int numVerticalNeighbors = melon.verticalNeighborEndRow - melon.verticalNeighborStartRow + 1;
    int numHorizNeighbors = melon.horizNeighborEndCol - melon.horizNeighborStartCol + 1;

    // Remove all vertical neighbors.
    if (_melonLabel == numVerticalNeighbors)
    {
        for (int i = melon.verticalNeighborStartRow; i <= melon.verticalNeighborEndRow; i++) {
            [self removeMelonAtX:i Y:col];
        }
    }
    // Remove all horizontal neighbors.
    if (_melonLabel == numHorizNeighbors)
    {
        for (int j = melon.horizNeighborStartCol; j <= melon.horizNeighborEndCol; j++) {
            [self removeMelonAtX:row Y:j];
        }
    }
}


// Attempts to remove a melon at the specificed position.
- (void)removeMelonAtX:(int)xPos Y:(int)yPos
{
    if (_gridArray[xPos][yPos] == [NSNull null]) {
        return;
    }
    
    Melon *melonToRemove = _gridArray[xPos][yPos];
    
    // Winter melons only get removed after a certain number of hits.
    if (melonToRemove.type != MelonTypeRegular && melonToRemove.numOfHits < NUM_OF_HITS_BEFORE_BREAK)
    {
        // Every time a winter melon is hit, replace the old picture with a new one.
        [self winterMelon:melonToRemove hitTimes:melonToRemove.numOfHits + 1];
    }
    else
    {
        // Completely remove melon from board.
        [self melonRemoved:melonToRemove];
        _gridArray[xPos][yPos] = [NSNull null];
    }
}

// Changes winter melon sprite frame upon getting hit.
- (void)winterMelon:(Melon *)melon hitTimes:(int)times
{
    // Change the sprite frame of the melon that got hit.
    switch (times) {
        case 1: {
            melon.type =  MelonTypeWinterFirstHit;
            break;
        }
        case 2: {
            melon.type = MelonTypeWinterSecondHit;
            break;
        }
        default:
            break;
    }
}

// Removes the melon with particle effects.
- (void)melonRemoved:(Melon *)melon
{
    // Load and clean up particle effect.
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"MelonExplosion"];
    explosion.autoRemoveOnFinish = YES;
    
    // Place the particle effect at the melon's center.
    explosion.position = ccp(melon.position.x + melon.contentSizeInPoints.width / 2, melon.position.y +
                             melon.contentSizeInPoints.height / 2);
//    explosion.position = melon.position;
    
    // Add the particle effect to the same node the melon is on and remove the destroyed melon.
    [melon.parent addChild:explosion];
    [melon removeFromParent];
}

@end