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
#import "TutorialPopup.h"

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

// Consecutive explosions gives a bonus multiplier.
static const int EXPLOSION_TIMES_BONUS_CAP = 3;

// The chance to get a 5 is lower.
static const int LABEL_WITH_LESS_FREQUENCY = 5;

// Total time before game over.
static const int TOTAL_NUM_MELONS = 40;

// Number of melons on the board to start with,
static const int NUM_MELONS_ON_START = 6;

// Number of pixels below the label in the y-axis.
static const int MELON_ICON_Y_OFFSET = 0;

// After this number of explosions, stops highlighting cells with possible explosions.
static const int NUM_EXPLOSIONS_BEFORE_TUTORIAL_HIGHLIGHT_STOPS = 5;

// Key for highscore.
static NSString* const HIGH_SCORE_KEY = @"highScore";
// Key for whether tutorial is completed.
static NSString* const TUTORIAL_KEY = @"tutorialDone";

@implementation Gameplay
{
    CGRect _gridBox;
    Grid *_grid, *_highlightedCells;
    Melon *_melon, *_melonIcon;
    TutorialPopup *_tutorialPopup;
    CCLabelTTF *_tutorialText, *_tutorialPopupText, *_gameOverText;
    CCLabelTTF *_totalMelonLabel, *_totalMelonLabelText;
    CCLabelTTF *_scoreLabel, *_scoreLabelText, *_highScoreLabel;
    CCLabelTTF *_numLabel;
    CCButton *_playButtonAtEndOfTutorial, *_tutorialAgainButton;
    CCButton *_hideHighlightsButton;
    CCButton *_backButton, *_nextButton, *_repeatButton;
    CCButton *_backButtonAtTop, *_nextButtonAtTop;
    CCNode *_nextArrow;
    NSNumber *_highScoreNum;
    BOOL _tutorialCompleted;
    BOOL _acceptTouch;
    BOOL _promptHighlightPopup;
    int _tutorialCurrentStep;
    int _melonLabel; // Current melon number label.
    int _melonsLeft;
    int _score, _highScore;
    int _consecutiveTimes; // Number of consecutive explosions.
    int _numExplosionsAfterGameStarts; // Show hints before this reaches NUM_EXPLOSIONS_BEFORE_TUTORIAL_HIGHLIGHT_STOPS.
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
    
    _highlightedCells = [[Grid alloc]init];
    
    self.userInteractionEnabled = YES;
}

- (void)onEnter
{
    [super onEnter];
    
    _gridBox = _grid.boundingBox;

    // Retrieve high score.
    _highScoreNum = [[NSUserDefaults standardUserDefaults] objectForKey:HIGH_SCORE_KEY];
    // Retrieve whether tutorial has been completed.
     _tutorialCompleted = [[NSUserDefaults standardUserDefaults] boolForKey:TUTORIAL_KEY];
 
    if (_tutorialCompleted)
    {
        _promptHighlightPopup = NO;
    }
    else
    {
        _promptHighlightPopup = YES;
    }
    
    if (!_tutorialCompleted)
    {
        [self tutorialLabelsHide:NO];
        
        [self showTutorialAtStep:_tutorialCurrentStep];
    }
    else
    {
        [self startGame];
    }
}

