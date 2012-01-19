//
//  PngOverlay.h
//  TileMap
//
//  Created by Ilias Koen on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>



@interface ImageTile : NSObject {
    NSString *imagePath;
    UIImage* image; 
    MKMapRect frame;
}
@property (nonatomic, readonly) MKMapRect image;
@property (nonatomic, readonly) MKMapRect frame;
@property (nonatomic, readonly) NSString *imagePath;

@end



@interface PngOverlay : NSObject <MKOverlay> {
    MKMapRect frame;
    NSString *pngPath;
    MKMapRect boundingMapRect;
    UIImage *image;
    CGSize imageSize; 
    
    CLLocationCoordinate2D UpperLeft   ;
    CLLocationCoordinate2D LowerLeft   ;
    CLLocationCoordinate2D UpperRight  ;
    CLLocationCoordinate2D LowerRight  ;
    CLLocationCoordinate2D Center;
    
    CGPoint imageScale;
    //modal pixel scale x,  y , z (not yet used) 
    CGPoint ModelPixelScaleTag; 
    //center coordinates in lat and long. 
    //CLLocationCoordinate2D centerCoordinates;
    
}
@property (nonatomic, readonly) MKMapRect boundingMapRect;
@property (nonatomic, readonly) NSString *pngPath;
@property (nonatomic, readonly) UIImage* image; 
@property (nonatomic, readonly) CGPoint imageScale; 
@property (nonatomic, readonly) CGPoint ModelPixelScaleTag;
@property (nonatomic, readonly) CLLocationCoordinate2D centerCoordinates;
@property (nonatomic, readonly) CGSize imageSize; 

//functions
- (id)initWithPath:(NSString *)path;

@end
