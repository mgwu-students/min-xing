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
#import "WinPopup.h"

// The chance to get bomb increases at this rate per point scored.
static const float BOMB_CHANCE_INCREASE_RATE = 0.005;
static const float INITIAL_BOMB_CHANCE = 0.001;
// Highest chance to get a bomb.
static const float BOMB_CHANCE_CAP = 0.05;
// The chance to get winter melon increases at this rate per point scored.
static const float WINTERMELON_CHANCE_INCREASE_RATE = 0.01;
static const float INITIAL_WINTERMELON_CHANCE = 0.18 + INITIAL_BOMB_CHANCE;
// Highest chance to get a winter melon.
static const float WINTERMELON_CHANCE_CAP = 0.5 + BOMB_CHANCE_CAP;

// Total time before game over.
static const int TOTAL_TIME_IN_SECONDS = 50;

@implementation Gameplay
{
    Grid *_grid;
    Melon *_melon;
    CCLabelTTF *_numLabel;
    CCLabelTTF *_timeLabel;
    CCLabelTTF *_scoreLabel;
    CCLabelTTF *_highScoreLabel;
    CGRect _gridBox;
    int _melonLabel; // Current melon number label.
    int _score;
    NSNumber *highScore;
    int _timeLeft;
    float _chanceToGetWintermelon;
    float _chanceToGetBomb;
    float _chance;
    BOOL _firstTouch;
}

#pragma mark - Initialize

- (id)init
{
    self = [super init];
    return self;
}

- (void)didLoadFromCCB
{
    _chanceToGetBomb = INITIAL_BOMB_CHANCE;
    _chanceToGetWintermelon = INITIAL_WINTERMELON_CHANCE;
    
    _score = 0;
    highScore = [NSNumber numberWithInteger:9001];
    [[NSUserDefaults standardUserDefaults] setObject:highScore forKey:@"highScore"];
    
    _timeLeft = TOTAL_TIME_IN_SECONDS;
    _firstTouch = YES;
    
    self.userInteractionEnabled = YES;
}

- (void)onEnter
{
    [super onEnter];
    
    _gridBox = _grid.boundingBox;
    
    // First melon label.
    [self updateMelonLabelAndIcon];
}

#pragma mark - Touch Handling

// Melon gets placed on touch.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Current touch location.
    CGPoint touchLocation = [touch locationInNode:self];
    
    // If touch point is outside the grid, don't do anything.
    if (CGRectContainsPoint(_gridBox, touchLocation))
    {
        if (_firstTouch) {
            // Start the timer.
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(onTick:)
                                           userInfo:nil
                                            repeats:YES];
            _firstTouch = NO;
        }
        
        // Convert to grid coordinates.
        touchLocation = [touch locationInNode:_grid];
        
        // Makes a new melon and update its location.
        _melon = (Melon *)[CCBReader load:@"Melon"];
        [self updateMelonRowAndCol:touchLocation];
        
        [_grid addChild:_melon];
        
        // Prevents duplicate touches.
        if ([_grid hasObjectAtRow:_melon.row andCol:_melon.col])
        {
            [_melon removeFromParent];
            return;
        }
        
        // Adds melon to the grid.
        [_grid addObject:_melon toRow:_melon.row andCol:_melon.col];
        
        // Determines what type of melon it is and changes type accordingly.
        if (_chance <= _chanceToGetBomb)
        {
            _melon.type = MelonTypeBomb;
            
            // Positions and scales melon on board.
            [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
            
            // Removes the bomb.
            [_melon explodeOrChangeFrame];
            [_grid removeObjectAtX:_melon.row Y:_melon.col];
            
            // Removes surrounding melons and accumulates the score.
            int totalNeighborRemoved = [_grid removeNeighborsAroundObjectAtRow:_melon.row andCol:_melon.col];
            [self updateScoreAndDifficulty:totalNeighborRemoved andCalculateHighScore:NO];
        }
        else
        {
            if (_chance <= _chanceToGetWintermelon)
            {
                _melon.type = MelonTypeWinter;
            }
            else
            {
                _melon.type = MelonTypeRegular;
            }
            
            // Positions and scales melon on board.
            [_grid positionNode:_melon atRow:_melon.row andCol:_melon.col];
            
            // Updates the melon's neighbor positions and remove them.
            [self countMelonNeighbors];
            
//            CCLOG(@"horizontal neighbor start col: %d", _melon.horizNeighborStartCol);
//            CCLOG(@"horizontal neighbor end col: %d", _melon.horizNeighborEndCol);
//            CCLOG(@"vertical neighbor start row: %d", _melon.verticalNeighborStartRow);
//            CCLOG(@"vertical neighbor end row: %d", _melon.verticalNeighborEndRow);

            [self removeNeighbors];
        }
        
        [self updateMelonLabelAndIcon];
        
//        [self printBoardState];
        
        [self checkGameover];
    }
}


