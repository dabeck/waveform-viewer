//
//  MainViewController.m
//  waveform-viewer
//
//  Created by Daniel Becker on 28.02.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController () {
	CGPoint actualPosition;
}

@end

@implementation MainViewController

#pragma mark -
#pragma mark Initialization and teardown

-(void)viewDidLoad
{
    [super viewDidLoad];
    [tblView setDelegate:self];
    [tblView setDataSource:self];

	actualPosition = CGPointMake(0, 0);
    [self loadSignals];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	//scatterPlotView.frame = self.view.bounds;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self setScreenOrientation];
}

-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Return the number of rows in the section.
    return self.signals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	cell.textLabel.text = [[self.signals allValues][indexPath.row] name];
	
    return cell;
}

//load Signals from vcd file
- (void)loadSignals{
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"vcd"];
    
    [VCD loadWithPath:filePath callback:^(VCD *vcd) {
        
        
        if(vcd == nil) {
            NSLog(@"VCD Parsing Error!");
            return;
        }
        self.signals = [vcd signals];

        // ...
        //refresh Data ofr Tableview
        [tblView reloadData];
        
        
        
        //resize the views
        [self setupGraph];
        [self setScreenOrientation];
        
        
        for (VCDSignal *sig in [[vcd signals] allValues]) {
            [self constructScatterPlot:[sig name]];
        }
    }];
    
    
}


#pragma mark -
#pragma mark Plot construction methods

- (void)setupGraph{
    NSInteger coordinate = self.signals.count * -1;
    // Create graph from theme
    graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:theme];
    scatterPlotView.hostedGraph = graph;
    
	
    graph.paddingLeft   = 10.0;
    graph.paddingTop    = 0.0;
    graph.paddingRight  = 10.0;
    graph.paddingBottom = 0.0;
	
    
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    
    plotSpace.delegate = self;
    
    plotSpace.globalXRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(600)]; //TODO: calc max value
    plotSpace.globalYRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.values.count) length:CPTDecimalFromDouble(coordinate)];
    
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(10)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.signals.count) length:CPTDecimalFromDouble(coordinate)];
	
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(1.0);
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
    x.minorTicksPerInterval       = 2;
    NSArray *exclusionRanges = [NSArray arrayWithObjects:
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(1.99) length:CPTDecimalFromDouble(0.02)],
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.99) length:CPTDecimalFromDouble(0.02)],
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(2.99) length:CPTDecimalFromDouble(0.02)],
                                nil];
    x.labelExclusionRanges = exclusionRanges;
	
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromDouble(1.0);
    y.minorTicksPerInterval       = 2;
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
    exclusionRanges               = [NSArray arrayWithObjects:
                                     [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(1.99) length:CPTDecimalFromDouble(0.02)],
                                     [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.99) length:CPTDecimalFromDouble(0.02)],
                                     [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(3.99) length:CPTDecimalFromDouble(0.02)],
                                     nil];
    y.labelExclusionRanges = exclusionRanges;
}