- (void)startGame
{
    _score = 0;
    _acceptTouch = YES;
    
    [self tutorialLabelsHide:YES];

    _playButtonAtEndOfTutorial.visible = NO;
    _tutorialAgainButton.visible = NO;
    
    [_grid clearBoardAndRemoveChildren:YES];
    [_highlightedCells clearBoardAndRemoveChildren:YES];
    
    [self putRandomMelonsOnBoard];
    
    // First melon label.
    [self updateRandomMelonLabelAndIcon];
    
    _tutorialCompleted = YES;
    [[NSUserDefaults standardUserDefaults] setBool:_tutorialCompleted forKey:TUTORIAL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
            [_grid addObject:_melon toRow:ranRow andCol:ranCol asChild:YES];
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
            [self loadTutorialPopup];
            [self tutorialPopupVisible: YES];
            _tutorialPopupText.string = @"\n\nGoal:\n\nGet as many points\nas possible by\nclearing melons\n"
                "on the board.";
            
            _numLabel.string = [NSString stringWithFormat:@" "];
            
            _backButton.visible = NO;
            _backButtonAtTop.visible = NO;
            _nextButtonAtTop.visible = NO;
            _nextArrow.visible = NO;
        }
            break;
        case 1:
        {
            [self tutorialPopupVisible: YES];
            _tutorialPopupText.string = @"\n\nThe number 3 on the\nmelon means if you\nadd "
                "a 3rd melon to\na row or column\nof 2 melons, all 3\nmelons will explode.";
            
            _melonLabel = 3;
            [self updateMelonLabelAndIconType:MelonTypeRegular];
        }
            break;
        case 2:
        {
            [self tutorialPopupVisible:NO];
            _tutorialText.string = @"Tap to place your 4th\nmelon on a glowing cell.";

            [self helperShowTutorialStartCol:0 endCol:0 startRow:0 endRow:2
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:1 endCol:1 startRow:2 endRow:2
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:2 endCol:2 startRow:2 endRow:2
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:3 endCol:3 startRow:0 endRow:0
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:4 endCol:4 startRow:1 endRow:3
                                  melonLabel:5 type:MelonTypeRegular];
            
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melonLabel = 4;
            [self updateMelonLabelAndIconType:MelonTypeRegular];
            
            [self highlightExplosionCells];
        }
            break;
        case 3:
        {
            [self tutorialPopupVisible: NO];
                        
            _tutorialText.string = @"Good job!\nNow try to make a 5.";
        
            [_grid clearBoardAndRemoveChildren:YES];
            
            [self helperShowTutorialStartCol:0 endCol:3 startRow:0 endRow:0
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:1 endCol:1 startRow:1 endRow:2
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:2 endCol:2 startRow:2 endRow:2
                                  melonLabel:4 type:MelonTypeRegular];
            
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melonLabel = 5;
            [self updateMelonLabelAndIconType:MelonTypeRegular];
        }
            break;
        case 4:
        {
            [self tutorialPopupVisible: NO];
            _tutorialText.string = @"Try to get 2 in a row\nor column.";
            
            [_grid clearBoardAndRemoveChildren:YES];
            
            [self helperShowTutorialStartCol:0 endCol:3 startRow:3 endRow:3
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:1 endCol:2 startRow:2 endRow:2
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:3 endCol:3 startRow:0 endRow:0
                                  melonLabel:4 type:MelonTypeRegular];
            [self helperShowTutorialStartCol:4 endCol:4 startRow:1 endRow:1
                                  melonLabel:4 type:MelonTypeRegular];
            
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melonLabel = 2;
            [self updateMelonLabelAndIconType:MelonTypeRegular];
        }
            break;
        case 5:
        {
            [self tutorialPopupVisible: YES];
            _tutorialPopupText.string = @"Nice!\n\nExplosions can be\nvertical and/or\nhorizontal, "
                "but\nNOT diagonal.";
            
            _backButton.visible = YES;
        }
            break;
        case 6:
        {
            [self tutorialPopupVisible:YES];
            _tutorialPopupText.string = @"\nThere're 2 type of\nmelons: green & blue.\n\nEach time "
                "you get\na random melon with\na random number.";
            
            [_grid clearBoardAndRemoveChildren:YES];
            
            [self updateMelonLabelAndIconType:MelonTypeWinter];
        }
            break;
        case 7:
        {
            [self tutorialPopupVisible:YES];
            _tutorialPopupText.string = @"\nA (blue) winter melon\ntakes 3 hits to clear.";
        }
            break;
        case 8:
        {
            [self tutorialPopupVisible:NO];
            _tutorialText.string = @"Place the winter melon\nanywhere on the board.";
            
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melon.type = MelonTypeWinter;
            
            _melonLabel = 4;
            [self updateMelonLabelAndIconType:MelonTypeWinter];
        }
            break;
        case 9:
        {
            [self tutorialPopupVisible: NO];
            _tutorialText.string = @"Place another winter\nmelon.";
            
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melon.type = MelonTypeWinter;
            
            _melonLabel = 2;
            [self updateMelonLabelAndIconType:MelonTypeWinter];
        }
            break;
        case 10:
        {
            [self tutorialPopupVisible: NO];
            _tutorialText.string = @"Click any empty cell to\ncontinue.";
            
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melon.type = MelonTypeWinter;
        }
            break;
        case 11:
        {
            [self tutorialPopupVisible:NO];
            _tutorialText.string = @"You have a limited\nnumber of 40\nmelons. Place them\nwisely!";
            
            _backButtonAtTop.visible = NO;
            
            _playButtonAtEndOfTutorial.visible = YES;
            _tutorialAgainButton.visible = YES;
            
             _promptHighlightPopup = YES;
        }
            break;
        default:
            [self tutorialPopupVisible:NO];
            break;
    }
}

