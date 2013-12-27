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
    db = [[EQDB alloc] init];

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


- (void)viewDidAppear:(BOOL)animated
{
    content = [NSMutableArray arrayWithArray:[db retrieveAllSet]];
    [tableview reloadData];
}

#pragma mark Table view methods________________________

// To learn about using table views, see the TableViewSuite sample code
//		and Table View Programming Guide for iPhone OS.

- (NSInteger) tableView: (UITableView *) table numberOfRowsInSection: (NSInteger)section {
    
    return [content count];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    
	NSInteger row = [indexPath row];
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"media"];
    
    if( cell == nil ){
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"media"];
        
    }
    
    NSDictionary *dic = [content objectAtIndex:row];
	
	if (dic) {
		cell.textLabel.text = [dic objectForKey:@"songname"];
        cell.detailTextLabel.text = [dic objectForKey:@"songtype"];
	}
    
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	
	return cell;
}

//	 To conform to the Human Interface Guidelines, selections should not be persistent --
//	 deselect the row after it has been selected.
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    NSDictionary *dic = [content objectAtIndex:[indexPath row]];
    NSString *sid = [dic objectForKey:@"songid"];
    
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    
    //int64_t i = atoll([sid UTF8String]);

    
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:sid forProperty:MPMediaItemPropertyPersistentID];
    [query addFilterPredicate:predicate];
    
    MPMediaItem *itemToPass;
    for (MPMediaItem *item in [query items]) {
        NSLog(@"%@",[item valueForProperty:MPMediaItemPropertyTitle]);
        itemToPass = item;
    }
    
    

    EQViewController *eqView = [[EQViewController alloc] initWithPlayer:player];
    [player setMediaItem:itemToPass];
    [player startAUGraph];
    [self presentViewController:eqView animated:YES completion:nil];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSDictionary *dic = [content objectAtIndex:[indexPath row]];
        NSString *sid = [dic objectForKey:@"songid"];
        
        // if the deletion in db works, perform deletion on UI
        if ( [db removeSet:sid]) {
            [content removeObjectAtIndex:[indexPath row]];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
        
        
    }


}



@end
