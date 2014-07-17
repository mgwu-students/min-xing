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
static const float BOMB_CHANCE = 0.07;
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
    // Makes a melon and update its location.
    currentMelon = (Melon *)[CCBReader load:@"Melon"];
    [self updateRowAndCol:[touch locationInNode:self]];
    
    // Prevents duplicate touches.
    if (_gridArray[currentMelon.row][currentMelon.col] != [NSNull null]) {
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
            // Only does this for regular green melon.
            // Count row and column neighbors.
            currentMelon.type = MelonTypeRegular;
        }
        
        // Puts melon on board.
        [self positionMelon:currentMelon atRow:currentMelon.row andCol:currentMelon.col];
        [self addChild: currentMelon];
        
        // Makes clearable melon wobble.
        [self countNeighborsOf:currentMelon atRow:currentMelon.row andCol:currentMelon.col];
        [self wobble:YES orRemoveNeighborsOf:currentMelon atRow:currentMelon.row andCol:currentMelon.col];

    }
}

// Melon moves with touch.
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Centers the melon.
    currentMelon.anchorPoint = ccp(0.5, 0.5);
    
    //Follows finger movements.
    CGPoint currentLocation = [touch locationInNode:self];
    currentMelon.position = currentLocation;
    
    // Dynamically makes clearable melon wobble.
    [self updateRowAndCol:currentLocation];
    [self countNeighborsOf:currentMelon atRow:currentMelon.row andCol:currentMelon.col];
    [self wobble:YES orRemoveNeighborsOf:currentMelon atRow:currentMelon.row andCol:currentMelon.col];
    
    // TODO: Highlight passing grid.
}

// Melon gets added to the grid on release.
- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Updates melon location.
    [self updateRowAndCol:[touch locationInNode:self]];
 
    // Prevent putting multiple objects at the same location.
    if (_gridArray[currentMelon.row][currentMelon.col] != [NSNull null]) {
        return;
    }
    
    // Special effect for bombs.
    if (_chance <= _chanceToGetBomb) {
        // Remove surrounding melons.
        [self explodeMelonsAdjacentToRow:currentMelon.row andCol:currentMelon.col];
    }
    else {
        // Add melon.
        [self positionMelon:currentMelon atRow:currentMelon.row andCol:currentMelon.col];
        _gridArray[currentMelon.row][currentMelon.col] = currentMelon;
        
        // Only do this for regular green melon.
        if (currentMelon.type == MelonTypeRegular) {
            // Remove row and column neighbors if necessary.
            [self countNeighborsOf:currentMelon atRow:currentMelon.row andCol:currentMelon.col];
            [self wobble:NO orRemoveNeighborsOf:currentMelon atRow:currentMelon.row andCol:currentMelon.col];
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

// Put a melon on the board at the specified position on the board.
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
        // Generate random int btw 2 & GRID_COLUMNS
        _melonLabel = arc4random_uniform(GRID_COLUMNS - 1) + 2;
        self.updateLabel(_melonLabel);
    }
}


// Remove the melons surounding the bomb.
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
            melon.verticalNeighborEndRow++;
        }
        else {
            break;
        }
    }
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove that column/row.
- (void)wobble:(BOOL)wobbly orRemoveNeighborsOf:(Melon *)melon atRow:(int)row andCol:(int)col
{
    int numVerticalNeighbors = melon.verticalNeighborEndRow - melon.verticalNeighborStartRow + 1;
    int numHorizNeighbors = melon.horizNeighborEndCol - melon.horizNeighborStartCol + 1;

    // Remove all vertical neighbors.
    if (_melonLabel == numVerticalNeighbors)
    {
        for (int i = melon.verticalNeighborStartRow; i <= melon.verticalNeighborEndRow; i++) {
            if (wobbly && _gridArray[i][col] != [NSNull null]) {
                // Wobble the melon and its clearable neighbors.
                [melon wobble];
                Melon *neighborMelon = _gridArray[i][col];
                [neighborMelon wobble];
            }
            else {
                [self removeMelonAtX:i Y:col];
            }
        }
    }
    // Remove all horizontal neighbors.
    if (_melonLabel == numHorizNeighbors)
    {
        for (int j = melon.horizNeighborStartCol; j <= melon.horizNeighborEndCol; j++) {
            if (wobbly && _gridArray[row][j] != [NSNull null]) {
                // Wobble the melon and its clearable neighbors.
                [melon wobble];
                Melon *neighborMelon = _gridArray[row][j];
                [neighborMelon wobble];
            }
            else {
                [self removeMelonAtX:row Y:j];
            }
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
        melonToRemove.numOfHits++;
        // Every time a winter melon is hit, replace the old picture with a new one.
        [self winterMelon:melonToRemove hitTimes:melonToRemove.numOfHits];
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