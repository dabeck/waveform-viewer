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
    NSMutableDictionary *visibleSignals;
    NSInteger maxTime;
    CPTPlotRange *xRange;
    CPTPlotRange *yRange;
    NSInteger visibleSignalsCount;
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
    
    if (!self.parseSelection) {
        [self performSegueWithIdentifier:@"modalIdent" sender:self];
    } else {
        [self loadSignals];
    }
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
    
    //self.graph = nil;
    //[self.graph removeFromSuperlayer];
    //[self constructScatterPlot];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self.graph removeFromSuperlayer];
    self.countPlot = -1;
    //self.graph
    [self setupGraph];
    [self constructScatterPlot];
}

/**
 *  Loads the signals from the selected VCD file
 */
- (void)loadSignals {
	//TODO: get signal from settings!
    if ([self.parseSelection  rangeOfString:@"http://"].location == NSNotFound) {
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
    } else {
        [VCD loadWithURL:[NSURL URLWithString:self.parseSelection] callback:^(VCD *vcd) {
            if(vcd == nil) {
                NSLog(@"VCD Parsing Error!");
                return;
            }
            self.signals = [vcd signals];
            [self setup];
        }];
    }
}

- (void) setup {
    //refresh Data for Tableview
    [self.tblView reloadData];
    
    for(VCDSignal *newSig in [self.signals allValues]){
        for(VCDValue *newValue in [newSig valueForKey:@"_values"]){
            if(maxTime < [newValue time]){
                maxTime = [newValue time];
            }
        }
        if(self.tblView.visibleCells.count > 14){
            visibleSignalsCount = (self.tblView.visibleCells.count);
        }
        else{
            visibleSignalsCount = 14;
        }
        xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxTime)];
        yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(visibleSignalsCount)];
        
        //configure Graph
        [self setupGraph];
        [self constructScatterPlot];
        
    }
    

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
   
    
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x				= axisSet.xAxis;
    x.majorIntervalLength       = CPTDecimalFromDouble(xInterval);
    x.minorTicksPerInterval     = 0;
	x.labelOffset = -25;

	CPTXYAxis *y = axisSet.yAxis;
	y.labelingPolicy = CPTAxisLabelingPolicyNone;
  
    if(self.tblView.visibleCells.count < 14){
        [self.tblView setContentInset:UIEdgeInsetsMake((14 -self.tblView.visibleCells.count) * 50.29f, 0, 0, 0)];
    }
    else{
        [self.tblView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
    
    [self.tblView reloadData];
	
}


- (void)constructScatterPlot
{
    
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];// Create graph from theme
    visibleSignals = [NSMutableDictionary new];
    // Create a blue plot area
    for(NSString* name in[self.signals allKeys]){
        for(UITableViewCell *cell in (self.tblView.visibleCells)){
            if([cell.textLabel.text isEqualToString:name]){
                [visibleSignals addEntriesFromDictionary:@{name:self.signals[name] }];
                CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
                boundLinePlot.identifier = name;
                
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
            continue;
        }
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	// For each line the number of different values e.g. 0,1 = 2 ...
    NSArray *allVal = [[visibleSignals objectForKey:(NSString*)plot.identifier] valueForKey:@"_values"];
	return allVal.count;
}


-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSString *plotIdent = (NSString *) plot.identifier;

    if (![plotIdent isEqualToString:self.currentIdent]) {
        self.countPlot++;
        self.currentIdent = plotIdent;
    }
	
//    if(self.countPlot >= 15){
//        return nil;
//    }
    
    VCDSignal *newSig = [visibleSignals objectForKey:plotIdent];
//  VCDValue * newValue = [newSig valueAtTime:index];
	NSArray *allVal = [newSig valueForKey:@"_values"];

	NSNumber *number = [NSNumber new];
    //for(VCDValue* newValue in [allVal ){
    VCDValue * newValue = [allVal objectAtIndex:index];
        number = [NSNumber numberWithInteger:[newValue.value integerValue]];
    

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
    //}
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

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"modalIdent"]) {
        UINavigationController *controller = [segue destinationViewController];
        
        SettingsViewController *svc = [[controller childViewControllers] firstObject];
        svc.delegate = self;
    }
}

- (void)didChooseValue:(NSString *)value {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.parseSelection = value;
    [self.navigationController popViewControllerAnimated:YES];
    [self loadSignals];
}
@end
