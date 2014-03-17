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
    NSMutableArray *allValues;
    CPTXYPlotSpace *plotSpace;
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
    
        return self.actualHeight;
}

#pragma mark - ScrollView delegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{

    
//	UITableView *tv = (UITableView*)scrollView;
//	NSIndexPath *indexPathOfTopRowAfterScrolling = [tv indexPathForRowAtPoint:*targetContentOffset];
//	CGRect rectForTopRowAfterScrolling = [tv rectForRowAtIndexPath:indexPathOfTopRowAfterScrolling];
//	targetContentOffset->y=rectForTopRowAfterScrolling.origin.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    
//    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.signals.count * self.actualHeight);
//    self.scatterPlotView.frame = CGRectMake(0, 0, self.scatterPlotView.frame.size.width, self.signals.count * self.actualHeight);
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
        self.actualHeight = CELL_HEIGHT;
        self.maxCellHeight = MAX_VISIBLE_CELLS;
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
        self.actualHeight = CELL_HEIGHT_PORT;
        self.maxCellHeight = MAX_VISIBLE_CELLS_PORT;
    }
	
	xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxTime)];
	yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.signals.count * self.actualHeight) length:CPTDecimalFromDouble(self.maxCellHeight)];
	
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.signals.count * self.actualHeight);

    
	[self setupGraph];
	[self constructScatterPlot];
}

#pragma mark - Plot construction methods

- (void)setupGraph
{
	// Create graph from theme
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.scatterPlotView.frame];
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
    plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
	
    plotSpace.allowsUserInteraction = YES;
    
    plotSpace.delegate = self;
    
    plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxTime)];
    if(self.signals.count < 14){
        plotSpace.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(self.maxCellHeight)];
    }
    else{
        plotSpace.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(self.signals.count)];
    }
    
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
	//x.labelOffset				= -(self.graph.bounds.size.height * 2);
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
    if (self.tblView.visibleCells.count < self.maxCellHeight)
    {
        self.countPlot = (self.maxCellHeight - self.tblView.visibleCells.count);
    }
    else{
        self.countPlot = 0;
    }
 
    
    
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];// Create graph from theme
	lineStyle.lineColor  = [CPTColor greenColor];

    CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
    boundLinePlot.identifier = @"defined";
    boundLinePlot.dataLineStyle = lineStyle;
    boundLinePlot.dataSource     = self;
    boundLinePlot.cachePrecision = CPTPlotCachePrecisionAuto;
    boundLinePlot.interpolation  = CPTScatterPlotInterpolationStepped;
    [self.graph addPlot:boundLinePlot];
    
    
}



#pragma mark - CorePlot dataSource

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	// For each line the number of different values e.g. 0,1 = 2 ...
    allValues = [NSMutableArray new];
    
    for(VCDSignal *newSig in [[self.signals allValues] reverseObjectEnumerator]){
        for(VCDValue *newVal in [newSig valueForKey:@"_values"]){
            [allValues addObject: newVal];
        }
        VCDValue *next = [[VCDValue alloc]initWithValue:"q" AtTime:0];
        [allValues addObject:next];
    }
    //self.countPlot = -1;
	return allValues.count;
}


- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    //VCDSignal *newSig = [allValues objectAtIndex:index];
    VCDValue *newValue = [allValues objectAtIndex:index];
    NSNumber *number = [NSNumber new];
    
    
    if (fieldEnum == CPTScatterPlotFieldY)
    {
        if([[newValue value]isEqualToString:@"q"]){
            self.countPlot++;
            return nil;
        }
        
        NSString *newValueString = [newValue value];
        number = [NSNumber numberWithInteger:[newValueString integerValue]];

        
        if (![newValueString isEqualToString:@"x"] && ![newValueString isEqualToString:@"z"] && [number isEqualToNumber:@1])
        {
            number = @(self.countPlot + 0.8);
        }
        else if (![newValueString isEqualToString:@"x"] && ![newValueString isEqualToString:@"z"] && [number isEqualToNumber:@0])
        {
            //return nil;
            number = @(self.countPlot + 0.2);
        }
        else if ([newValueString isEqualToString:@"x"])
        {
            //return nil;
            number = @(self.countPlot + 0.4);
        }
        else if ([newValueString isEqualToString:@"z"])
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
//- (CPTPlotRange *)plotSpace:(CPTPlotSpace *)space
//	  willChangePlotRangeTo:(CPTPlotRange *)newRange
//			  forCoordinate:(CPTCoordinate)coordinate
//{
//	
//    CPTPlotRange *updatedRange = nil;
//	
//    switch (coordinate)
//	{
//		case CPTCoordinateX:
//			if (newRange.locationDouble < 0.0F)
//			{
//				CPTMutablePlotRange *mutableRange = [newRange mutableCopy];
//				mutableRange.location = CPTDecimalFromFloat(0.0);
//				updatedRange = mutableRange;
//                xRange = updatedRange;
//			}
//			else {
//				updatedRange = newRange;
//                xRange = updatedRange;
//			}
//			break;
//		case CPTCoordinateY:{
//			updatedRange = ((CPTXYPlotSpace *)space).globalYRange;
//			break;
//        }
//		default:
//			break;
//    }
//	
//    return updatedRange;
//}

#pragma mark - DeviceRotation delegate

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(UIInterfaceOrientationIsLandscape(fromInterfaceOrientation)){
        self.actualHeight = CELL_HEIGHT;
    }
    else{
        self.actualHeight = CELL_HEIGHT_PORT;
    }
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
