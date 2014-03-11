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

@implementation MainViewController @synthesize dataForPlot;

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
    return self.values.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [self.values objectAtIndex:indexPath.row];
    return cell;
}

//load Signals from vcd file
- (void)loadSignals{
    NSMutableString *str = [[NSMutableString alloc] init];
    self.values = [NSMutableArray new];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"vcd"];

    [VCD loadWithPath:filePath callback:^(VCD *vcd) {
        if(vcd == nil) {
            NSLog(@"VCD Parsing Error!");
            return;
        }
        self.signals = [vcd signals];
        for (VCDSignal *sig in [[vcd signals] allValues]) {
            [str appendString:[sig name]];
            [str appendString:@": "];
            [self.values addObject:[sig name]];
            for(VCDValue *v = [sig valueAtTime:0]; v != nil; v = [v next]) {
                [str appendString:[v value]];
                [str appendString:@", "];
            }
            [str appendString:@"\n"];
            
        }
        // ...
        //refresh Data ofr Tableview
        [tblView reloadData];
        
        //resize the views
        [self setScreenOrientation];
        [self constructScatterPlot];
    }];
}


#pragma mark -
#pragma mark Plot construction methods

- (void)constructScatterPlot
{
    NSInteger coordinate = self.values.count * -1;
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
	
	plotSpace.globalXRange			= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(100)]; //TODO: get max value
	plotSpace.globalYRange			= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.values.count) length:CPTDecimalFromDouble(coordinate)]; //TODO: get max value

    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(10)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.values.count) length:CPTDecimalFromDouble(coordinate)];

    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(1.0);
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
    x.minorTicksPerInterval       = 2;

    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromDouble(1.0);
    y.minorTicksPerInterval       = 2;
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
	
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
	
    // Create a blue plot area
    CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
    boundLinePlot.identifier = @"BluePlot";
	
    lineStyle            = [boundLinePlot.dataLineStyle mutableCopy];
    lineStyle.miterLimit = 1.0;
    lineStyle.lineWidth  = 3.0;
    lineStyle.lineColor  = [CPTColor blueColor];
	
    boundLinePlot.dataSource     = self;
    boundLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
    boundLinePlot.interpolation  = CPTScatterPlotInterpolationHistogram;
    [graph addPlot:boundLinePlot];
	
    // Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor blackColor];
	
    // Add some initial data
    self.numbValues = [NSMutableArray new];
    NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];

    self.dataForPlot = contentArray;
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return 3 ;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    if ( fieldEnum == CPTScatterPlotFieldY ) {
        return [@[@0.8,@0.2,@0.2] objectAtIndex:index];
    }
    
    if ( fieldEnum == CPTScatterPlotFieldX ) {
        return [@[@0,@1,@2] objectAtIndex:index];
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
        NSInteger height = self.values.count * CELL_SIZE_LANDSCAPE;
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
        NSInteger height = self.values.count * 48;
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
