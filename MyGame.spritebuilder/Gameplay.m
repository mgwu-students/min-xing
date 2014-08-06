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
static const float BOMB_CHANCE_INCREASE_RATE = 0.1;
static const float INITIAL_BOMB_CHANCE = 0.01;
// Highest chance to get a bomb.
static const float BOMB_CHANCE_CAP = 0.05;
// Bonus multiplier for bombs.
static const float BOMB_BONUS_MULTIPLIER = 1.5;


// The chance to get winter melon increases at this rate per point scored.
static const float WINTERMELON_CHANCE_INCREASE_RATE = 0.1;
static const float INITIAL_WINTERMELON_CHANCE = 0.2 + INITIAL_BOMB_CHANCE;
// Highest chance to get a winter melon.
static const float WINTERMELON_CHANCE_CAP = 0.5 + BOMB_CHANCE_CAP;

// The chance to get a 5 is lower.
static const int LABEL_WITH_LESS_FREQUENCY = 5;

// Total time before game over.
static const int TOTAL_NUM_MELONS = 40;
// Number of melons on the board to start with,
static const int NUM_MELONS_ON_START = 6;

// Key for highscore.
static NSString* const HIGH_SCORE_KEY = @"highScore";
// Key for whether tutorial is completed.
static NSString* const TUTORIAL_KEY = @"tutorialDone";

@implementation Gameplay
{
    CGRect _gridBox;
    Grid *_grid;
    Melon *_melon;
    Melon *_melonIcon;
    CCLabelTTF *_numLabel;
    CCLabelTTF *_totalMelonLabel;
    CCLabelTTF *_scoreLabel;
    CCLabelTTF *_highScoreLabel;
    NSNumber *_highScoreNum;
    BOOL _tutorialCompleted;
    int _tutorialAllowedRow;
    int _tutorialAllowedCol;
    int _highScore;
    int _score;
    int _melonLabel; // Current melon number label.
    int _melonsLeft;
    int _consecutiveTimes; // Number of consecutive explosions.
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
    _chanceToGetBomb = INITIAL_BOMB_CHANCE;
    _chanceToGetWintermelon = INITIAL_WINTERMELON_CHANCE;
    
    _melonsLeft = TOTAL_NUM_MELONS;
    
    _melonIcon = (Melon *)[CCBReader load:@"Melon"];
    
    self.userInteractionEnabled = YES;
}

- (void)onEnter
{
    [super onEnter];
    
    _gridBox = _grid.boundingBox;
    
    // Retrieve high score.
    _highScoreNum = [[NSUserDefaults standardUserDefaults] objectForKey:HIGH_SCORE_KEY];
    // Retrieve whether tutorial has been completed.
    //    _tutorialCompleted = [[NSUserDefaults standardUserDefaults] objectForKey:TUTORIAL_KEY];
    
    // TESTING ONLY. DELETE THIS LINE LATER.
    _tutorialCompleted = NO;
    
    if (!_tutorialCompleted)
    {
        [self showTutorial];
    }
    
//    [self putRandomMelonsOnBoard];
//    
//    // First melon label.
//    [self updateRandomMelonLabelAndIcon];
}

// Generate random melons on board on start.
- (void)putRandomMelonsOnBoard
{
    for (int i = 0; i < NUM_MELONS_ON_START; i++)
    {
        int ranRow = arc4random_uniform(_grid.numRows);
        int ranCol = arc4random_uniform(_grid.numCols);
        
        if ([_grid hasObjectAtRow:ranRow andCol:ranCol] == NO)
        {
            _melon = (Melon *)[CCBReader load:@"Melon"];
            [_grid addObject:_melon toRow:ranRow andCol:ranCol];
        }
    }
}

#pragma mark - Tutorial

