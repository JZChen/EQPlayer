//
//  EQViewController.h
//  EQPlayer
//
//  Created by AllenHsu on 2013/12/25.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EQPlayer.h"

@interface EQViewController : UIViewController
{
    IBOutlet UILabel *songName,*songTime;
    IBOutlet UISlider *songProgress;
    IBOutlet UIScrollView *info,*eqbars;

    EQPlayer *player;

    NSArray *frequency;
    NSMutableArray *sliders;
    NSMutableArray *labels;

}

- (id)initWithPlayer:(EQPlayer *)eqplayer;


-(IBAction)done:(id)sender;
-(IBAction)reset:(id)sender;
-(void)setEQValue:(UISlider *)sender;

@end
