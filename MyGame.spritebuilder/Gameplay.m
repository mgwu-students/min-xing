//
//  Gameplay.m
//  MyGame
//
//  Created by Min Xing on 7/7/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "Grid.h"
#import "Melon.h"

// Chance to get a bomb melon.
static const float BOMB_CHANCE = 0.05;
// Chance to get a winter melon.
static const float INITIAL_WINTERMELON_CHANCE = 0.22;

@implementation Gameplay {
    Grid *_grid;
    Melon *_melon;
    CCLabelTTF *_numLabel;
    int _melonLabel; // Current melon number label.
    float _chanceToGetWintermelon;
    float _chanceToGetBomb;
    float _chance;
    float _gridHeightOffset;
    float _gridWidthOffset;
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)didLoadFromCCB
{
    _chanceToGetBomb = BOMB_CHANCE;
    _chanceToGetWintermelon = _chanceToGetBomb + INITIAL_WINTERMELON_CHANCE;
    
    _melon = (Melon *)[CCBReader load:@"Melon"];
    
    [self updateMelonLabel]; // First melon label.
    
    self.userInteractionEnabled = YES;
}

// Melon appears on touch.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Makes a melon and update its location.
    _melon = (Melon *)[CCBReader load:@"Melon"];
    CGPoint touchLocation = [touch locationInNode:_grid];

    [self updateMelonRowAndCol:touchLocation];
 
    // Prevents duplicate touches.
    if ([_grid isNullAtRow:_melon.row andCol:_melon.col] == NO) {
        return;
    }
    
    // Determine what type of melon it is and change type accordingly.
    if (_chance <= _chanceToGetBomb) {
        _melon.type = MelonTypeBomb;
    }
    else if (_chance <= _chanceToGetWintermelon) {
        _melon.type = MelonTypeWinter;
    }
    else {
        _melon.type = MelonTypeRegular;
        
        // Makes clearable neighbor melon wobble.
        [self countMelonNeighbors];
        [self wobbleOrRemoveNeighbors:NO];
    }
    
    // Puts melon on board.
    [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
    [_grid addChild: _melon];
}

// Melon moves with touch.
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Centers the melon.
    _melon.anchorPoint = ccp(0.5, 0.5);
    
    //Follows finger movements.
    [self updateMelonRowAndCol:[touch locationInNode:_grid]];
    [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
    
    // Only wobble melons when the current melon doesn't overlap another melon.
    if ([_grid isNullAtRow:_melon.row andCol:_melon.col] && _melon.type == MelonTypeRegular) {
        // Makes clearable neighbor melon wobble.
        [self countMelonNeighbors];
        [self wobbleOrRemoveNeighbors:NO];
    }
}

// Melon gets added to the grid on release.
- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Updates melon location.
    [self updateMelonRowAndCol:[touch locationInNode:_grid]];
    
    // Prevent putting multiple objects at the same location.
    if ([_grid isNullAtRow:_melon.row andCol:_melon.col] == NO) {
        // Remove the current melon if it's not properly placed.
        [_melon removeFromParent];
        return;
    }
    
    // Add melon.
    [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
    [_grid addObject:_melon toRow:_melon.row andCol:_melon.col];
    
    // Check to remove neighbors for bombs and regular green melons.
    if (_melon.type == MelonTypeBomb) {
        // Remove the bomb.
        [_melon explode];
        [_grid removeObjectAtX:_melon.row Y:_melon.col];
        
        // Remove surrounding melons.
        [_grid removeNeighborsAroundObjectAtRow:_melon.row andCol:_melon.col];
    }
    else if (_melon.type == MelonTypeRegular) {
        // Remove row and column neighbors if necessary.
        [self countMelonNeighbors];
        
//        CCLOG(@"horizontal neighbor start col %d", _melon.horizNeighborStartCol);
//        CCLOG(@"horizontal neighbor end col %d", _melon.horizNeighborEndCol);
//        CCLOG(@"vertical neighbor start row %d", _melon.verticalNeighborStartRow);
//        CCLOG(@"vertical neighbor end row %d", _melon.verticalNeighborEndRow);
        
        [self wobbleOrRemoveNeighbors:YES];
    }
    
    [self updateMelonLabel];
}

