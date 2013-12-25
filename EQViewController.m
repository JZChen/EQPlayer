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
    //[eq getFrequency];
    
    for(int i=0; i<[frequency count]; i++)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(138, 0+i*50, 150, 21)];
        
        label.text = [NSString stringWithFormat:@"%dHZ:",[[frequency objectAtIndex:i] integerValue]];
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 25+ i*50, 284, 23)];
        [eqbars addSubview:label];
        [eqbars addSubview:slider];
        slider.minimumValue = -25.0f;
        slider.maximumValue = 25.0f;
        slider.value = 0.0f;
        slider.tag = i;
        [slider addTarget:self action:@selector(setEQValue:) forControlEvents:UIControlEventValueChanged];
        [sliders addObject:slider];
        [labels addObject:label];
    }
    CGRect frame = eqbars.frame;
    frame.size.height = 600;
    eqbars.contentSize = frame.size;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





#pragma IBACTION_SEC


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
        [player setEQ:i gain:0];
        
    }
    
}

- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
