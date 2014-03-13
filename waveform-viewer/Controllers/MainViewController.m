//
//  MainViewController.m
//  waveform-viewer
//
//  Created by Daniel Becker on 28.02.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()
{
    NSMutableDictionary *visibleSignals;
    NSInteger maxTime;
    CPTPlotRange *xRange;
    CPTPlotRange *yRange;
    NSInteger visibleSignalsCount;
}

@end

@implementation MainViewController

#pragma mark - Initialization and teardown

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tblView setDelegate:self];
    [self.tblView setDataSource:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadExternalFile:)
                                                 name:@"openVCDDataFile" object:nil];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	
    if (!self.parseSelection)
	{
        [self performSegueWithIdentifier:@"modalIdent" sender:self];
    }
	else
	{
        [self loadSignals];
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
    [self.graph removeFromSuperlayer];
	visibleSignals = nil;
	
    [self setupGraph];
    [self constructScatterPlot];
}

- (void)loadExternalFile:(NSNotification*)notification {
	NSURL *selectedFile = [notification object];

	NSLog(@"%@", selectedFile);
	self.parseSelection = [selectedFile absoluteString];
	[self dismissViewControllerAnimated:NO completion:nil];
	[self.graph removeFromSuperlayer];
	[self loadSignals];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.signals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	cell.textLabel.text = [[self.signals allValues][indexPath.row] name];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(UIInterfaceOrientationIsLandscape(orientation)){
        return CELL_HEIGHT;
    }
    else{
        return CELL_HEIGHT_PORT;
    }
}

#pragma mark - ScrollView delegate
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//	if (!decelerate)
//	{
//		[self.graph removeFromSuperlayer];
//		
//		[self setupGraph];
//		[self constructScatterPlot];
//	}
//}
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//	[self.graph removeFromSuperlayer];
//	
//    [self setupGraph];
//    [self constructScatterPlot];
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self.graph removeFromSuperlayer];
	
	[self setupGraph];
	[self constructScatterPlot];
    NSLog(@"%i",self.tblView.visibleCells.count);
}

#pragma mark - VCD Loading & Parsing

/**
 *  Loads the signals from the selected VCD file
 */
- (void)loadSignals
{
    if ([self.parseSelection  rangeOfString:@"http://"].location == NSNotFound && [self.parseSelection rangeOfString:@"file://"].location == NSNotFound)
	{
        self.parseSelection = [self.parseSelection stringByReplacingOccurrencesOfString:@".vcd" withString:@""];
        NSString* filePath = [[NSBundle mainBundle] pathForResource:self.parseSelection ofType:@"vcd"];
		
        [VCD loadWithPath:filePath callback:^(VCD *vcd) {
            if(vcd == nil) {
                NSLog(@"VCD Parsing Error!");
                return;
            }
            self.signals = [vcd signals];
            [self setup];
        }];
    }
	else if ([self.parseSelection  rangeOfString:@"http://"].location != NSNotFound || [self.parseSelection  rangeOfString:@"file://"].location != NSNotFound)
	{
        [VCD loadWithURL:[NSURL URLWithString:self.parseSelection] callback:^(VCD *vcd) {
            if(vcd == nil)
			{
                NSLog(@"VCD Parsing Error!");
                return;
            }
            self.signals = [vcd signals];
            [self setup];
        }];
    }
	else
	{
		NSLog(@"Something went wrong Error!");
		return;

	}
}

/**
 *  Setup the plot values and prepare some plotting defaults
 */
