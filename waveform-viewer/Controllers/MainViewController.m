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
    [self.tblView setDelegate:self];
    [self.tblView setDataSource:self];

	actualPosition = CGPointMake(0, 0);
	self.countPlot =-1;
	//resize the views
	
    [self loadSignals];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	//scatterPlotView.frame = self.view.bounds;
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.29f;
}

/**
 *  Triggered when the user scrolled our tableView
 *
 *  @param scrollView          the actual scrollview (our tableview)
 *  @param velocity            .
 *  @param targetContentOffset .
 */
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
	UITableView *tv = (UITableView*)scrollView;
	NSIndexPath *indexPathOfTopRowAfterScrolling = [tv indexPathForRowAtPoint:
													*targetContentOffset
													];
	CGRect rectForTopRowAfterScrolling = [tv rectForRowAtIndexPath:
										  indexPathOfTopRowAfterScrolling
										  ];
	targetContentOffset->y=rectForTopRowAfterScrolling.origin.y;
}


/**
 *  Loads the signals from the selected VCD file
 */
- (void)loadSignals {
	//TODO: get signal from settings!
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"normal" ofType:@"vcd"];
    
    [VCD loadWithPath:filePath callback:^(VCD *vcd) {
        
        if(vcd == nil) {
            NSLog(@"VCD Parsing Error!");
            return;
        }
        self.signals = [vcd signals];

        // ...
        //refresh Data for Tableview
        [self.tblView reloadData];
		
		
		[self setupGraph];
		
		//for (VCDSignal *sig in [[vcd signals] allValues]) {
			//if([sig.name isEqualToString:@"clock"] || [sig.name isEqualToString:@"z [8]"]) {
				[self constructScatterPlot];
			//}
		//}

    }];
    
    
}


#pragma mark -
#pragma mark Plot construction methods

- (void)setupGraph {
	// Create graph from theme
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.scatterPlotView.bounds];
	self.graph.plotAreaFrame.masksToBorder = NO;
	self.scatterPlotView.hostedGraph = self.graph;

    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainBlackTheme];
    [self.graph applyTheme:theme];
	
    self.graph.paddingLeft   = 0.0;
    self.graph.paddingTop    = 0.0;
    self.graph.paddingRight  = 0.0;
    self.graph.paddingBottom = 0.0;
	
    // Setup plot space

    NSInteger coordinate = (self.tblView.visibleCells.count);
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
	
    plotSpace.allowsUserInteraction = YES;
    
    plotSpace.delegate = self;
    
    plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(800000)];
    plotSpace.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(coordinate)];
    
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(10)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(coordinate)];

	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x				= axisSet.xAxis;
    x.majorIntervalLength       = CPTDecimalFromDouble(10); //TODO: dynamic scaling
    x.minorTicksPerInterval     = 0;
	x.labelOffset = -25;

	CPTXYAxis *y = axisSet.yAxis;
	y.labelingPolicy = CPTAxisLabelingPolicyNone;

	
}


- (void)constructScatterPlot
{
    
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];// Create graph from theme
    
    // Create a blue plot area
    for (VCDSignal *sig in [self.signals allValues] ) {
        if([sig.name isEqualToString:@"z [5]"]||[sig.name isEqualToString:@"z [1]"]||[sig.name isEqualToString:@"z [2]"]||[sig.name isEqualToString:@"z [3]"]||[sig.name isEqualToString:@"z [4]"]||[sig.name isEqualToString:@"z [5]"]||[sig.name isEqualToString:@"z [6]"]||[sig.name isEqualToString:@"z [7]"]||[sig.name isEqualToString:@"z [8]"]||[sig.name isEqualToString:@"z [9]"]||[sig.name isEqualToString:@"z [10]"]||[sig.name isEqualToString:@"z [11]"]||[sig.name isEqualToString:@"z [12]"]||[sig.name isEqualToString:@"z [13]"]||[sig.name isEqualToString:@"clock"]){
            CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
            boundLinePlot.identifier = [sig name];
            
            lineStyle            = [boundLinePlot.dataLineStyle mutableCopy];
            lineStyle.miterLimit = 1.0;
            lineStyle.lineWidth  = 1.0;
            lineStyle.lineColor  = [CPTColor redColor];
            boundLinePlot.dataLineStyle = lineStyle;
            
            boundLinePlot.dataSource     = self;
            boundLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
            boundLinePlot.interpolation  = CPTScatterPlotInterpolationStepped;
            [self.graph addPlot:boundLinePlot];
        }
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	// For each line the number of different values e.g. 0,1 = 2 ...
    NSArray *allVal = [[self.signals objectForKey:plot.identifier] valueForKey:@"_values"];
//	NSLog(@"%@", plot.identifier);
	return allVal.count;
//	return 2;
}

//- (NSArray *)numbersForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndexRange:(NSRange)indexRange {
//	return @[@5, @5];
//}

//- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
//	NSNumber *num;
//	
//    NSArray *allVal = [[self.signals objectForKey:plot.identifier] valueForKey:@"_values"];
//    VCDValue * currentValue = [allVal objectAtIndex:idx];
//	
//	if ( fieldEnum == CPTScatterPlotFieldY ) {
//		if ([(NSString *)plot.identifier isEqualToString:@"z [8]"]) {
//			num = [NSNumber numberWithInteger:[[NSString stringWithUTF8String:currentValue.cValue] integerValue]+2];
//		} else {
//			num = [NSNumber numberWithInteger:[[NSString stringWithUTF8String:currentValue.cValue] integerValue]];
//		}
//	}
//	
//	if ( fieldEnum == CPTScatterPlotFieldX ) {
//		num = [NSDecimalNumber numberWithInteger:[currentValue time]/10];
//	}
//
//	
//	return num;
//}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSString *plotIdent = (NSString *) plot.identifier;

    if (![plotIdent isEqualToString:self.currentIdent]) {
        self.countPlot++;
        self.currentIdent = plotIdent;
    }
	
    if(self.countPlot >= 15){
        return nil;
    }
    
//	VCDSignal *newSig = [self.signals objectForKey:plotIdent];
//  VCDValue * newValue = [newSig valueAtTime:index];
	NSArray *allVal = [[self.signals objectForKey:plotIdent] valueForKey:@"_values"];
    VCDValue * newValue = [allVal objectAtIndex:index];

	NSNumber *number = [NSNumber numberWithInteger:[newValue.value integerValue]];

    if ( fieldEnum == CPTScatterPlotFieldY ) {
        
        if([number isEqualToNumber:[NSNumber numberWithInt:1]]){
            number = [NSNumber numberWithFloat:(self.countPlot + 0.2)];
            return  number;
        }
        else if([number isEqualToNumber:[NSNumber numberWithInt:0]]){
            number = [NSNumber numberWithFloat:(self.countPlot + 0.8)];
            return  number;
        }
        else if([newValue.value isEqualToString:@"x"]){
            number = [NSNumber numberWithFloat:(self.countPlot + 0.4)];
            return  number;
        }
        else if([newValue.value isEqualToString:@"z"]){
            number = [NSNumber numberWithFloat:(self.countPlot + 0.4)];
            return  number;
        }
        
        return number;
    }
    if ( fieldEnum == CPTScatterPlotFieldX ) {
        return [NSNumber numberWithInteger:[newValue time]];
    }
    return nil;
}

-(void)didFinishDrawing:(CPTPlot *)plot
{
	NSLog(@"%@", plot.identifier);
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
@end