// Displays a row or column of melons on board and updates the melon label for the tutorial.
- (void)helperShowTutorialStartCol:(int)startCol endCol:(int)endCol
                          startRow:(int)startRow endRow:(int)endRow
                          melonLabel:(int)label type:(int)melonType
{
    _melonLabel = label;
    [self updateMelonLabelAndIconType:MelonTypeRegular];
    
    for (int row = startRow; row <= endRow; row++)
    {
        for (int col = startCol; col <= endCol; col++)
        {
            _melon = (Melon *)[CCBReader load:@"Melon"];
            _melon.type = melonType;
            [_grid addObject:_melon toRow:row andCol:col asChild:YES];
        }
    }
}

// Whether the total melon labels and the score labels are visible.
- (void)tutorialLabelsHide:(BOOL)visible
{
    _totalMelonLabel.visible = visible;
    _totalMelonLabelText.visible = visible;
    
    _scoreLabel.visible = visible;
    _scoreLabelText.visible = visible;
    
    _playButtonAtEndOfTutorial.visible = visible;
    _tutorialAgainButton.visible = visible;
    
    _nextButtonAtTop.visible = !visible;
    _nextArrow.visible = !visible;
    _backButtonAtTop.visible = !visible;
    _tutorialText.visible = !visible;
}

- (void)loadTutorialPopup
{
    _tutorialPopup = (TutorialPopup *)[CCBReader load:@"Tutorial" owner:self];
    _tutorialPopup.positionType = CCPositionTypeNormalized;
    _tutorialPopup.position = ccp(0.4, 0.6);
    [self addChild:_tutorialPopup];
}

- (void)tutorialPopupVisible:(BOOL)visible
{
    _tutorialPopup.visible = visible;
    _backButton.visible = visible;
    _nextButton.visible = visible;
    
    _backButtonAtTop.visible = !visible;
    _tutorialText.visible = !visible;
    _acceptTouch = !visible;
    
    _repeatButton.visible = !visible;
    _hideHighlightsButton.visible = !visible;
}

// Gives the player the option to click on the "next" button.
- (void)completeStep
{
    _nextButtonAtTop.visible = YES;
    _nextArrow.visible = YES;
    _tutorialText.string = @"There, you got it!";
}

// Goes to the next step of the tutorial.
- (void)goToTutorialNextStep
{
    _tutorialCurrentStep++;
    [self loadTutorialStep:_tutorialCurrentStep];
}

- (void)goToTutorialPreviousStep
{
    if (_tutorialCurrentStep > 0)
    {
        _tutorialCurrentStep--;
        [self loadTutorialStep:_tutorialCurrentStep];
    }
}

- (void)repeatTutorialStep
{
    if (_tutorialCurrentStep != 0)
    {
        _backButtonAtTop.visible = YES;
    }
    
    [self showTutorialAtStep:_tutorialCurrentStep];
}