- (void) setup
{
	maxTime = 0;

    [self.tblView reloadData];
    
    for (VCDSignal *newSig in [self.signals allValues])
	{
        for (VCDValue *newValue in [newSig valueForKey:@"_values"])
		{
            if (maxTime < [newValue time])
			{
                maxTime = [newValue time];
            }
        }
    }
	
	// Another loop to draw the lines till the end
	for (VCDSignal *newSig in [self.signals allValues])
	{
		NSInteger maxSigTime = 0;
		char lastValue = '\0';
		
		for (VCDValue *newValue in [newSig valueForKey:@"_values"])
		{
            if (maxTime > [newValue time])
			{
                maxSigTime = [newValue time];
				lastValue = *[newValue cValue];
            }
        }
		
		if (maxSigTime < maxTime) {
			[newSig addValue:&lastValue AtTime:maxTime];
		}
	}
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(UIInterfaceOrientationIsLandscape(orientation)){
        if (self.tblView.visibleCells.count > MAX_VISIBLE_CELLS)
        {
            visibleSignalsCount = self.tblView.visibleCells.count;
        }
        else
        {
            visibleSignalsCount = MAX_VISIBLE_CELLS;
        }
    }
    else{
        if (self.tblView.visibleCells.count > MAX_VISIBLE_CELLS_PORT)
        {
            visibleSignalsCount = self.tblView.visibleCells.count;
        }
        else
        {
            visibleSignalsCount = MAX_VISIBLE_CELLS_PORT;
        }
    }
	
	xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxTime)];
	yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(visibleSignalsCount)];
	
	
	[self setupGraph];
	[self constructScatterPlot];
}

#pragma mark - Plot construction methods

- (void)setupGraph
{
	// Create graph from theme
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.scatterPlotView.bounds];
	self.graph.plotAreaFrame.masksToBorder = YES;
	
	//Very VERY VERY!!! Important property to reduce memory usage
	[self.graph setMasksToBorder:YES];
	
	self.scatterPlotView.hostedGraph = self.graph;
	
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainBlackTheme];
    [self.graph applyTheme:theme];
	
    self.graph.paddingLeft   = 0.0;
    self.graph.paddingTop    = 0.0;
    self.graph.paddingRight  = 0.0;
    self.graph.paddingBottom = 0.0;
	
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
	
    plotSpace.allowsUserInteraction = YES;
    
    plotSpace.delegate = self;
    
    plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxTime)];
    plotSpace.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(visibleSignalsCount)];
    
    plotSpace.xRange = xRange;
    plotSpace.yRange = yRange;

    NSInteger xInterval = 10;
    if(maxTime >= 100000){
        xInterval = 10000;
    }
    else if(maxTime >= 10000){
        xInterval = 1000;
    }
    else if(maxTime >= 400){
        xInterval = 100;
    }
	
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle new];// Create graph from theme
	lineStyle.lineColor  = [CPTColor darkGrayColor];
	lineStyle.lineWidth  = 0.5f;
	
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x				= axisSet.xAxis;
    x.majorIntervalLength       = CPTDecimalFromDouble(xInterval);
	x.majorTickLength			= self.graph.bounds.size.height * 2;
	x.majorTickLineStyle		= lineStyle;
    x.minorTicksPerInterval     = 0;
	x.labelOffset				= -(self.graph.bounds.size.height * 2);
	x.labelingPolicy			= CPTAxisLabelingPolicyFixedInterval;
	
	CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength       = CPTDecimalFromDouble(1);
    y.minorTicksPerInterval     = 1;
	y.majorTickLineStyle		= lineStyle;
	y.majorTickLength			= INT16_MAX;
	
    
    [self.tblView reloadData];
	
}

/**
 * Constructs a plot for every single
 * signal that is currently visible
 */
- (void)constructScatterPlot
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(UIInterfaceOrientationIsLandscape(orientation)){
        if (self.tblView.visibleCells.count < MAX_VISIBLE_CELLS)
        {
            self.countPlot = (MAX_VISIBLE_CELLS - self.tblView.visibleCells.count) - 1;
        }
        else{
            self.countPlot = -1;
        }
    }
    else{
        if (self.tblView.visibleCells.count < MAX_VISIBLE_CELLS_PORT)
        {
            self.countPlot = (MAX_VISIBLE_CELLS_PORT - self.tblView.visibleCells.count) - 1;
        }
        else{
            self.countPlot = -1;
        }
    }

    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];// Create graph from theme
	lineStyle.lineColor  = [CPTColor redColor];

	
    visibleSignals = [NSMutableDictionary new];
	
    // Create a blue plot area
    for (NSString* name in [self.signals allKeys])
	{
        for (UITableViewCell *cell in (self.tblView.visibleCells))
		{
            if ([cell.textLabel.text isEqualToString:name])
			{
				CGRect rectInTableView = [self.tblView rectForRowAtIndexPath:[self.tblView indexPathForCell:cell]];
				NSLog(@"%@ - %f",name, rectInTableView.origin.y);

                [visibleSignals addEntriesFromDictionary:@{ name : self.signals[name] }];
				
                CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
                boundLinePlot.identifier = name;
                boundLinePlot.dataLineStyle = lineStyle;
                boundLinePlot.dataSource     = self;
                boundLinePlot.cachePrecision = CPTPlotCachePrecisionAuto;
                boundLinePlot.interpolation  = CPTScatterPlotInterpolationStepped;
                [self.graph addPlot:boundLinePlot];
            }
            continue;
        }
    }
}