#pragma mark - Updates

// This is called every second by the timer.
-(void)onTick:(NSTimer *)timer
{
    _timeLeft--;
    
    _timeLabel.string = [NSString stringWithFormat:@"%d", _timeLeft];
    
    if (_timeLeft == 0)
    {
        [self gameover];
    }
}

- (void) updateMelonLabelAndIcon
{
    _melon = (Melon *)[CCBReader load:@"Melon"];

    // Random float between 0 and 1.
    _chance = drand48();
    
    if (_chance <= _chanceToGetBomb)
    {
        _melon.type = MelonTypeBomb;
        _numLabel.string = [NSString stringWithFormat:@" "];
    }
    else
    {
        if (_chance <= _chanceToGetWintermelon)
        {
            _melon.type = MelonTypeWinter;
        }
        else
        {
            _melon.type = MelonTypeRegular;
        }
        
        // Random int btw 1 & GRID_COLUMNS.
        _melonLabel = arc4random_uniform(_grid.numCols) + 1;
        _numLabel.string = [NSString stringWithFormat:@" %d", _melonLabel];
    }
    
    // Positions the melon icon.
    [_numLabel.parent addChild:_melon];
    _melon.anchorPoint = ccp(0.5, 0.5);
    _melon.positionInPoints = _numLabel.positionInPoints;
    
    // See Melon Class for overriding scale setter.
    _melon.scale = _grid.cellHeight * _grid.scaleY;
    
    // Position the number label on top of the melon icon.
    _numLabel.zOrder = 1;
}

// Updates the melon's row and column.
- (void)updateMelonRowAndCol:(CGPoint)location
{
    _melon.row = location.y / _grid.cellHeight;
    _melon.col = location.x / _grid.cellWidth;
}

