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

// The chance to get bomb increases at this rate per point scored.
static const float BOMB_CHANCE_INCREASE_RATE = 0.001;
// Chance to get a bomb melon.
static const float INITIAL_BOMB_CHANCE = 0.0001;
// Highest chance to get a bomb.
static const float BOMB_CHANCE_CAP = 0.05;
// The chance to get winter melon increases at this rate per point scored.
static const float WINTERMELON_CHANCE_INCREASE_RATE = 0.01;
// Chance to get a winter melon.
static const float INITIAL_WINTERMELON_CHANCE = 0.18 + INITIAL_BOMB_CHANCE;
// Highest chance to get a winter melon.
static const float WINTERMELON_CHANCE_CAP = 0.3 + BOMB_CHANCE_CAP;

@implementation Gameplay
{
    Grid *_grid;
    Melon *_melon;
    CCLabelTTF *_numLabel;
    CCLabelTTF *_scoreLabel;
    CGRect _gridBox;
    int _melonLabel; // Current melon number label.
    int _score;
    float _chanceToGetWintermelon;
    float _chanceToGetBomb;
    float _chance;
}

#pragma mark - Initialize

- (id)init
{
    self = [super init];
    return self;
}

- (void)didLoadFromCCB
{
    // Initialize chances to get bomb and winter melons.
    _chanceToGetBomb = INITIAL_BOMB_CHANCE;
    _chanceToGetWintermelon = INITIAL_WINTERMELON_CHANCE;
    
    // Initialize score.
    _score = 0;
    
    self.userInteractionEnabled = YES;
}

- (void)onEnter
{
    [super onEnter];
    
    // Grid's bounding box.
    _gridBox = _grid.boundingBox;
    
    // First melon label.
    [self updateMelonLabelAndIcon];
}

#pragma mark - Touch Handling

// Melon appears on touch.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Current touch location.
    CGPoint touchLocation = [touch locationInNode:self];
    
    // If touch point is outside the grid, don't do anything.
    if (CGRectContainsPoint(_gridBox, touchLocation) == NO) {
        return;
    }
    
    // Convert to grid coordinates.
    touchLocation = [touch locationInNode:_grid];
    
    // Makes a new melon.
    _melon = (Melon *)[CCBReader load:@"Melon"];
    
    // Updatets the melon's location.
    [self updateMelonRowAndCol:touchLocation];
 
    // Prevents duplicate touches.
    if ([_grid hasObjectAtRow:_melon.row andCol:_melon.col]) {
        return;
    }
    
    // Determine what type of melon it is and change type accordingly.
    if (_chance <= _chanceToGetBomb) {
        _melon.type = MelonTypeBomb;
    }
    else {
        if (_chance <= _chanceToGetWintermelon) {
            _melon.type = MelonTypeWinter;
        }
        else {
            _melon.type = MelonTypeRegular;
        }
        // Updates the current melon's neighbor positions.
        [self countMelonNeighbors];
        // Makes clearable neighbors wobble (without removing them).
        [self wobbleOrRemoveNeighbors:NO];
    }

    // Positions the melon.
    [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
    // Adds the melon to the grid.
    [_grid addChild: _melon];
}

// Melon moves with touch.
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Current touch location.
    CGPoint touchLocation = [touch locationInNode:self];
    
    // If touch point is outside the grid, don't do anything.
    if (CGRectContainsPoint(_gridBox, touchLocation) == NO) {
        return;
    }
    
    // Convert to grid coordinates.
    touchLocation = [touch locationInNode:_grid];
    
    // Centers the melon.
    _melon.anchorPoint = ccp(0.5, 0.5);
    
    // Updates the melon's current location.
    [self updateMelonRowAndCol:touchLocation];
    
    // Position melon to follow finger movements.
    [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
    
    // Only wobble melons when the current (regular) melon doesn't overlap another melon.
    if ([_grid hasObjectAtRow:_melon.row andCol:_melon.col] == NO) {
        // Updates the current melon's neighbor positions.
        [self countMelonNeighbors];
        // Makes clearable neighbors wobble (without removing them).
        [self wobbleOrRemoveNeighbors:NO];
    }
}

// Melon gets added to the grid on release.
- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Current touch location.
    CGPoint touchLocation = [touch locationInNode:self];
    
    // If touch point is outside the grid, don't do anything.
    if (CGRectContainsPoint(_gridBox, touchLocation) == NO) {
        return;
    }
    
    // Converts to grid coordinates.
    touchLocation = [touch locationInNode:_grid];
    
    // Updates melon location.
    [self updateMelonRowAndCol:touchLocation];
    
    // Prevents putting multiple melons at the same location.
    if ([_grid hasObjectAtRow:_melon.row andCol:_melon.col]) {
        // Remove the current melon if it's not properly placed.
        [_melon removeFromParent];
        return;
    }
    
    // Position melon on board.
    [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
    // Adds melon to the grid.
    [_grid addObject:_melon toRow:_melon.row andCol:_melon.col];
    
    // Check to remove neighbors for bomb and regular melon.
    if (_melon.type == MelonTypeBomb) {
        // Removes the bomb.
        [_melon explodeOrChangeFrame];
        [_grid removeObjectAtX:_melon.row Y:_melon.col];
        
        // Removes surrounding melons and accumulates the score.
        int numNeighborRemoved =[_grid removeNeighborsAroundObjectAtRow:_melon.row andCol:_melon.col];
        [self updateScoreAndDifficulty:numNeighborRemoved];
    }
    else {
        // Updates the current melon's neighbor positions.
        [self countMelonNeighbors];
        
        CCLOG(@"horizontal neighbor start col: %d", _melon.horizNeighborStartCol);
        CCLOG(@"horizontal neighbor end col: %d", _melon.horizNeighborEndCol);
        CCLOG(@"vertical neighbor start row: %d", _melon.verticalNeighborStartRow);
        CCLOG(@"vertical neighbor end row: %d", _melon.verticalNeighborEndRow);
        
        // Removes the melon's neighbors on mouse release.
        [self wobbleOrRemoveNeighbors:YES];
    }
    
    [self updateMelonLabelAndIcon];
    
    [self printoutBoardState];
}