#pragma mark - CorePlot dataSource

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	// For each line the number of different values e.g. 0,1 = 2 ...
    NSArray *allVal = [[visibleSignals objectForKey:(NSString*)plot.identifier] valueForKey:@"_values"];
	return allVal.count;
}


- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSString *plotIdent = (NSString *) plot.identifier;
	
    if (![plotIdent isEqualToString:self.currentIdent])
	{
        self.countPlot++;
        self.currentIdent = plotIdent;
    }
	
    
    VCDSignal *newSig = [visibleSignals objectForKey:plotIdent];
	NSArray *allVal = [newSig valueForKey:@"_values"];
    VCDValue * newValue = [allVal objectAtIndex:index];
	
	
	if (fieldEnum == CPTScatterPlotFieldY)
	{
		NSNumber *number = [NSNumber new];
		NSString *newValueString = newValue.value;
		number = [NSNumber numberWithInteger:[newValueString integerValue]];

		
		if (![newValueString isEqualToString:@"x"] && ![newValueString isEqualToString:@"z"] && [number isEqualToNumber:@1])
		{
			number = @(self.countPlot + 0.8);
		}
		else if (![newValueString isEqualToString:@"x"] && ![newValueString isEqualToString:@"z"] && [number isEqualToNumber:@0])
		{
			number = @(self.countPlot + 0.2);
		}
		else if ([newValueString isEqualToString:@"x"] || [newValueString isEqualToString:@"z"])
		{
			number = @(self.countPlot + 0.4);
		}
		//NSLog(@"Signal: %@  -- X: %ld Y: %@ RESULT Y: %@", newSig.name, (long)newValue.time, newValue.value, number);
		
		return number;
	}
	
	if (fieldEnum == CPTScatterPlotFieldX)
	{
		return [NSNumber numberWithInteger:[newValue time]];
	}
	
    return nil;
}

#pragma mark - CorePlot delegates
- (CPTPlotRange *)plotSpace:(CPTPlotSpace *)space
	  willChangePlotRangeTo:(CPTPlotRange *)newRange
			  forCoordinate:(CPTCoordinate)coordinate
{
	
    CPTPlotRange *updatedRange = nil;
	
    switch (coordinate)
	{
		case CPTCoordinateX:
			if (newRange.locationDouble < 0.0F)
			{
				CPTMutablePlotRange *mutableRange = [newRange mutableCopy];
				mutableRange.location = CPTDecimalFromFloat(0.0);
				updatedRange = mutableRange;
                xRange = updatedRange;
			}
			else {
				updatedRange = newRange;
                xRange = updatedRange;
			}
			break;
		case CPTCoordinateY:
			updatedRange = ((CPTXYPlotSpace *)space).globalYRange;
			break;
		default:
			break;
    }
	
    return updatedRange;
}

#pragma mark - DeviceRotation delegate

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.graph removeFromSuperlayer];
	[self setup];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"modalIdent"])
	{
        UINavigationController *controller = [segue destinationViewController];
        
        SettingsViewController *svc = [[controller childViewControllers] firstObject];
        svc.delegate = self;
    }
}

#pragma mark - SettingsViewController delegate
- (void)didChooseValue:(NSString *)value
{
	self.parseSelection = value;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
    [self loadSignals];
}

@end
