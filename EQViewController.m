//
//  EQViewController.m
//  EQPlayer
//
//  Created by AllenHsu on 2013/12/25.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import "EQViewController.h"

@interface EQViewController ()

@end

@implementation EQViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithPlayer:(EQPlayer *)eqplayer
{
    self = [super init];
    if (self) {
        player = eqplayer;
        player.delegate = self;
    
        db = [[EQDB alloc] init];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    sliders = [[NSMutableArray alloc] init];
    labels = [[NSMutableArray alloc] init];
    frequency = [player getFrequencyBand];
    
    songTime.text = [NSString stringWithFormat:@"0sec"];
    
    for(int i=0; i<[frequency count]; i++)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(138, 0+i*50, 150, 21)];
        
        label.text = [NSString stringWithFormat:@"%dHZ:0",[[frequency objectAtIndex:i] integerValue]];
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 25+ i*50, 284, 23)];
        [eqbars addSubview:label];
        [eqbars addSubview:slider];
        slider.minimumValue = 0.0f;
        slider.maximumValue = 50.0f;
        slider.value = 0.0f;
        slider.tag = i;
        [slider addTarget:self action:@selector(setEQValue:) forControlEvents:UIControlEventValueChanged];
        [sliders addObject:slider];
        [labels addObject:label];
    }
    CGRect frame = eqbars.frame;
    frame.size.height = 600;
    eqbars.contentSize = frame.size;
    
    
    MPMediaItem *song = [player getSongInfo];
    songName.text = [NSString stringWithFormat:@"%@",[song valueForProperty:MPMediaItemPropertyTitle]];
    
    
    
    // set info scollview content size
    frame = info.frame;
    frame.size.height = 300;
    info.contentSize = frame.size;
    
    //[self restore:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





#pragma IBACTION_SE


-(void)setEQValue:(UISlider *)sender;
{
    //NSLog(@"tag:%d, value:%f",sender.tag,sender.value);
    UILabel* label = [labels objectAtIndex:sender.tag];
    int i = [[frequency objectAtIndex:sender.tag] integerValue];
    label.text = [NSString stringWithFormat:@"%dHZ:%f",i,sender.value];
    [player setEQ:sender.tag gain:sender.value];
}

-(IBAction)reset:(id)sender
{
    // reset the eq value
    for (int i=0; i<[frequency count]; i++) {
        // reset the label text to 0hz
        UILabel* label = [labels objectAtIndex:i];
        int fq = [[frequency objectAtIndex:i] integerValue];
        label.text = [NSString stringWithFormat:@"%dHZ:0",fq];
        // reset the equalizer for each band
        UISlider *slider = [sliders objectAtIndex:i];
        slider.value = 0;
        [player setEQ:i gain:0];
    }
    
}

- (void)updateCurrentTime:(float)time
{

    dispatch_async(dispatch_get_main_queue(), ^{
		//Code here to which needs to update the UI in the UI thread goes here
        //NSLog(@"update time in U %d sec",(int)time);
        songTime.text = [NSString stringWithFormat:@"%d sec",(int)time];
        songProgress.maximumValue = player.duration;
        songProgress.minimumValue = 0;
        songProgress.value = time;
        
	});
    
    
}

- (IBAction)setTime:(UISlider *)sender
{
    [player setTime:sender.value];
}

- (IBAction)restore:(id)sender
{
    MPMediaItem *item = [player getSongInfo];
    NSDictionary *dic = [db retrieveSet:[NSString stringWithFormat:@"%@",[item valueForProperty:MPMediaItemPropertyPersistentID]]];
    
    NSString *eqSet = [dic objectForKey:@"eqset"];
    NSString *type = [dic objectForKey:@"songtype"];
    
    info.text = eqSet;
    songType.text = type;
    
    NSArray *set = [eqSet componentsSeparatedByString:@"\n"];
    int i=0;
    for(NSString *eq in set)
    {
        NSLog(@"eq %@",eq);
        if( [eq length] < 2){
            continue;
        }
        float gainValue = [[[eq componentsSeparatedByString:@":"] objectAtIndex:1] floatValue];
        [player setEQ:i gain:gainValue];
        UISlider *slider = [sliders objectAtIndex:i];
        slider.value = gainValue;
        i++;
    }
    
}

- (IBAction)save:(id)sender
{

    
    MPMediaItem *item = [player getSongInfo];
    
    NSString *EQSet = @"";
    for(UILabel *label in labels){
        EQSet = [EQSet stringByAppendingFormat:@"%@\n",label.text];
    }
    
    
    NSLog(@"saving song : id %@\n name %@",[item valueForProperty:MPMediaItemPropertyPersistentID],[item valueForProperty:MPMediaItemPropertyTitle]);
    NSLog(@"type %@\n set %@",[NSString stringWithFormat:@"%@",songType.text], EQSet);
    
    
    [db saveSet:[NSString stringWithFormat:@"%@",[item valueForProperty:MPMediaItemPropertyPersistentID]]
               :[item valueForProperty:MPMediaItemPropertyTitle]
               :[NSString stringWithFormat:@"%@",songType.text]
               :EQSet];
    
    
    [self restore:nil];


}


- (IBAction)done:(id)sender
{
    [player setDelegate:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