#pragma mark - Updates

- (void) updateMelonLabelAndIcon
{
    // Reloads melon.
    _melon = (Melon *)[CCBReader load:@"Melon"];

    // Random float between 0 and 1.
    _chance = drand48();
    
    if (_chance <= _chanceToGetBomb) {
        _melon.type = MelonTypeBomb;
        _numLabel.string = [NSString stringWithFormat:@" "];
    }
    else {
        if (_chance <= _chanceToGetWintermelon) {
            _melon.type = MelonTypeWinter;
        }
        else {
            _melon.type = MelonTypeRegular;
        }
        
        // Random int btw 1 & GRID_COLUMNS.
        _melonLabel = arc4random_uniform(_grid.numCols) + 1;
        _numLabel.string = [NSString stringWithFormat:@" %d", _melonLabel];
    }
    
    // Position the melon icon.
    [_numLabel.parent addChild:_melon];
    _melon.anchorPoint = ccp(0.5, 0.5);
    _melon.scale = _grid.cellHeight * _grid.scaleY;
    _melon.positionInPoints = _numLabel.positionInPoints;
    
    // Position the number on top of the melon icon.
    _numLabel.zOrder = 1;
}

// Updates the melon's row and column.
- (void)updateMelonRowAndCol:(CGPoint)location
{
    _melon.row = location.y / _grid.cellHeight;
    _melon.col = location.x / _grid.cellWidth;
}

// Updates total score.
- (void)updateScoreAndDifficulty:(int)addScore
{
    // Updates score.
    _score += addScore;
    _scoreLabel.string = [NSString stringWithFormat: @"%d", _score];
    
    // Updates chance to get bomb.
    if (_chanceToGetBomb < BOMB_CHANCE_CAP) {
        _chanceToGetBomb += _chanceToGetBomb * BOMB_CHANCE_INCREASE_RATE;
//        CCLOG(@"Chance to get bomb: %f", _chanceToGetBomb);
    }
    
    // Updates chance to get winte rmelon.
    if (_chanceToGetWintermelon < WINTERMELON_CHANCE_CAP) {
        _chanceToGetWintermelon += _chanceToGetWintermelon * WINTERMELON_CHANCE_INCREASE_RATE;
//        CCLOG(@"Chance to get wintermelon: %f", _chanceToGetWintermelon);
    }
}

#pragma mark - Neighbor Handling

// Updates the number of horizontal and vertical neighbors of a melon.
- (void)countMelonNeighbors
{
    // Initialize positions.
    _melon.verticalNeighborStartRow = _melon.row;
    _melon.verticalNeighborEndRow = _melon.row;
    _melon.horizNeighborStartCol = _melon.col;
    _melon.horizNeighborEndCol = _melon.col;
    
    // Count the number of melons to the right of the current melon.
    for (int right = _melon.col + 1; right < _grid.numCols; right++)
    {
        if ([_grid hasObjectAtRow:_melon.row andCol:right]) {
            _melon.horizNeighborEndCol++;
        }
        else {
            break; // Only count contiguous melons.
        }
    }
    
    // Count the number of melons to the left of the current melon.
    for (int left = _melon.col - 1; left >= 0; left--)
    {
        if ([_grid hasObjectAtRow:_melon.row andCol:left]) {
            _melon.horizNeighborStartCol--;
        }
        else {
            break;
        }
    }
    
    // Count the number of melons below the current melon.
    for (int up = _melon.row + 1; up < _grid.numRows; up++)
    {
        if ([_grid hasObjectAtRow:up andCol:_melon.col]) {
            _melon.verticalNeighborEndRow++;
        }
        else {
            break;
        }
    }
    
    // Count the number of melons above the current melon.
    for (int down = _melon.row - 1; down >= 0 ; down--)
    {
        if ([_grid hasObjectAtRow:down andCol:_melon.col]) {
            _melon.verticalNeighborStartRow--;
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
    if ([_grid hasObjectAtRow:row andCol:col]) {
        Melon *neighbor = [_grid getObjectAtRow:row andCol:col];
        
        if (remove) {
            // Accumulates score.
            [self updateScoreAndDifficulty:1];

            // Loads explosion effects and possible winter melon frame changes.
            [neighbor explodeOrChangeFrame];
            
            // Remove this melon completely.
            if (neighbor.type == MelonTypeRegular || neighbor.type == MelonTypeWinterThirdHit) {
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

#pragma mark - Reload

- (void)restart
{
     [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

#pragma mark - Debugging

- (void)printoutBoardState
{
    for (int row = 0; row < _grid.numRows; row++) {
        CCLOG(@"\n");
        for (int col = 0 ; col <_grid.numCols; col++) {
            CCLOG(@"%d ", [_grid getObjectAtRow:row andCol:col] != [NSNull null]);
        }
    }
}

@end