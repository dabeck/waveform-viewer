//
//  MainViewController.h
//  waveform-viewer
//
//  Created by Daniel Becker on 28.02.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CorePlot/CorePlot-CocoaTouch.h>
#import "VCD.h"
#import "VCDParser.h"
#import "VCDSignal.h"
#import "VCDValue.h"

const int CELL_SIZE_LANDSCAPE = 48;
const int CELL_SIZE_PORTRAIT = 48;

@interface MainViewController : UIViewController <CPTBarPlotDataSource, CPTBarPlotDelegate, CPTPlotSpaceDelegate, UITableViewDelegate, UITableViewDataSource>
{
    //IBOutlet UIView *mainView;
    IBOutlet UIView *mainView;
	CPTXYGraph *graph;
	IBOutlet CPTGraphHostingView *scatterPlotView;
	NSMutableArray *dataForPlot;
    IBOutlet UITableView *tblView;
    IBOutlet UIView *coordinateView;
    CGPoint currentPoint;
    int countPlot;
}

@property (nonatomic, strong) NSMutableArray *dataForPlot;
@property (nonatomic, strong) NSMutableArray *values;
@property (nonatomic, strong) NSDictionary *signals;
@property (nonatomic, strong) NSMutableArray *numbValues;
@property (nonatomic, strong) NSString *currentIdent;

- (void)constructScatterPlot: (NSString*)identifier;
- (void)setupGraph;
- (void)loadSignals;

@end
