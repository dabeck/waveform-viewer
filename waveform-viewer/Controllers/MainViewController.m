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
        //refresh Data for Tableview
        [self.tblView reloadData];
		
		
		[self setupGraph];
		
		for (VCDSignal *sig in [[vcd signals] allValues]) {
			[self constructScatterPlot:sig.name];
		}
    }];
    
    
}


#pragma mark -
#pragma mark Plot construction methods

- (void)setupGraph {
    NSInteger coordinate = self.signals.count * -1;
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
    
    plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(600)]; //TODO: calc max value
    plotSpace.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.signals.count) length:CPTDecimalFromDouble(coordinate/2)];

    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(100)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(self.signals.count) length:CPTDecimalFromDouble(coordinate/2)];

	
	self.graph.axisSet = nil;
	
}


- (void)constructScatterPlot:(NSString *)identifier
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
    boundLinePlot.dataLineStyle = lineStyle;
	
    boundLinePlot.dataSource     = self;
    boundLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
    boundLinePlot.interpolation  = CPTScatterPlotInterpolationStepped;
    [self.graph addPlot:boundLinePlot];
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
        self.countPlot++;
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
            number = [NSNumber numberWithFloat:(self.countPlot + 0.2)];
            return  number;
        }
        else if([number isEqualToNumber:[NSNumber numberWithInt:0]]){
            number = [NSNumber numberWithFloat:(self.countPlot + 0.8)];
            return  number;
        }
        else if([character isEqualToString:@"x"]){
            number = [NSNumber numberWithFloat:(self.countPlot + 0.5)];
            return  number;
        }
        else if([character isEqualToString:@"z"]){
            number = [NSNumber numberWithFloat:(self.countPlot + 0.5)];
            return  number;
        }
        
        return number;
    }
    if ( fieldEnum == CPTScatterPlotFieldX ) {
        return [NSDecimalNumber numberWithInteger:[newValue time]];
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
