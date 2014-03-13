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
#import "SettingsViewController.h"

#define CELL_HEIGHT 50.29f
#define CELL_HEIGHT_PORT 50.56f
#define MAX_VISIBLE_CELLS 14
#define MAX_VISIBLE_CELLS_PORT 19

@interface MainViewController : UIViewController <CPTBarPlotDataSource, CPTPlotSpaceDelegate, CPTPlotDelegate, SettingsViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UIView *mainView;
@property (nonatomic, weak) IBOutlet CPTGraphHostingView *scatterPlotView;
@property (nonatomic, weak) IBOutlet UITableView *tblView;

@property (nonatomic, assign) NSInteger countPlot;
@property (nonatomic, strong) CPTXYGraph *graph;

@property (nonatomic, strong) NSDictionary *signals;
@property (nonatomic, strong) NSString *currentIdent;
@property (nonatomic, strong) NSString *parseSelection;

@end