- (void)showTutorial
{
    _tutorialAllowedRow = 2;
    _tutorialAllowedCol = 3;
    [self helperShowTutorialStartCol:0 endCol:2 startRow:2 endRow:2 melonLabel:4];

//    _tutorialCompleted = YES;
//    [[NSUserDefaults standardUserDefaults] setObject:_tutorialCompleted forKey:TUTORIAL_KEY];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Displays a row or column of melons on board and updates the melon label for the tutorial.
- (void)helperShowTutorialStartCol:(int)startCol endCol:(int)endCol
                          startRow:(int)startRow endRow:(int)endRow melonLabel:(int)label
{
    _melonLabel = label;
    [self updateMelonLabelAndIcon:MelonTypeRegular];
    
    for (int row = startRow; row <= endRow; row++)
    {
        for (int col = startCol; col <= endCol; col++)
        {
            _melon = (Melon *)[CCBReader load:@"Melon"];
            [_grid addObject:_melon toRow:row andCol:col];
        }
    }
}

#pragma mark - Touch Handling

// Melon gets placed on touch.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:self];
    
    // If touch point is outside the grid, don't do anything.
    if (CGRectContainsPoint(_gridBox, touchLocation))
    {
        // Convert to grid coordinates.
        touchLocation = [touch locationInNode:_grid];
        
        int numRemoved = 0;
        int melonRow = touchLocation.y / _grid.cellHeight;
        int melonCol = touchLocation.x / _grid.cellWidth;
        
        // Limit touch in tutorial mode.
        if (!_tutorialCompleted && (melonRow != _tutorialAllowedRow ||
                                    melonCol != _tutorialAllowedCol))
        {
            return;
        }
        
        // Prevents duplicate melon placements.
        if ([_grid hasObjectAtRow:melonRow andCol:melonCol])
        {
            return;
        }
        
        // Makes a new melon and updates its location.
        _melon = (Melon *)[CCBReader load:@"Melon"];
        _melon.row =  melonRow;
        _melon.col = melonCol;
        
        // Determines what type of melon it is and acts accordingly.
        if (_tutorialCompleted && _chance <= _chanceToGetBomb && [_grid boardIsEmpty] == NO)
        {
            _melon.type = MelonTypeBomb;
            
            [_grid addObject:_melon toRow:_melon.row andCol:_melon.col];

            // Removes surrounding melons and accumulates the score.
            numRemoved = [_grid removeNeighborsAroundObjectAtRow:_melon.row andCol:_melon.col];
            
            // Bonus points for bombs.
            numRemoved *= BOMB_BONUS_MULTIPLIER;
        }
        else
        {
            if (_tutorialCompleted && _chance <= _chanceToGetWintermelon)
            {
                _melon.type = MelonTypeWinter;
            }
            else
            {
                _melon.type = MelonTypeRegular;
            }
            
            [_grid addObject:_melon toRow:_melon.row andCol:_melon.col];
            
            // Updates the melon's neighbor positions and remove them.
            [self countMelonNeighbors];
            numRemoved = [self removedNeighbors];
        }
        
        [self updateRandomMelonLabelAndIcon];
        
        [self updateScore:numRemoved];
        
        [self updateDifficulty];
        
        [self checkGameover];
    }
}

#pragma mark - Updates

// Updates the upper-right icon to match the current melon type and number.
- (void)updateRandomMelonLabelAndIcon
{
    // Random float between 0 and 1.
    _chance = drand48();
    
    if (_chance <= _chanceToGetBomb)
    {
        _melonLabel = 0;
        [self updateMelonLabelAndIcon:MelonTypeBomb];
    }
    else
    {
        // Random int btw 2 & GRID_COLUMNS.
        _melonLabel = arc4random_uniform(_grid.numCols - 1) + 2;
        
        // Roll again for certain labels to reduce the probability of its appearance.
        if (_melonLabel == LABEL_WITH_LESS_FREQUENCY)
        {
            _melonLabel = arc4random_uniform(_grid.numCols - 1) + 2;
        }
        
        if (_chance <= _chanceToGetWintermelon)
        {
            [self updateMelonLabelAndIcon:MelonTypeWinter];
        }
        else
        {
            [self updateMelonLabelAndIcon:MelonTypeRegular];
        }
    }
}