- (void)constructScatterPlot: (NSString*)identifier
{
    
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];// Create graph from theme
    
    // Create a blue plot area
    CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
    boundLinePlot.identifier = identifier;
	
    lineStyle            = [boundLinePlot.dataLineStyle mutableCopy];
    lineStyle.miterLimit = 1.0;
    lineStyle.lineWidth  = 1.0;
    lineStyle.lineColor  = [CPTColor redColor];
	
    boundLinePlot.dataSource     = self;
    boundLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
    boundLinePlot.interpolation  = CPTScatterPlotInterpolationStepped;
    [graph addPlot:boundLinePlot];
	
    // Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor redColor];
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSArray *allVal = [[self.signals objectForKey:plot.identifier] valueForKey:@"_values"];
	return allVal.count ;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *plotIdent = (NSString *) plot.identifier;
    if (![self.currentIdent isEqual:plotIdent]) {
        countPlot++;
        self.currentIdent = plotIdent;
    }
    
    NSArray *allVal = [[self.signals objectForKey:plotIdent] valueForKey:@"_values"];
    VCDValue * newValue = [allVal objectAtIndex:index];
    if ( fieldEnum == CPTScatterPlotFieldY ) {
        NSString *character = [NSString stringWithUTF8String:[newValue cValue]];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *number = [f numberFromString:character];
        
        if([number isEqualToNumber:[NSNumber numberWithInt:1]]){
            number = [NSNumber numberWithFloat:(countPlot + 0.2)];
            return  number;
        }
        else if([number isEqualToNumber:[NSNumber numberWithInt:0]]){
            number = [NSNumber numberWithFloat:(countPlot + 0.8)];
            return  number;
        }
        else if([character isEqualToString:@"x"]){
            number = [NSNumber numberWithFloat:(countPlot + 0.5)];
            return  number;
        }
        else if([character isEqualToString:@"z"]){
            number = [NSNumber numberWithFloat:(countPlot + 0.5)];
            return  number;
        }
        
        return number;
    }
    if ( fieldEnum == CPTScatterPlotFieldX ) {
        return [NSNumber numberWithInteger:[newValue time]];
    }
    return nil;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    static CPTMutableTextStyle *text = nil;
	
    if ( !text ) {
        text       = [[CPTMutableTextStyle alloc] init];
        text.color = [CPTColor blackColor];
    }
	
    CPTTextLayer *newLayer = nil;
    
    if ( [plot isKindOfClass:[CPTScatterPlot class]] ) {
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%lu", (unsigned long)index] style:text];
    }
	
    return newLayer;
}

- (CPTPlotRange *)plotSpace:(CPTPlotSpace *)space
	   willChangePlotRangeTo:(CPTPlotRange *)newRange
			   forCoordinate:(CPTCoordinate)coordinate {
	
    CPTPlotRange *updatedRange = nil;
	
    switch (coordinate)
	{
		case CPTCoordinateX:
			if (newRange.locationDouble < 0.0F) {
				CPTMutablePlotRange *mutableRange = [newRange mutableCopy];
				mutableRange.location = CPTDecimalFromFloat(0.0);
				updatedRange = mutableRange;
			}
			else {
				updatedRange = newRange;
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

-(void) setScreenOrientation{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    float screenWidth = self.view.frame.size.width;
    float screenHeight = self.view.frame.size.height;
    
    if ( UIInterfaceOrientationIsLandscape(orientation) ) {
        NSInteger height = self.signals.count * CELL_SIZE_LANDSCAPE;
        // Move the plots into place for portrait
        //mainView.frame = self.view.bounds;
        //tblView.frame = self.view.bounds;
        //scrollView.frame = self.view.bounds;
        scatterPlotView.frame = self.view.bounds;
        int widhtttt = mainView.frame.size.width;
        int heightttt = mainView.frame.size.height;
        [mainView setFrame:CGRectMake(0,0,screenWidth, screenHeight)];
        widhtttt = mainView.frame.size.width;
        heightttt = mainView.frame.size.height;
        [scatterPlotView setFrame: CGRectMake(120,0,scatterPlotView.frame.size.width, height)];
        [tblView setFrame:CGRectMake(0,0,120, height)];
        [coordinateView setFrame:CGRectMake(0,screenWidth-CELL_SIZE_LANDSCAPE,screenWidth, height)];
    }
    else {
        NSInteger height = self.signals.count * 48;
        // Move the plots into place for landscape
        //mainView.frame = self.view.bounds;
        //scatterPlotView.frame = self.view.bounds;
        [mainView setFrame:CGRectMake(0,0,screenWidth, screenHeight)];
        //tblView.frame = self.view.bounds;
        //scrollView.frame = self.view.bounds;
        scatterPlotView.frame = self.view.bounds;
        int tbl = tblView.frame.size.height;
        NSLog(@"%i",tbl);
        tbl = tblView.frame.size.height;
        NSLog(@"%i",tbl);

        [scatterPlotView setFrame: CGRectMake(120,0,scatterPlotView.frame.size.width, height)];
        [tblView setFrame:CGRectMake(0,0,120, height)];
        [coordinateView setFrame:CGRectMake(0,screenHeight-48,screenWidth, height)];
    }
}
@end