- (void)loadTutorialStep:(int)step
{
    _nextArrow.visible = NO;
    _nextButtonAtTop.visible = NO;
    
    [_highlightedCells clearBoardAndRemoveChildren:YES];
    [_grid clearBoardAndRemoveChildren:YES];
    
    [self tutorialPopupVisible:NO];
    [self showTutorialAtStep:step];
}


// Go through the tutorial again.
- (void)showTutorialAgain
{
    _tutorialCompleted = NO;
    [[NSUserDefaults standardUserDefaults] setBool:_tutorialCompleted forKey:TUTORIAL_KEY];
    [[NSUserDefaults standardUserDefaults]synchronize];

    [self restart];
}

// Highlights all the cells where an explosion is possible.
- (void)highlightExplosionCells
{
    for (int row = 0; row < _grid.numRows; row++)
    {
        for (int col = 0; col < _grid.numCols; col++)
        {
            // Make a temp melon to count neighbors.
            Melon *melonTemp = (Melon *)[CCBReader load:@"Melon"];
            melonTemp.row = row;
            melonTemp.col = col;
            
            [_grid addChild:melonTemp];
            
            [self countMelonNeighborsOfMelon:melonTemp];
            
            // Do not highlight cells where there are melons.
            if ([_grid hasObjectAtRow:row andCol:col] == NO)
            {
                // Highlight cells where there are no current highlights and where an explosion is possible.
                if ((melonTemp.totalHorizNeighbors == _melonLabel || melonTemp.totalVerticalNeighbors == _melonLabel) &&
                    [_highlightedCells hasObjectAtRow:row andCol:col] == NO)
                {
                    CCParticleSystem *highlightOneCell = (CCParticleSystem *)[CCBReader load:@"highlightedCell"];

                    [_highlightedCells addObject:highlightOneCell toRow:row andCol:col asChild:NO];
             
                    [self highlight:highlightOneCell CellAtRow:row andCol:col];
                }
                // Remove highlights if explosions are no longer possible there.
                else if (!(melonTemp.totalHorizNeighbors == _melonLabel || melonTemp.totalVerticalNeighbors == _melonLabel) && [_highlightedCells hasObjectAtRow:row andCol:col])
                {
                    [_highlightedCells removeObjectAtX:row Y:col fromParent:YES];
                }
            }
            
            [melonTemp removeFromParent];
        }
    }
}

// In tutorial mode, highlight the cell the player is supposed to tap.
- (void)highlight:(CCParticleSystem*)cellHighlight CellAtRow:(int)row andCol:(int)col
{
    if (row >= 0 && row < _grid.numRows && col >= 0 && col < _grid.numCols && !cellHighlight.parent)
    {
        [_grid addChild:cellHighlight];
        cellHighlight.position = ccp(col * _grid.cellWidth + _grid.cellWidth / 2,
                                     row * _grid.cellHeight + _grid.cellHeight / 2);
        cellHighlight.anchorPoint = ccp(0.5, 0.5);
    }
}

- (void)hideHighlights
{
    _tutorialPopup.visible = NO;
    _acceptTouch = YES;
}

#pragma mark - Touch Handling

