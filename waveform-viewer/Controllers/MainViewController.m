//
//  MainViewController.m
//  waveform-viewer
//
//  Created by Daniel Becker on 28.02.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController @synthesize dataForPlot;

#pragma mark -
#pragma mark Initialization and teardown

-(void)viewDidLoad
{
    [super viewDidLoad];
    [tblView setDelegate:self];
    [tblView setDataSource:self];
    ScatterView *scatterView;
    [scatterView setUserInteractionEnabled:YES];
    [scatterView setDelegate:self];
    [scatterPlotView addSubview: scatterView];
    //UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    //[scatterPlotView addGestureRecognizer:panRecognizer];
    [self loadSignals];
    
    
}

- (void)pan:(id)sender {
    UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer*) sender;
    scatterPlotView.center = [recognizer locationInView:scatterPlotView];
    NSLog(@"Pan");
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    // When a touch starts, get the current location in the view
    currentPoint = [[touches anyObject] locationInView:scatterPlotView];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    // Get active location upon move
    CGPoint activePoint = [[touches anyObject] locationInView:self.view];
    
    // Determine new point based on where the touch is now located
    CGPoint newPoint = CGPointMake(self.view.center.x + (activePoint.x - currentPoint.x),
                                   currentPoint.y);
    
    //--------------------------------------------------------
    // Make sure we stay within the bounds of the parent view
    //--------------------------------------------------------
    float midPointX = CGRectGetMidX(self.view.bounds);
    // If too far right...
    if (newPoint.x > self.view.superview.bounds.size.width  - midPointX)
        newPoint.x = self.view.superview.bounds.size.width - midPointX;
    else if (newPoint.x < midPointX)  // If too far left...
        newPoint.x = midPointX;
    
    float midPointY = CGRectGetMidY(self.view.bounds);
    // If too far down...
    /*if (newPoint.y > self.view.superview.bounds.size.height  - midPointY)
        newPoint.y = self.view.superview.bounds.size.height - midPointY;
    else if (newPoint.y < midPointY)  // If too far up...
        newPoint.y = midPointY;
    */
    // Set new center location
    self.view.center = newPoint;
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
-(void) loadSignals{
    NSMutableString *str = [[NSMutableString alloc] init];
    self.values = [NSMutableArray new];
    NSString* filePath = @"/Users/student/Desktop/nida/waveform-viewer Kopie/waveform-viewer/Externals/simple.vcd";
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

-(void)constructScatterPlot
{
    int coordinate = self.values.count*-1;
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
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.5) length:CPTDecimalFromDouble(10)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.values.count) length:CPTDecimalFromDouble(coordinate)];
	
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(0.5);
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
	
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
	
    // Create a blue plot area
    CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
    boundLinePlot.identifier = @"Blue Plot";
	
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
    NSUInteger i;
    NSUInteger i2;
    const char *zero = "0";
    const char *one = "1";
    const char *undef = "x";
    const char *high = "z";
    int time = 0;
    int values = 0;

    
    for (VCDSignal *sig in [self.signals allValues]) {
        for (VCDValue *value in [sig valueForKey:@"_values"]){
            NSNumber *x = [NSNumber numberWithInt:time];
            NSNumber *y;
            char *s = &[value cValue][0];
            if(strcmp(s, zero) == 0){
                NSLog(@"%@",value);
                NSLog(@"0");
                NSLog(@"%s value", [value cValue]);
                y = [NSNumber numberWithFloat:(values + 0.2)];
            }
            if(strcmp(s, one) == 0){
                NSLog(@"%@",value);
                NSLog(@"1");
                NSLog(@"%s value", [value cValue]);
                y = [NSNumber numberWithFloat:(values + 0.8)];
            }
            else if(strcmp(s, undef) == 0){
                NSLog(@"%@",value);
                NSLog(@"undef");
                NSLog(@"%s", [value cValue]);
                y = [NSNumber numberWithFloat:(values + 0.5)];
            }
            else if(strcmp(s, high) == 0){
                NSLog(@"%@",value);
                NSLog(@"high");
                NSLog(@"%s", [value cValue]);
                y = [NSNumber numberWithFloat:(values + 0.5)];
            }
            [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
            time++;
        }
        [self.numbValues addObject: [NSNumber numberWithInt:time]];
        time=0;
        values++;
    }

    
    /*for(i2 = 0; i2 < self.values.count; i2++){
        for ( i = 0; i < 10; i++ ) {
            if(i<3 || i>5){
                NSNumber *x = [NSNumber numberWithFloat:i];
                NSNumber *y = [NSNumber numberWithFloat:i2 + 0.8];
                [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
            }
            else{
                NSNumber *x = [NSNumber numberWithFloat:i];
                NSNumber *y = [NSNumber numberWithFloat: i2 + 0.2];
                [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
            }
        
        }
    }*/
    self.dataForPlot = contentArray;
}

#pragma mark -
#pragma mark CPTBarPlot delegate method

-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index
{
    NSLog(@"barWasSelectedAtRecordIndex %d", index);
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return [dataForPlot count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = nil;
	
    //if ( index % 81) {
    if ([self.numbValues indexOfObject: [NSNumber numberWithInt:index]] != NSNotFound) {
		NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
		num = [[dataForPlot objectAtIndex:index] valueForKey:key];
		// Green plot gets shifted above the blue
		if ( [(NSString *)plot.identifier isEqualToString : @"Green Plot"] ) {
			if ( fieldEnum == CPTScatterPlotFieldY ) {
				num = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:[num doubleValue] + 1.0];
			}
		}
	}
	else {
		num = [NSDecimalNumber notANumber];
	}
	
    return num;
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

-(void) setScreenOrientation{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    float screenWidth = self.view.frame.size.width;
    float screenHeight = self.view.frame.size.height;
    
    if ( UIInterfaceOrientationIsLandscape(orientation) ) {
        int height = self.values.count * CELL_SIZE_LANDSCAPE;
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
        [scrollView setFrame:CGRectMake(0,0,screenHeight, screenWidth-48)];
        [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, height)];
        [scatterPlotView setFrame: CGRectMake(120,0,scatterPlotView.frame.size.width, height)];
        [tblView setFrame:CGRectMake(0,0,120, height)];
        [coordinateView setFrame:CGRectMake(0,screenWidth-CELL_SIZE_LANDSCAPE,screenWidth, height)];
    }
    else {
        int height = self.values.count * 48;
        // Move the plots into place for landscape
        //mainView.frame = self.view.bounds;
        //scatterPlotView.frame = self.view.bounds;
        [mainView setFrame:CGRectMake(0,0,screenWidth, screenHeight)];
        //tblView.frame = self.view.bounds;
        //scrollView.frame = self.view.bounds;
        scatterPlotView.frame = self.view.bounds;
        int tbl = tblView.frame.size.height;
        NSLog(@"%i",tbl);
        [scrollView setFrame:CGRectMake(0,0,screenWidth, screenHeight-48)];
        [scrollView setContentSize:CGSizeMake(scatterPlotView.frame.size.width, height)];
        tbl = tblView.frame.size.height;
        NSLog(@"%i",tbl);
        int scroll = scrollView.frame.size.height;
        int plot = scatterPlotView.frame.size.height;
        [scatterPlotView setFrame: CGRectMake(120,0,scatterPlotView.frame.size.width, height)];
        [tblView setFrame:CGRectMake(0,0,120, height)];
        [coordinateView setFrame:CGRectMake(0,screenHeight-48,screenWidth, height)];
    }
}
@end
