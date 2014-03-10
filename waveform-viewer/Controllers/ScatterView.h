//
//  ScatterView.h
//  waveform-viewer
//
//  Created by student on 06.03.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ScatterViewDelegate <NSObject>


@end

@interface ScatterView : UIView

@property (nonatomic, assign) id <ScatterViewDelegate> delegate;

@end