// Melon gets placed on touch.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!_acceptTouch)
    {
        return;
    }
    
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
        
        // Updates the melon's location.
        _melon.row =  melonRow;
        _melon.col = melonCol;
    
        // Determines what type of melon it is and acts accordingly.
        if (_melon.type == MelonTypeBomb && [_grid boardIsMoreThanHalfFull])
        {
            numRemoved = [self bombPlacedStoreNumRemoved:numRemoved];
        }
        else
        {
            numRemoved = [self melonPlacedStoreNumRemoved:numRemoved];
        }
        
        if (!_tutorialCompleted)
        {
            if ([_grid boardIsFull])
            {
                [self tutorialPopupVisible:YES];
                _repeatButton.visible = YES;
                
                _tutorialPopupText.string = @"Don't worry, let's try\nthis step again.";
                
                _backButton.visible = NO;
                _nextButton.visible = NO;
                _backButtonAtTop.visible = NO;
                _nextButtonAtTop.visible = NO;
            }
            
            if (_melon.type != MelonTypeRegular)
            {
                _tutorialCurrentStep++;
                [self showTutorialAtStep:_tutorialCurrentStep];
            }
            else
            {
                [self highlightExplosionCells];
                
                if (numRemoved == _melonLabel)
                {
                    [self completeStep];
                }
                else
                {
                    int melonType = _melon.type;
                    _melon = (Melon *)[CCBReader load:@"Melon"];
                    _melon.type = melonType;
                }
            }
        }
        else
        {
            // Previous explosion label.
            int labelTemp = _melonLabel;
            
            [self updateRandomMelonLabelAndIcon];
            
            if (_promptHighlightPopup)
            {
                if (_numExplosionsAfterGameStarts <
                    NUM_EXPLOSIONS_BEFORE_TUTORIAL_HIGHLIGHT_STOPS)
                {
                    [self highlightExplosionCells];
                    
                    // 1 explosion completed.
                    if (numRemoved == labelTemp)
                    {
                        _numExplosionsAfterGameStarts++;
                    }
                }
                else if (_numExplosionsAfterGameStarts ==
                         NUM_EXPLOSIONS_BEFORE_TUTORIAL_HIGHLIGHT_STOPS)
                {
                    // Explosions completed. Exit highlight mode.
                    [_highlightedCells clearBoardAndRemoveChildren:YES];
                    
                    _tutorialPopup.anchorPoint = ccp(0.5, 0.5);
                    
                    [self tutorialPopupVisible:YES];
                    
                    _tutorialPopup.zOrder = 1;
                    
                    _tutorialPopupText.string = @"Very nicely done.\n\nNo more glowing\ncells now. "
                        "You are\non your own!";
                    
                    _hideHighlightsButton.visible = YES;
                    _backButton.visible = NO;
                    _nextButton.visible = NO;
                    
                    _numExplosionsAfterGameStarts++;
                }
            }
            
            [self updateScore:numRemoved];
            
            [self updateDifficulty];
            
            [self checkGameover];
        }
    }
}

// Counts how many melons have been removed by the bomb.
- (int)bombPlacedStoreNumRemoved:(int)totalRemoved
{
    [_grid addObject:_melon toRow:_melon.row andCol:_melon.col asChild:YES];
    
    // Removes surrounding melons and accumulates the score.
    totalRemoved = [_grid removeNeighborsAroundObjectAtRow:_melon.row andCol:_melon.col fromParent:YES];
    
    // Bonus points for bombs.
    totalRemoved *= BOMB_BONUS_MULTIPLIER;
    
    return totalRemoved;
}

// Counts how many melons have been removed by the melon.
- (int)melonPlacedStoreNumRemoved:(int)totalRemoved
{
    if (!_melon.parent)
    {
        [_grid addObject:_melon toRow:_melon.row andCol:_melon.col asChild:YES];
        
        // Updates the melon's neighbor positions and remove them.
        [self countMelonNeighborsOfMelon:_melon];
        
        totalRemoved = [self removedNeighbors];
    }
    
    return totalRemoved;
}


#pragma mark - Updates

// Updates the upper-right icon to match the current melon type and number.
- (void)updateRandomMelonLabelAndIcon
{
    // Loads a new melon.
    _melon = (Melon *)[CCBReader load:@"Melon"];
    
    // Random float between 0 and 1.
    _chance = drand48();
    
    if (_chance <= _chanceToGetBomb && [_grid boardIsMoreThanHalfFull])
    {
        _melonLabel = 0;
        _melon.type = MelonTypeBomb;
        [self updateMelonLabelAndIconType:MelonTypeBomb];
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
            _melon.type = MelonTypeWinter;
            [self updateMelonLabelAndIconType:MelonTypeWinter];
        }
        else
        {
            _melon.type = MelonTypeRegular;
            [self updateMelonLabelAndIconType:MelonTypeRegular];
        }
    }
}