- (void) updateMelonLabel
{
    _chance = drand48(); // Random float between 0 and 1.
    
    if (_chance <= _chanceToGetBomb) {
        _numLabel.string = [NSString stringWithFormat:@"%d", 99];
    }
    else if (_chance <= _chanceToGetWintermelon) {
        _numLabel.string = [NSString stringWithFormat:@"%d", 0];
    }
    else {
        _melonLabel = arc4random_uniform(_grid.numCols) + 1; // Random int btw 1 & GRID_COLUMNS
        _numLabel.string = [NSString stringWithFormat:@"%d", _melonLabel];
    }
}

// Updates the melon's row and column.
- (void)updateMelonRowAndCol:(CGPoint)location
{
    _melon.row = location.y / _grid.cellHeight;
    _melon.col = location.x / _grid.cellWidth;
    
//    CCLOG(@"melon row, col %d  %d", _melon.row, _melon.col);
}

// Updates the number of horizontal and vertical neighbors of a melon.
- (void)countMelonNeighbors
{
    // Initialize positions.
    _melon.verticalNeighborStartRow = _melon.row;
    _melon.verticalNeighborEndRow = _melon.row;
    _melon.horizNeighborStartCol = _melon.col;
    _melon.horizNeighborEndCol = _melon.col;
    
    // Count the active melons to the right of the current melon.
    for (int right = _melon.col + 1; right < _grid.numCols; right++)
    {
        if ([_grid isNullAtRow:_melon.row andCol:right] == NO) {
            _melon.horizNeighborEndCol++;
        }
        else {
            break; // Only count contiguous melons.
        }
    }
    
    // Count the active melons to the left of the current melon.
    for (int left = _melon.col - 1; left >= 0; left--)
    {
        if ([_grid isNullAtRow:_melon.row andCol:left] == NO) {
            _melon.horizNeighborStartCol--;
        }
        else {
            break;
        }
    }
    
    // Count the active melons above the current melon.
    for (int down = _melon.row - 1; down >= 0 ; down--)
    {
        if ([_grid isNullAtRow:down andCol:_melon.col] == NO) {
            _melon.verticalNeighborStartRow--;
        }
        else {
            break;
        }
    }
    
    // Count the active melons below the current melon.
    for (int up = _melon.row + 1; up < _grid.numRows; up++)
    {
        if ([_grid isNullAtRow:up andCol:_melon.col] == NO) {
            _melon.verticalNeighborEndRow++;
        }
        else {
            break;
        }
    }
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove that column/row.
- (void)wobbleOrRemoveNeighbors:(BOOL)removeNeighbor
{
    int numVerticalNeighbors = _melon.verticalNeighborEndRow - _melon.verticalNeighborStartRow + 1;
    int numHorizNeighbors = _melon.horizNeighborEndCol - _melon.horizNeighborStartCol + 1;
    
    // Remove all vertical neighbors.
    if (_melonLabel == numVerticalNeighbors) {
        for (int i = _melon.verticalNeighborStartRow; i <= _melon.verticalNeighborEndRow; i++) {
            [self helperWobbleOrRemove:removeNeighbor NeighborsAtRow:i andCol:_melon.col];
        }
    }
    // Removes all horizontal neighbors.
    if (_melonLabel == numHorizNeighbors) {
        for (int j = _melon.horizNeighborStartCol; j <= _melon.horizNeighborEndCol; j++) {
            [self helperWobbleOrRemove:removeNeighbor NeighborsAtRow:_melon.row andCol:j];
        }
    }
}

// Helper method to remove or wobble neighbor.
- (void) helperWobbleOrRemove:(BOOL)remove NeighborsAtRow:(int)row andCol:(int)col
{
    if ( [_grid isNullAtRow:row andCol:col] == NO) {
        Melon *neighbor = [_grid getObjectAtRow:row andCol:col];
        
        if (remove) {
            // Remove reference unless it's a winter melon.
            if (neighbor.type == MelonTypeWinter || neighbor.type == MelonTypeWinterFirstHit) {
                // Attempt to explode the neighbor (change pic if winter melon).
                [neighbor explode];
            }
            else {
                [_grid removeObjectAtX:row Y:col];
            }
        }
        else {
            // Wobble the neighbor and the current melon.
            [neighbor wobble];
            [_melon wobble];
        }
    }
}

// Reloads the scene.
- (void)restart
{
     [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

@end
