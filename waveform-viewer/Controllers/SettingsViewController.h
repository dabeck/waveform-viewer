//
//  SettingsViewController.h
//  waveform-viewer
//
//  Created by Daniel Becker on 12.03.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SettingsViewControllerDelegate <NSObject>

- (void)didChooseValue:(NSString *)value;

@end

@interface SettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet UITextField *urlField;
@property (strong, nonatomic) IBOutlet UITableView *fileTable;

@property (strong, nonatomic) NSArray *files;
@property (strong, nonatomic) NSIndexPath *lastIndexPath;
@property (strong, nonatomic) NSString *selection;
@property (strong, nonatomic) NSString *selectionType;

@property (nonatomic, assign) id<SettingsViewControllerDelegate> delegate;


- (IBAction)btnDoneTapped:(id)sender;
- (IBAction)changedValue:(id)sender;

@end