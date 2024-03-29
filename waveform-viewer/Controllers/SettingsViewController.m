//
//  SettingsViewController.m
//  waveform-viewer
//
//  Created by Daniel Becker on 12.03.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.fileTable setDelegate:self];
    [self.fileTable setDataSource:self];
    [self initObjects];
    [self.fileTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:0];
}

- (void) initObjects
{
    // segment control
    [self.segmentedControl setTitle:@"File" forSegmentAtIndex:0];
    [self.segmentedControl setTitle:@"URL" forSegmentAtIndex:1];
    self.segmentedControl.selectedSegmentIndex = 0;
    [self changedValue:self.segmentedControl];
    
    // url field
    [self.urlField setHidden:YES];
    
    // file selection menu
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.vcd'"];
    self.files = [dirContents filteredArrayUsingPredicate:fltr];
    self.selection = [self.files objectAtIndex:0];

    CALayer *layer = self.fileTable.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius: 4.0];
    [layer setBorderWidth:1.0];
}

#pragma mark - TableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	cell.textLabel.text = [self.files objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selection = [self.files objectAtIndex:indexPath.row];
    [self.fileTable deselectRowAtIndexPath:self.lastIndexPath animated:NO];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.lastIndexPath = indexPath;
}

#pragma mark - Actions

- (IBAction)btnDoneTapped:(id)sender
{
    if (![self.selectionType isEqualToString:@"File"])
	{
        self.selection = self.urlField.text;
    }
    [self.delegate didChooseValue:self.selection];
}

- (IBAction)changedValue:(id)sender
{
    self.selectionType = [self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex];
    if ([self.selectionType isEqualToString:@"File"])
	{
        [self.urlField setHidden:YES];
        [self.fileTable setHidden:NO];
    }
	else
	{
        [self.urlField setHidden:NO];
        [self.fileTable setHidden:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