// Updates the melon label and positions the melon as an icon on the upper right corner.
- (void) updateMelonLabelAndIcon:(int)type
{
    if (_melonLabel)
    {
        _numLabel.string = [NSString stringWithFormat:@" %d", _melonLabel];
    }
    else
    {
        _numLabel.string = [NSString stringWithFormat:@" "];
    }
    
    if (_melonIcon.parent)
    {
        [_melonIcon removeFromParent];
    }
    
    _melonIcon.type = type;
    
    // Positions the melon icon.
    [_numLabel.parent addChild:_melonIcon];
    _melonIcon.anchorPoint = ccp(0.5, 0.5);
    _melonIcon.positionInPoints = _numLabel.positionInPoints;
    
    // See Melon Class for overriding scale setter.
    _melonIcon.scale = _grid.cellHeight * _grid.scaleY;
    
    // Position the number label on top of the melon icon.
    _numLabel.zOrder = 1;
}

// Calculates the score.
- (void)updateScore:(int)totalRemoved
{
    // Consecutive explosions earn a bonus score multiplier.
    if (_consecutiveTimes > 0)
    {
        _score += totalRemoved * totalRemoved * _consecutiveTimes;
    }
    else
    {
        _score += totalRemoved * totalRemoved;
        
    }
    _scoreLabel.string = [NSString stringWithFormat: @"%d", _score];
    
    // Updates consecutive explosion multiplier.
    if (totalRemoved > 0)
    {
        _consecutiveTimes++;
    }
    else
    {
        _consecutiveTimes = 0;
    }
}

// Retrieves the highs score and replace it if necessary.
- (void)updateHighScore
{
    _scoreLabel.string = [NSString stringWithFormat: @"%d", _score];
     
    NSNumber *currentHighScore = [[NSUserDefaults standardUserDefaults] objectForKey:HIGH_SCORE_KEY];
    int hs = [currentHighScore intValue];
    
    if (_score > hs)
    {
        _highScore = _score;
        _highScoreNum = [NSNumber numberWithInt:_highScore];
        [[NSUserDefaults standardUserDefaults] setObject:_highScoreNum forKey:HIGH_SCORE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        _highScore = [[[NSUserDefaults standardUserDefaults] objectForKey:HIGH_SCORE_KEY] intValue];
    }
    
    _highScoreLabel.string = [NSString stringWithFormat: @"%d", _highScore];
}

- (void)updateDifficulty
{
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
    
    _melon.totalVerticalNeighbors = _melon.verticalNeighborEndRow - _melon.verticalNeighborStartRow + 1;
    _melon.totalHorizNeighbors = _melon.horizNeighborEndCol - _melon.horizNeighborStartCol + 1;
}

// Check if the melon's label equals the number of vertical/horizontal neighbors. If so,
// remove/hit that column/row.
- (int)removedNeighbors
{
    int numRemoved = 0;
    
    // Hit all vertical neighbors.
    if (_melonLabel == _melon.totalVerticalNeighbors)
    {
        for (int i = _melon.verticalNeighborStartRow; i <= _melon.verticalNeighborEndRow; i++)
        {
            [self helperRemoveNeighborsAtRow:i andCol:_melon.col];
        }
        numRemoved += _melon.totalVerticalNeighbors;
    }
    // Hit all horizontal neighbors.
    if (_melonLabel == _melon.totalHorizNeighbors)
    {
        for (int j = _melon.horizNeighborStartCol; j <= _melon.horizNeighborEndCol; j++)
        {
            [self helperRemoveNeighborsAtRow:_melon.row andCol:j];
        }
        numRemoved += _melon.totalHorizNeighbors;
    }
    
    return numRemoved;
}

// Helper method to remove neighbor.
- (void) helperRemoveNeighborsAtRow:(int)row andCol:(int)col
{
    if ([_grid hasObjectAtRow:row andCol:col])
    {
        Melon *neighbor = [_grid getObjectAtRow:row andCol:col];

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
    // Check if the player runs out of melons.
    if (_melonsLeft <= 0)
    {
        [self gameover];
        return;
    }
    else
    {
        _melonsLeft--;
        _totalMelonLabel.string = [NSString stringWithFormat:@"%d", _melonsLeft];
    }
    
    // Check if the board is full.
    for (int i = 0; i < _grid.numRows; i++)
    {
        for (int j = 0; j < _grid.numCols; j++)
        {
            if ([_grid hasObjectAtRow:i andCol:j] == NO)
            {
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
    
    [self updateHighScore];
}

- (void)restart
{
     [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

@end