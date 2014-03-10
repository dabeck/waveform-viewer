//
//  ScatterView.m
//  waveform-viewer
//
//  Created by student on 06.03.14.
//  Copyright (c) 2014 Uni Kassel. All rights reserved.
//

#import "ScatterView.h"

@implementation ScatterView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchedView = [super hitTest:point withEvent:event];
    NSSet* touches = [event allTouches];
    CGPoint currentPoint = [[touches anyObject] locationInView:touchedView];
    
    // Get active location upon move
    CGPoint activePoint = [[touches anyObject] locationInView:touchedView];
    
    // Determine new point based on where the touch is now located
    CGPoint newPoint = CGPointMake(touchedView.center.x + (activePoint.x - currentPoint.x),
                                   touchedView.center.y + (activePoint.y - currentPoint.y));
    
    //--------------------------------------------------------
    // Make sure we stay within the bounds of the parent view
    //--------------------------------------------------------
    float midPointX = CGRectGetMidX(touchedView.bounds);
    // If too far right...
    if (newPoint.x > touchedView.superview.bounds.size.width  - midPointX)
        newPoint.x = touchedView.superview.bounds.size.width - midPointX;
    else if (newPoint.x < midPointX)  // If too far left...
        newPoint.x = midPointX;
    
    float midPointY = CGRectGetMidY(touchedView.bounds);
    // If too far down...
    if (newPoint.y > touchedView.superview.bounds.size.height  - midPointY)
        newPoint.y = touchedView.superview.bounds.size.height - midPointY;
    else if (newPoint.y < midPointY)  // If too far up...
        newPoint.y = midPointY;
    
    // Set new center location
    touchedView.center = newPoint;
    
    // handle touches if you need
    return touchedView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
