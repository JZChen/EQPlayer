//
//  ViewController.m
//  EQPlayer
//
//  Created by Wildchild on 13/12/23.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    player = [[EQPlayer alloc] init];
    //[player startAUGraph];
    

    
}

- (IBAction)selectSong:(id)sender
{
    MPMediaPickerController *picker =
    [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
	
	picker.delegate						= self;
	picker.allowsPickingMultipleItems	= NO;
	picker.prompt						= NSLocalizedString (@"AddSongsPrompt", @"Prompt to user to choose some songs to play");
	
	[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault animated:YES];
    
	[self presentViewController:picker animated:YES completion:^{
        
        
    }];
}

// Responds to the user tapping Done after choosing music.
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection {
    /*
    for(int i=0;i<[mediaItemCollection count];i++)
    {
        [mediaCollection addObject:[[[mediaItemCollection items] objectAtIndex:i] retain]];
    }
    */
	[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated:YES];
    [mediaPicker dismissViewControllerAnimated:YES completion:^{
        EQViewController *eqview = [[EQViewController alloc] initWithPlayer:player];
        [player setMediaItem:[[mediaItemCollection items] objectAtIndex:0]];
        [self presentViewController:eqview animated:YES completion:nil];
    }];
    
}


// Responds to the user tapping done having chosen no music.
- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {
    
	[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated:YES];
    [mediaPicker dismissViewControllerAnimated:YES completion:^{
    }];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
