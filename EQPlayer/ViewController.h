//
//  ViewController.h
//  EQPlayer
//
//  Created by Wildchild on 13/12/23.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EQPlayer.h"
#import "EQDB.h"
#import "EQViewController.h"

@interface ViewController : UIViewController<MPMediaPickerControllerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    EQPlayer *player;
    EQDB *db;
    NSMutableArray *content;
    IBOutlet UITableView *tableview;
}

- (IBAction)selectSong:(id)sender;

@end