// Updates the melon label and positions the melon as an icon on the upper right corner.
- (void) updateMelonLabelAndIconType:(int)type
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
    _melonIcon.positionInPoints = ccp(_numLabel.positionInPoints.x,
                                      _numLabel.positionInPoints.y - MELON_ICON_Y_OFFSET);
    
    // See Melon Class for overriding scale setter.
    _melonIcon.scale = _grid.cellHeight * _grid.scaleY;
    
    // Position the number label on top of the melon icon.
    _numLabel.zOrder = 1;
}

// Calculates the score.
- (void)updateScore:(int)totalRemoved
{
    // Consecutive explosions earn a bonus score multiplier.
    if (_consecutiveTimes > 0 && _consecutiveTimes <= EXPLOSION_TIMES_BONUS_CAP)
    {
        _score += totalRemoved * totalRemoved * _consecutiveTimes;
        
        // Reset the number of consecutive explosions.
        if (_consecutiveTimes == EXPLOSION_TIMES_BONUS_CAP)
        {
            _consecutiveTimes = 0;
        }
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
- (void)countMelonNeighborsOfMelon:(Melon *)melon
{
    // Initialize positions.
    melon.verticalNeighborStartRow = melon.row;
    melon.verticalNeighborEndRow = melon.row;
    melon.horizNeighborStartCol = melon.col;
    melon.horizNeighborEndCol = melon.col;
    
    // Count the number of melons to the right of the current melon.
    for (int right = melon.col + 1; right < _grid.numCols; right++)
    {
        if ([_grid hasObjectAtRow:melon.row andCol:right])
        {
            melon.horizNeighborEndCol++;
        }
        else
        {
            break; // Only count contiguous melons.
        }
    }
    
    // Count the number of melons to the left of the current melon.
    for (int left = melon.col - 1; left >= 0; left--)
    {
        if ([_grid hasObjectAtRow:melon.row andCol:left])
        {
            melon.horizNeighborStartCol--;
        }
        else
        {
            break;
        }
    }
    
    // Count the number of melons below the current melon.
    for (int up = melon.row + 1; up < _grid.numRows; up++)
    {
        if ([_grid hasObjectAtRow:up andCol:melon.col])
        {
            melon.verticalNeighborEndRow++;
        }
        else
        {
            break;
        }
    }
    
    // Count the number of melons above the current melon.
    for (int down = melon.row - 1; down >= 0 ; down--)
    {
        if ([_grid hasObjectAtRow:down andCol:melon.col])
        {
            melon.verticalNeighborStartRow--;
        }
        else
        {
            break;
        }
    }
    
    melon.totalVerticalNeighbors = melon.verticalNeighborEndRow - melon.verticalNeighborStartRow + 1;
    melon.totalHorizNeighbors = melon.horizNeighborEndCol - melon.horizNeighborStartCol + 1;
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
    
    if (_melon.totalHorizNeighbors == _melon.totalVerticalNeighbors && numRemoved != 0)
    {
        numRemoved /= 2;
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
            [_grid removeObjectAtX:row Y:col fromParent:YES];
        }
    }
}

#pragma mark - Gameover

- (void)checkGameover
{
    // Check if the player runs out of melons.
    if (_melonsLeft <= 1)
    {
        [self gameover];
        _gameOverText.string = @"No more melons left..";
        
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
    _gameOverText.string = @"Board is full!";
}

- (void)gameover
{
    WinPopup *popup = (WinPopup *)[CCBReader load:@"Gameover" owner:self];
    popup.positionType = CCPositionTypeNormalized;
    popup.position = ccp(0.5, 0.5);
    [self addChild:popup];
    
    [self updateHighScore];;
}

- (void)restart
{
     [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

@end