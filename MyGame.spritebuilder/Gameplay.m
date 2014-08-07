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
// Initial and maximum probability to get a boomb.
static const float INITIAL_BOMB_CHANCE = 0.01, BOMB_CHANCE_CAP = 0.05;
// Bonus multiplier for bombs.
static const float BOMB_BONUS_MULTIPLIER = 1.5;


// The chance to get winter melon increases at this rate per point scored.
static const float WINTERMELON_CHANCE_INCREASE_RATE = 0.1;
// Initial and maximum probability to get a winter melon.
static const float INITIAL_WINTERMELON_CHANCE = 0.2 + INITIAL_BOMB_CHANCE,
                    WINTERMELON_CHANCE_CAP = 0.5 + BOMB_CHANCE_CAP;

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
    Melon *_melon, *_melonIcon;
    CCLabelTTF *_tutorialText;
    CCLabelTTF *_numLabel;
    CCLabelTTF *_totalMelonLabel, *_totalMelonLabelStr;
    CCLabelTTF *_scoreLabel, *_scoreLabelStr, *_highScoreLabel;
    CCButton *_playButtonAtEndOfTutorial, *_tutorialAgain;
    CCParticleSystem *_cellHighlight;
    NSNumber *_highScoreNum;
    BOOL _tutorialCompleted;
    int _tutorialCurrentStep, _tutorialAllowedRow, _tutorialAllowedCol;
    int _melonLabel; // Current melon number label.
    int _melonsLeft;
    int _score, _highScore;
    int _consecutiveTimes; // Number of consecutive explosions.
    float _chance, _chanceToGetWintermelon, _chanceToGetBomb;
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
    
    // TESTING ONLY.
    _tutorialCompleted = NO;
    
    if (!_tutorialCompleted)
    {
        [self labelsVisible:NO];
        
        [self showTutorialAtStep:_tutorialCurrentStep];
    }
    else
    {
        [self startGame];
    }
}

