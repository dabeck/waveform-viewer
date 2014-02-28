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
	
    [self constructScatterPlot];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ( UIInterfaceOrientationIsLandscape(fromInterfaceOrientation) ) {
        // Move the plots into place for portrait
        scatterPlotView.frame = CGRectMake(20.0, 55.0, 728.0, 556.0);
    }
    else {
        // Move the plots into place for landscape
        scatterPlotView.frame = CGRectMake(20.0, 51.0, 628.0, 677.0);
    }
}

-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark Plot construction methods

-(void)constructScatterPlot
{
    // Create graph from theme
    graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:theme];
    scatterPlotView.hostedGraph = graph;
	
    graph.paddingLeft   = 10.0;
    graph.paddingTop    = 10.0;
    graph.paddingRight  = 10.0;
    graph.paddingBottom = 10.0;
	
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(1.0) length:CPTDecimalFromDouble(2.0)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(1.0) length:CPTDecimalFromDouble(3.0)];
	
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(0.5);
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(2.0);
    x.minorTicksPerInterval       = 2;
    NSArray *exclusionRanges = [NSArray arrayWithObjects:
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(1.99) length:CPTDecimalFromDouble(0.02)],
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.99) length:CPTDecimalFromDouble(0.02)],
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(2.99) length:CPTDecimalFromDouble(0.02)],
                                nil];
    x.labelExclusionRanges = exclusionRanges;
	
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromDouble(0.5);
    y.minorTicksPerInterval       = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(2.0);
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
    NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];
    NSUInteger i;
    for ( i = 0; i < 60; i++ ) {
        NSNumber *x = [NSNumber numberWithFloat:1 + i * 0.05];
        NSNumber *y = [NSNumber numberWithFloat:1.2 * rand() / (float)RAND_MAX + 1.2];
        [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
    }
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
	
    if ( index % 8 ) {
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
    static CPTMutableTextStyle *whiteText = nil;
	
    if ( !whiteText ) {
        whiteText       = [[CPTMutableTextStyle alloc] init];
        whiteText.color = [CPTColor blackColor];
    }
	
    CPTTextLayer *newLayer = nil;
    
    if ( [plot isKindOfClass:[CPTScatterPlot class]] ) {
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%lu", (unsigned long)index] style:whiteText];
    }
	
    return newLayer;
}

@end
