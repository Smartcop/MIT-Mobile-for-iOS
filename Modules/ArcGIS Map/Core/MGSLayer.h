#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class MGSMapAnnotation;
@class MGSMapCoordinate;
@class MGSMarker;
@class MGSMapView;
@class MGSLayer;

@protocol MGSAnnotation;

@protocol MGSLayerDelegate <NSObject>
@optional
- (void)mapLayer:(MGSLayer*)layer willMoveToMapView:(MGSMapView*)mapView;
- (void)mapLayer:(MGSLayer*)layer didMoveToMapView:(MGSMapView*)mapView;

- (void)mapLayer:(MGSLayer*)layer willAddAnnotations:(NSArray*)annotations;
- (void)mapLayer:(MGSLayer*)layer didAddAnnotations:(NSArray*)annotations;

- (void)mapLayer:(MGSLayer*)layer willRemoveAnnotations:(NSArray*)annotations;
- (void)mapLayer:(MGSLayer*)layer didRemoveAnnotations:(NSArray*)annotations;

- (void)willReloadMapLayer:(MGSLayer*)mapLayer;
- (void)didReloadMapLayer:(MGSLayer*)mapLayer;
@end

@interface MGSLayer : NSObject
@property (nonatomic,weak) id<MGSLayerDelegate> delegate;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,weak,readonly) MGSMapView *mapView;

@property (nonatomic,strong) NSArray *annotations;
@property (assign,nonatomic) BOOL hidden;

+ (MKCoordinateRegion)regionForAnnotations:(NSSet*)annotations;

- (void)addAnnotation:(id<MGSAnnotation>)annotation;
- (void)addAnnotations:(NSArray *)objects;
- (void)insertAnnotation:(id<MGSAnnotation>)annotation atIndex:(NSUInteger)index;
- (void)deleteAnnotation:(id<MGSAnnotation>)annotation;
- (void)deleteAnnotations:(NSArray*)annotation;
- (void)deleteAllAnnotations;

- (void)centerOnAnnotation:(id<MGSAnnotation>)annotation;
- (MKCoordinateRegion)regionForAnnotations;

- (id)initWithName:(NSString*)name;
- (void)refreshLayer;
@end

@interface MGSLayer (Subclassing)
- (void)willMoveToMapView:(MGSMapView*)mapView;
- (void)didMoveToMapView:(MGSMapView*)mapView;
- (void)willAddAnnotations:(NSArray*)annotations;
- (void)didAddAnnotations:(NSArray*)annotations;
- (void)willRemoveAnnotations:(NSArray*)annotations;
- (void)didRemoveAnnotations:(NSArray*)annotations;
- (void)willReloadMapLayer;
- (void)didReloadMapLayer;
@end