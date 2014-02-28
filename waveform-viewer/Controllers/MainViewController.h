//
//  MainViewController.h
//  waveform-viewer
//
//  Created by Daniel Becker on 28.02.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CorePlot/CorePlot-CocoaTouch.h>

@interface MainViewController : UIViewController <CPTBarPlotDataSource, CPTBarPlotDelegate>
{
	CPTXYGraph *graph;

	IBOutlet CPTGraphHostingView *scatterPlotView;
	NSMutableArray *dataForPlot;
}

@property (nonatomic, strong) NSMutableArray *dataForPlot;

- (void)constructScatterPlot;

@end