// Updates total score.
- (void)updateScoreAndDifficulty:(int)addScore andCalculateHighScore:(BOOL)calculate
{
    // Updates score.
    _score += addScore;
    _scoreLabel.string = [NSString stringWithFormat: @"%d", _score];
    
    // Updates chance to get bomb.
    if (_chanceToGetBomb < BOMB_CHANCE_CAP)
    {
        _chanceToGetBomb += _chanceToGetBomb * BOMB_CHANCE_INCREASE_RATE;
//        CCLOG(@"Chance to get bomb: %f", _chanceToGetBomb);
    }
    
    // Updates chance to get winte rmelon.
    if (_chanceToGetWintermelon < WINTERMELON_CHANCE_CAP)
    {
        _chanceToGetWintermelon += _chanceToGetWintermelon * WINTERMELON_CHANCE_INCREASE_RATE;
//        CCLOG(@"Chance to get wintermelon: %f", _chanceToGetWintermelon);
    }
    
    if (calculate) {
        NSNumber *currentHighScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"highScore"];
        int hs = [currentHighScore intValue];

        if (_score > hs)
        {
            highScore = [NSNumber numberWithInteger:_score];
            [[NSUserDefaults standardUserDefaults] setObject:highScore forKey:@"highScore"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            _highScoreLabel.string = [NSString stringWithFormat: @"%d", highScore.integerValue];
        }
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
        if ([_grid hasObjectAtRow:_melon.row andCol:right])
        {
            _melon.horizNeighborEndCol++;
        }
        else
        {
            break; // Only count contiguous melons.
        }
    }
    
    // Count the number of melons to the left of the current melon.
    for (int left = _melon.col - 1; left >= 0; left--)
    {
        if ([_grid hasObjectAtRow:_melon.row andCol:left])
        {
            _melon.horizNeighborStartCol--;
        }
        else
        {
            break;
        }
    }
    
    // Count the number of melons below the current melon.
    for (int up = _melon.row + 1; up < _grid.numRows; up++)
    {
        if ([_grid hasObjectAtRow:up andCol:_melon.col])
        {
            _melon.verticalNeighborEndRow++;
        }
        else
        {
            break;
        }
    }
    
    // Count the number of melons above the current melon.
    for (int down = _melon.row - 1; down >= 0 ; down--)
    {
        if ([_grid hasObjectAtRow:down andCol:_melon.col])
        {
            _melon.verticalNeighborStartRow--;
        }
        else
        {
            break;
        }
    }
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove/hit that column/row.
- (void)removeNeighbors
{
    int totalVerticalNeighbors = _melon.verticalNeighborEndRow - _melon.verticalNeighborStartRow + 1;
    int totalHorizNeighbors = _melon.horizNeighborEndCol - _melon.horizNeighborStartCol + 1;
    
    // Hit the melon itself.
    if (_melonLabel == 1 && (totalHorizNeighbors == 1 || totalVerticalNeighbors == 1))
    {
        [self helperRemoveNeighborsAtRow:_melon.row andCol:_melon.col];
        
        return;
    }
    
    // Hit all vertical neighbors.
    if (_melonLabel == totalVerticalNeighbors)
    {
        for (int i = _melon.verticalNeighborStartRow; i <= _melon.verticalNeighborEndRow; i++)
        {
            [self helperRemoveNeighborsAtRow:i andCol:_melon.col];
        }
    }
    // Hit all horizontal neighbors.
    if (_melonLabel == totalHorizNeighbors)
    {
        for (int j = _melon.horizNeighborStartCol; j <= _melon.horizNeighborEndCol; j++)
        {
            [self helperRemoveNeighborsAtRow:_melon.row andCol:j];
        }
    }
}



// Helper method to remove neighbor.
- (void) helperRemoveNeighborsAtRow:(int)row andCol:(int)col
{
    if ([_grid hasObjectAtRow:row andCol:col])
    {
        Melon *neighbor = [_grid getObjectAtRow:row andCol:col];

        // Accumulates score.
        [self updateScoreAndDifficulty:1 andCalculateHighScore:NO];

        // Loads explosion effects and possible winter melon frame changes.
        [neighbor explodeOrChangeFrame];
        
        // Remove this melon completely.
        if (neighbor.type == MelonTypeRegular || neighbor.type == MelonTypeWinterThirdHit)
        {
            [_grid removeObjectAtX:row Y:col];
        }
    }
}

#pragma mark - Gameover

- (void)checkGameover
{
    for (int i = 0; i < _grid.numRows; i++)
    {
        for (int j = 0; j < _grid.numCols; j++)
        {
            if ([_grid hasObjectAtRow:i andCol:j] == NO)
            {
                CCLOG(@"Grid at row %d col %d is null", i, j);
                // There exists an empty cell. Continue playing.
                return;
            }
        }
    }
    
    // Every position on the grid is filled. Gameover.
    [self gameover];
}

- (void)gameover
{
    WinPopup *popup = (WinPopup *)[CCBReader load:@"Gameover" owner:self];
    popup.positionType = CCPositionTypeNormalized;
    popup.position = ccp(0.5, 0.5);
    [self addChild:popup];
    
    [self updateScoreAndDifficulty:0 andCalculateHighScore:YES];
}

- (void)restart
{
     [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

#pragma mark - Debugging

- (void)printBoardState
{
    for (int row = 0; row < _grid.numRows; row++)
    {
        CCLOG(@"\n");
        for (int col = 0 ; col <_grid.numCols; col++)
        {
            CCLOG(@"%d ", [_grid getObjectAtRow:row andCol:col] != [NSNull null]);
        }
    }
}

@end