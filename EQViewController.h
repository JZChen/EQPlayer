//
//  EQViewController.h
//  EQPlayer
//
//  Created by AllenHsu on 2013/12/25.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EQPlayer.h"
#import "EQDB.h"

@interface EQViewController : UIViewController<EQPlayerDelegate,UITextFieldDelegate>
{
    IBOutlet UILabel *songName,*songTime;
    IBOutlet UISlider *songProgress;
    IBOutlet UIScrollView *eqbars;
    IBOutlet UITextView *info;
    IBOutlet UITextField *songType;

    EQPlayer *player;
    EQDB *db;
    NSArray *frequency;
    NSMutableArray *sliders;
    NSMutableArray *labels;

}

- (id)initWithPlayer:(EQPlayer *)eqplayer;

- (IBAction)done:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)restore:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)setTime:(UISlider *)sender;
- (void)setEQValue:(UISlider *)sender;


// delegate
- (void)updateCurrentTime:(float)time;

@end
