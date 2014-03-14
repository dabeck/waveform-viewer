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
    [self.signalTable setDelegate:self];
    [self.signalTable setDataSource:self];
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (self.files.count >= 1)
	{
		NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
		[self.fileTable selectRowAtIndexPath:ip animated:NO scrollPosition:0];
		[self tableView:self.fileTable didSelectRowAtIndexPath:ip];
	}
}

- (void) setupView
{
    // segment control
    [self.segmentedControl setTitle:@"File" forSegmentAtIndex:0];
    [self.segmentedControl setTitle:@"URL" forSegmentAtIndex:1];
    self.segmentedControl.selectedSegmentIndex = 0;
    [self segmentControlChangedValue:self.segmentedControl];
    
    // url field
    [self.urlField setHidden:YES];
    
    // file selection menu
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:[self applicationInboxDirectory] error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.vcd'"];
    self.files = [dirContents filteredArrayUsingPredicate:fltr];
    self.selection = [self.files firstObject];
	
    CALayer *layer = self.fileTable.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius: 4.0];
    [layer setBorderWidth:1.0];
    
    // signal selection menu
    CALayer *signalLayer = self.signalTable.layer;
    [signalLayer setMasksToBounds:YES];
    [signalLayer setCornerRadius: 4.0];
    [signalLayer setBorderWidth:1.0];
}

/**
 *  Loads the signals from downloaded VCD file
 *
 *  URLs:
 *  https://www.uni-kassel.de/eecs/fileadmin/datas/fb16/Fachgebiete/Digitaltechnik/ipadlab/very_simple.vcd
 *  https://www.uni-kassel.de/eecs/fileadmin/datas/fb16/Fachgebiete/Digitaltechnik/ipadlab/simple.vcd
 *  https://www.uni-kassel.de/eecs/fileadmin/datas/fb16/Fachgebiete/Digitaltechnik/ipadlab/pong.vcd
 */
- (void)loadSignals:(NSURL *)path
{
    [VCD loadWithURL:path
			callback:^(VCD *vcd)
					 {
						 if(vcd == nil)
						 {
							 NSLog(@"VCD Parsing Error!");
							 return;
						 }
						 else
						 {
							 [self.signalTable setHidden:NO];
						 }
						 
						 [self reloadSignalTable:vcd];
					 }
	 ];
}

- (void)reloadSignalTable:(VCD *)vcd
{
    self.signals = [vcd signals];
    self.signalNames = [[NSMutableArray alloc] init];
	
    for (VCDSignal *newSig in [self.signals allValues])
    {
        [self.signalNames addObject:[newSig name]];
    }
    [self.signalTable reloadData];
}

- (NSString *)applicationInboxDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths firstObject] : nil;
		
    return [NSString stringWithFormat:@"%@/Inbox", basePath];
}

#pragma mark - TableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.fileTable)
	{
        return self.files.count;
    }
	else if (tableView == self.signalTable)
	{
        return self.signalNames.count;
    }
	
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.fileTable)
	{
        static NSString *CellIdentifier = @"FileCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = [self.files objectAtIndex:indexPath.row];
        return cell;
    }
	else if (tableView == self.signalTable)
	{
        static NSString *CellIdentifier = @"SignalCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = [self.signalNames objectAtIndex:indexPath.row];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        return cell;
    }
    return nil;
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.fileTable)
	{
		[self.fileTable deselectRowAtIndexPath:self.lastIndexPath animated:NO];
		
        NSString *path = [NSString stringWithFormat:@"%@/%@", [self applicationInboxDirectory], [self.files objectAtIndex:indexPath.row]];
        [self loadSignals:[[NSURL alloc] initFileURLWithPath:path isDirectory:false]];
		
    }
	else if (tableView == self.signalTable)
	{
		UITableViewCell *cell = [self.signalTable cellForRowAtIndexPath:indexPath];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
			[self.signalNames removeObject:cell.textLabel.text];
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			[self.signalNames addObject:cell.textLabel.text];
		}
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.fileTable)
	{
        self.lastIndexPath = indexPath;
    }
	else if (tableView == self.signalTable)
	{
        
    }
}

#pragma mark - Actions

- (IBAction)btnDoneTapped:(id)sender
{
    NSMutableDictionary *signal_copy = [[NSMutableDictionary alloc] initWithDictionary:self.signals];
    for (VCDSignal *newSig in [signal_copy allValues])
    {
        NSString *sigName = [newSig name];
		
        if ([self.signalNames indexOfObject:sigName] == NSNotFound)
		{
            [signal_copy removeObjectForKey:sigName];
        }
    }
	
    self.signals = [signal_copy mutableCopy];
    [self.delegate didChooseSignals:self.signals];
}

- (IBAction)segmentControlChangedValue:(id)sender
{
    self.selectionType = [self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex];
    if ([self.selectionType isEqualToString:@"File"])
	{
        [self.urlField setHidden:YES];
        [self.fileTable setHidden:NO];
        [self.signalTable setHidden:NO];
        [self.parseUrlButton setHidden:YES];
		//
		//        if (self.signalNames != nil)
		//		{
		//            [self.fileTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:0];
		////            [self loadSignals];
		//        }
    }
	else
	{
        [self.urlField setHidden:NO];
        [self.fileTable setHidden:YES];
        [self.signalTable setHidden:YES];
        [self.parseUrlButton setHidden:NO];
    }
}

- (IBAction)btnOkTapped:(id)sender
{
	[self.urlField endEditing:YES];
    [self loadSignals:[NSURL URLWithString:self.urlField.text]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