- (void)startGame
{
    if (_playButtonAtEndOfTutorial.parent)
    {
        [_playButtonAtEndOfTutorial removeFromParent];
    }
    
    if (_tutorialAgain.parent)
    {
        [_tutorialAgain removeFromParent];
    }
    
    _score = 0;
    _tutorialCompleted = YES;
    
    [self labelsVisible:YES];
    
    [self putRandomMelonsOnBoard];
    
    // First melon label.
    [self updateRandomMelonLabelAndIcon];
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

- (void)showTutorialAtStep:(int)step
{
    switch (step)
    {
        case 0:
        {
            _tutorialText.string = @"\nThe number 4 on the right\nmeans you can explode\n"
                "a row of 4 melons.\n\nPlace the 4th melon\non the glowing cell.";
            [self helperShowTutorialStartCol:0 endCol:2 startRow:2 endRow:2
                                  melonLabel:4 type:MelonTypeRegular];
            [self updateAllowedRow:2 andCol:3];
        }
            break;
        case 1:
        {
            _tutorialText.string = @"\n\nExplosions can be vertical\ntoo!\n\n"
                "(But not diagonal...)";
            [self helperShowTutorialStartCol:2 endCol:2 startRow:0 endRow:1
                                  melonLabel:3 type:MelonTypeRegular];
            [self updateAllowedRow:2 andCol:2];
        }
            break;
        case 2:
        {
            _tutorialText.string = @"\nWell done!\n\nYou can also explode\na row and a "
                "column\ntogether.";
            [self helperShowTutorialStartCol:0 endCol:1 startRow:2 endRow:2
                                  melonLabel:3 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:2 endCol:2 startRow:3 endRow:4
                                  melonLabel:3 type:MelonTypeRegular];
            [self updateAllowedRow:2 andCol:2];
        }
            break;
        case 3:
        {
            _tutorialText.string = @"\nNice job!\n\nWinter melon takes\n3 hits to remove.";
            [self helperShowTutorialStartCol:0 endCol:0 startRow:2 endRow:2
                                  melonLabel:4 type:MelonTypeWinter];
            [self helperShowTutorialStartCol:1 endCol:1 startRow:2 endRow:2
                                  melonLabel:3 type:MelonTypeRegular];
            [self updateAllowedRow:2 andCol:2];
        }
            break;
        case 4:
        {
            _tutorialText.string = @"\n\nHit the winter melon\nagain.";
            [self updateAllowedRow:2 andCol:1];
            _melonLabel = 2;
            [self updateMelonLabelAndIcon:MelonTypeRegular];
        }
            break;
        case 5:
        {
            _tutorialText.string = @"\n\nGreat! Now you can\nremove it.";
        }
            break;
        case 6:
        {
            _tutorialText.string = @"If a melon doesn't\nexplode anything, its\nlabel "
            "disappears and\nit will remain on the\nboard until another\nmelon removes it.";
            _melonLabel = 2;
            [self updateMelonLabelAndIcon:MelonTypeRegular];
            [self updateAllowedRow:4 andCol:2];
        }
            break;
        case 7:
        {
            _tutorialText.string = @"\n\nPlace another one.";
            _melonLabel = 4;
            [self updateMelonLabelAndIcon:MelonTypeRegular];
            [self updateAllowedRow:4 andCol:4];
        }
            break;
        case 8:
        {
            _tutorialText.string = @"\n\nLabel 3 works.\nNow explode them!";
            _melonLabel = 3;
            [self updateMelonLabelAndIcon:MelonTypeRegular];
            [self updateAllowedRow:4 andCol:3];
        }
            break;
        default:
        {
            _tutorialText.string = @"Very nice!!\nYou have a limited\n number of melons.\n"
                "Game ends when\nthey run out. Shoot\nfor a high score!";
            [self updateAllowedRow:-1 andCol:-1];
            
            _playButtonAtEndOfTutorial.visible = YES;
            _tutorialAgain.visible = YES;
        }
    }
   
    _tutorialCurrentStep++;
    
//    [[NSUserDefaults standardUserDefaults] setObject:_tutorialCompleted forKey:TUTORIAL_KEY];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Displays a row or column of melons on board and updates the melon label for the tutorial.
- (void)helperShowTutorialStartCol:(int)startCol endCol:(int)endCol
                          startRow:(int)startRow endRow:(int)endRow
                          melonLabel:(int)label type:(int)melonType
{
    _melonLabel = label;
    [self updateMelonLabelAndIcon:MelonTypeRegular];
    
    for (int row = startRow; row <= endRow; row++)
    {
        for (int col = startCol; col <= endCol; col++)
        {
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melon.type = melonType;
            [_grid addObject:_melon toRow:row andCol:col];
        }
    }
}

// In tutorial mode, touch is only allowed in one cell at each step.
- (void)updateAllowedRow:(int)row andCol:(int)col
{
    _tutorialAllowedRow = row;
    _tutorialAllowedCol = col;
        
    [self highlightCellAtRow:row andCol:col];
}

// In tutorial mode, highlight the cell the player is supposed to tap.
- (void)highlightCellAtRow:(int)row andCol:(int)col
{
    if (_cellHighlight.parent)
    {
        [_cellHighlight removeFromParent];
    }
    
    if (row >= 0 && row < _grid.numRows && col >= 0 && col < _grid.numCols)
    {
        _cellHighlight = (CCParticleSystem *)[CCBReader load:@"highlightedCell"];
        
        [_grid addChild:_cellHighlight];
        
        _cellHighlight.position = ccp(col * _grid.cellWidth + _grid.cellWidth / 2,
                                 row * _grid.cellHeight + _grid.cellHeight / 2);
        _cellHighlight.anchorPoint = ccp(0.5, 0.5);
    }
}

// Whether the total melon labels and the score labels are visible.
- (void)labelsVisible:(BOOL)visiblility
{
    _totalMelonLabel.visible = visiblility;
    _totalMelonLabelStr.visible = visiblility;
    
    _scoreLabel.visible = visiblility;
    _scoreLabelStr.visible = visiblility;
    
    _playButtonAtEndOfTutorial.visible = visiblility;
    _tutorialAgain.visible = visiblility;
    
    _tutorialText.visible = !visiblility;
}

// Go through the tutorial again.
- (void)showTutorialAgain
{
    [self labelsVisible:NO];
    
    _tutorialCurrentStep = 0;
    
    [self showTutorialAtStep:_tutorialCurrentStep];
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
        
        // Prevents duplicate melon placements.
        if ([_grid hasObjectAtRow:melonRow andCol:melonCol])
        {
            return;
        }
        
        // Limit touch in tutorial mode.
        if (!_tutorialCompleted && (melonRow != _tutorialAllowedRow ||
                                   melonCol != _tutorialAllowedCol))
        {
            return;
        }
        

        // Makes a new melon and updates its location.
        _melon = (Melon *)[CCBReader load:@"Melon"];
        _melon.row =  melonRow;
        _melon.col = melonCol;
        
        // Determines what type of melon it is and acts accordingly.
        if (_chance <= _chanceToGetBomb && [_grid boardIsMoreThanHalfFull])
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
        
        if (!_tutorialCompleted)
        {
            [self showTutorialAtStep:_tutorialCurrentStep];
        }
        else
        {
            [self updateRandomMelonLabelAndIcon];
            
            [self updateScore:numRemoved];
            
            [self updateDifficulty];
            
            [self checkGameover];
        }
    }
}

#pragma mark - Updates

// Updates the upper-right icon to match the current melon type and number.
- (void)updateRandomMelonLabelAndIcon
{
    // Random float between 0 and 1.
    _chance = drand48();
    
    if (_chance <= _chanceToGetBomb && [_grid boardIsMoreThanHalfFull])
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
    else if (_melon.type != MelonTypeBomb)
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