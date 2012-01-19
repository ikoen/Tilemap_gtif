//
//  PngOverlay.m
//  TileMap
//
//  Created by Ilias Koen on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PngOverlay.h"
#define TILE_SIZE 256.0

#import "tiffio.h"
#import "geotiffio.h"
#import "geotiffio.h" /* for GeoTIFF */


#import "geotiff.h"
#import "xtiffio.h"
#import "geo_normalize.h"
#import "geo_simpletags.h"
#import "geovalues.h"

#include "cpl_serv.h"
#include <stdio.h>

static void WriteTFWFile( GTIF * gtif, const char * tif_filename );
static void GTIFPrintCorners( GTIF *, GTIFDefn *, FILE *, int, int, int, int );
static const char *CSVFileOverride( const char * );
static const char *CSVDirName = NULL;
static int GTIFgetCLLocationCoordinateptr( GTIF *gtif, GTIFDefn *defn,
                                          const char * corner_name,
                                          double x, double y, int inv_flag, int dec_flag ,CLLocationCoordinate2D *CLLocationCoordinate2D_pointer );

static int GTIFReportACorner( GTIF *gtif, GTIFDefn *defn, FILE * fp_out,
                             const char * corner_name,
                             double x, double y, int inv_flag, int dec_flag );


static TIFF *st_setup_test_info();


@interface ImageTile (FileInternal)
- (id)initWithFrame:(MKMapRect)f path:(NSString *)p;
@end

@implementation ImageTile

@synthesize frame, imagePath;

- (id)initWithFrame:(MKMapRect)f path:(NSString *)p
{
    if (self = [super init]) {
        imagePath = [p retain];
        frame = f;
    }
    return self;
}

- (void)dealloc
{
    [imagePath release];
    [super dealloc];
}

@end

@implementation PngOverlay

@synthesize image, ModelPixelScaleTag, imageScale, imageSize;

enum {VERSION=0,MAJOR,MINOR};
- (id)initWithPath:(NSString *)path{
    if (self = [super init]) {
        pngPath = path;
        
        //init image
        image = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"p013r032_7t20001020_z18_nn10_geo" ofType:@"tif"]];
        NSLog(@"path =%s", pngPath);
        //gtif setup. 
        char *tiffFilePath ="/Users/iliaskoen/works/DuKode/digitalGraphitti/dev/TileMap_gtif/images/p013r032_7t20001020_z18_nn10_geo.tif";
        TIFF *tif=(TIFF*)0;
        
        GTIF *gtif=(GTIF*)0; /* GeoKey-level descriptor */
        
        int versions[3];
        int keycount; 
        geocode_t model;    /* all key-codes are of this type */          
        
        /* Open TIFF descriptor to read GeoTIFF tags */
        tif=XTIFFOpen(tiffFilePath,"r");  
        if (!tif)
            NSLog(@"error1");
        /* Open GTIF Key parser; keys will be read at this time. */
        gtif = GTIFNew(tif);
        if (!gtif) 
            NSLog(@"error2");
        
        /* Get the GeoTIFF directory info */
        GTIFDirectoryInfo(gtif,versions,&keycount);
        if (versions[MAJOR] > 1)
        {
            NSLog(@"this file is too new for me\n");  NSLog(@"error3");
        }
        if (!GTIFKeyGet(gtif, GTModelTypeGeoKey, &model, 0, 1))
        {
            NSLog(@"Yikes! no Model Type\n"); NSLog(@"error4");
        }
        
        
        GTIFPrint(gtif,0,0);
        
        int		i, norm_print_flag = 1, proj4_print_flag = 0;
        int		tfw_flag = 0, inv_flag = 0, dec_flag = 1;
        int         st_test_flag = 0;
        
        if( norm_print_flag )
        {
            GTIFDefn	defn;
            
            if( GTIFGetDefn( gtif, &defn ) )
            {
                int		xsize, ysize;
                
                printf( "\n" );
                GTIFPrintDefn( &defn, stdout );
                
                if( proj4_print_flag )
                {
                    printf( "\n" );
                    printf( "PROJ.4 Definition: %s\n", GTIFGetProj4Defn(&defn));
                }
                // ModelPixelScaleTag = CGPointMake( defn.ModelPixelScaleTag.x ,defn);
                
                TIFFGetField( tif, TIFFTAG_IMAGEWIDTH, &xsize );
                TIFFGetField( tif, TIFFTAG_IMAGELENGTH, &ysize );
                imageSize = CGSizeMake(xsize, ysize);
                // GEORef gr;
                double * d_list = 0;
                int d_list_count = 0;
                //http://www.awaresystems.be/imaging/tiff/tifftags/modelpixelscaletag.html
                if (TIFFGetField(tif, 0x830E , &d_list_count,
                                 &d_list))
                {
                    ModelPixelScaleTag.x =  d_list[0];
                    ModelPixelScaleTag.y =  d_list[1];
                }
              
                GTIFPrintCorners( gtif, &defn, stdout, xsize, ysize, inv_flag, dec_flag );
                
                GTIFgetCLLocationCoordinateptr(gtif, &defn, "Upper Left", 0.0, 0.0, inv_flag, dec_flag, &UpperLeft);
                GTIFgetCLLocationCoordinateptr(gtif, &defn,  "Lower Left",  0.0, ysize,  inv_flag, dec_flag, &LowerLeft);
                GTIFgetCLLocationCoordinateptr(gtif, &defn, "Upper Right", xsize, 0.0, inv_flag, dec_flag, &UpperRight);
                GTIFgetCLLocationCoordinateptr(gtif, &defn, "Lower Right", xsize, ysize, inv_flag, dec_flag, &LowerRight); 
                GTIFgetCLLocationCoordinateptr(gtif, &defn, "Center", xsize/2.0, ysize/2.0, inv_flag, dec_flag, &Center);
            }
        }
        GTIFFree(gtif);
        // Close raw and tiff file and free memory
        XTIFFClose(tif);    
        
        imageScale.x = (imageSize.width/ModelPixelScaleTag.x)*1.03; 
        imageScale.y = (imageSize.height/-ModelPixelScaleTag.y)*1.17; 
        
        boundingMapRect.origin.x  = MKMapPointForCoordinate(LowerLeft).x ;
        boundingMapRect.origin.y  = MKMapPointForCoordinate(LowerLeft).y ;
        boundingMapRect.size = MKMapSizeMake(imageSize.width,imageSize.height);
        
        
    }
    return self; 
}


- (CLLocationCoordinate2D)coordinate
{
    //NSLog(@"COORDINATES")
    return MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(boundingMapRect),
                                                  MKMapRectGetMidY(boundingMapRect)));
}
- (MKMapRect)boundingMapRect
{
    return boundingMapRect;
}

#pragma dealloc

- (void)dealloc
{
    [super dealloc];
}

@end


//get the center coordinate for image. 
static int GTIFgetCLLocationCoordinateptr( GTIF *gtif, GTIFDefn *defn,
                                          const char * corner_name,
                                          double x, double y, int inv_flag, int dec_flag ,CLLocationCoordinate2D *CLLocationCoordinate2D_pointer )
{
       
    double	x_saved, y_saved;
    
    /* Try to transform the coordinate into PCS space */
    if( !GTIFImageToPCS( gtif, &x, &y ) )
        return FALSE;
    
    x_saved = x;
    y_saved = y;
    
    fprintf( stdout, "%-13s ", corner_name );
    
    if( defn->Model == ModelTypeGeographic )
    {
        if (dec_flag) 
        {
            //            CLLocationCoordinate2D_pointer->longitude = x;
            //            CLLocationCoordinate2D_pointer->latitude = y; 
            ////            fprintf( fp_out, "(%.7f,", x );
            //            fprintf( fp_out, "%.7f)\n", y );
        } 
        else 
        {
            //            fprintf( fp_out, "(%s,", GTIFDecToDMS( x, "Long", 2 ) );
            //            fprintf( fp_out, "%s)\n", GTIFDecToDMS( y, "Lat", 2 ) );
        }
    }
    else
    {
        fprintf( stdout, "(%12.3f,%12.3f)", x, y );
        
        if( GTIFProj4ToLatLong( defn, 1, &x, &y ) )
        {
            if (dec_flag) 
            {
                CLLocationCoordinate2D_pointer->longitude = x;
                CLLocationCoordinate2D_pointer->latitude = y; 
                
                //                fprintf( fp_out, "  (%.7f,", x );
                //                fprintf( fp_out, "%.7f)", y );
            } 
            else 
            {
                //                fprintf( fp_out, "  (%s,", GTIFDecToDMS( x, "Long", 2 ) );
                //                fprintf( fp_out, "%s)", GTIFDecToDMS( y, "Lat", 2 ) );
            }
        }
        
        fprintf( stdout, "\n" );
    }
    
    if( inv_flag && GTIFPCSToImage( gtif, &x_saved, &y_saved ) )
    {
        //  fprintf( fp_out, "      inverse (%11.3f,%11.3f)\n", x_saved, y_saved );
    }
    
    
    return TRUE;
}


static int GTIFReportACorner( GTIF *gtif, GTIFDefn *defn, FILE * fp_out,
                             const char * corner_name,
                             double x, double y, int inv_flag, int dec_flag )

{
    double	x_saved, y_saved;
    
    /* Try to transform the coordinate into PCS space */
    if( !GTIFImageToPCS( gtif, &x, &y ) )
        return FALSE;
    
    x_saved = x;
    y_saved = y;
    
    fprintf( fp_out, "%-13s ", corner_name );
    
    if( defn->Model == ModelTypeGeographic )
    {
        if (dec_flag) 
        {
            fprintf( fp_out, "(%.7f,", x );
            fprintf( fp_out, "%.7f)\n", y );
        } 
        else 
        {
            fprintf( fp_out, "(%s,", GTIFDecToDMS( x, "Long", 2 ) );
            fprintf( fp_out, "%s)\n", GTIFDecToDMS( y, "Lat", 2 ) );
        }
    }
    else
    {
        fprintf( fp_out, "(%12.3f,%12.3f)", x, y );
        
        if( GTIFProj4ToLatLong( defn, 1, &x, &y ) )
        {
            if (dec_flag) 
            {
                fprintf( fp_out, "  (%.7f,", x );
                fprintf( fp_out, "%.7f)", y );
            } 
            else 
            {
                fprintf( fp_out, "  (%s,", GTIFDecToDMS( x, "Long", 2 ) );
                fprintf( fp_out, "%s)", GTIFDecToDMS( y, "Lat", 2 ) );
            }
        }
        
        fprintf( fp_out, "\n" );
    }
    
    if( inv_flag && GTIFPCSToImage( gtif, &x_saved, &y_saved ) )
    {
        fprintf( fp_out, "      inverse (%11.3f,%11.3f)\n", x_saved, y_saved );
    }
    
    return TRUE;
}

static void GTIFPrintCorners( GTIF *gtif, GTIFDefn *defn, FILE * fp_out,
                             int xsize, int ysize, int inv_flag, int dec_flag )

{
    printf( "\nCorner Coordinates:\n" );
    if( !GTIFReportACorner( gtif, defn, fp_out,
                           "Upper Left", 0.0, 0.0, inv_flag, dec_flag ) )
    {
        printf( " ... unable to transform points between pixel/line and PCS space\n" );
        return;
    }
    
    GTIFReportACorner( gtif, defn, fp_out, "Lower Left", 0.0, ysize, 
                      inv_flag, dec_flag );
    GTIFReportACorner( gtif, defn, fp_out, "Upper Right", xsize, 0.0,
                      inv_flag, dec_flag );
    GTIFReportACorner( gtif, defn, fp_out, "Lower Right", xsize, ysize,
                      inv_flag, dec_flag );
    GTIFReportACorner( gtif, defn, fp_out, "Center", xsize/2.0, ysize/2.0,
                      inv_flag, dec_flag );
}

/*
 * Write the defining matrix for this file to a .tfw file with the same
 * basename.
 */

static void WriteTFWFile( GTIF * gtif, const char * tif_filename )

{
    char	tfw_filename[1024];
    int		i;
    double	adfCoeff[6], x, y;
    FILE	*fp;
    
    /*
     * form .tfw filename
     */
    strncpy( tfw_filename, tif_filename, sizeof(tfw_filename)-4 );
    for( i = strlen(tfw_filename)-1; i > 0; i-- )
    {
        if( tfw_filename[i] == '.' )
        {
            strcpy( tfw_filename + i, ".tfw" );
            break;
        }
    }
    
    if( i <= 0 )
        strcat( tfw_filename, ".tfw" );
    
    /*
     * Compute the coefficients.
     */
    x = 0.5;
    y = 0.5;
    if( !GTIFImageToPCS( gtif, &x, &y ) )
    {
        fprintf( stderr, "Unable to translate image to PCS coordinates.\n" );
        return;
    }
    adfCoeff[4] = x;
    adfCoeff[5] = y;
    
    x = 1.5;
    y = 0.5;
    if( !GTIFImageToPCS( gtif, &x, &y ) )
        return;
    adfCoeff[0] = x - adfCoeff[4];
    adfCoeff[1] = y - adfCoeff[5];
    
    x = 0.5;
    y = 1.5;
    if( !GTIFImageToPCS( gtif, &x, &y ) )
        return;
    adfCoeff[2] = x - adfCoeff[4];
    adfCoeff[3] = y - adfCoeff[5];
    
    /*
     * Write out the coefficients.
     */
    
    fp = fopen( tfw_filename, "wt" );
    if( fp == NULL )
    {
        perror( "fopen" );
        fprintf( stderr, "Failed to open TFW file `%s'\n", tfw_filename );
        return;
    }
    
    for( i = 0; i < 6; i++ )
        fprintf( fp, "%24.10f\n", adfCoeff[i] );
    
    fclose( fp );
    
    fprintf( stderr, "World file written to '%s'.\n", tfw_filename); 
}

/************************************************************************/
/*                         st_setup_test_info()                         */
/*                                                                      */
/*      Setup a ST_TIFF structure for a simulated TIFF file.  This      */
/*      is just a hack to test the ST_ interface.                       */
/************************************************************************/

static TIFF *st_setup_test_info()

{
    ST_TIFF *st;
    double dbl_data[100];
    short  shrt_data[] = 
    { 1,1,0,6,1024,0,1,1,1025,0,1,1,1026,34737,17,0,2052,0,1,9001,2054,0,1,9102,3072,0,1,26711 };
    char *ascii_data = "UTM    11 S E000|";
    
    st = ST_Create();
    
    dbl_data[0] = 60;
    dbl_data[1] = 60;
    dbl_data[2] = 0;
    
    ST_SetKey( st, 33550, 3, STT_DOUBLE, dbl_data );
    
    dbl_data[0] = 0;
    dbl_data[1] = 0;
    dbl_data[2] = 0;
    dbl_data[3] = 440720;
    dbl_data[4] = 3751320;
    dbl_data[5] = 0;
    ST_SetKey( st, 33922, 6, STT_DOUBLE, dbl_data );
    
    ST_SetKey( st, 34735, sizeof(shrt_data)/2, STT_SHORT, shrt_data );
    ST_SetKey( st, 34737, strlen(ascii_data)+1, STT_ASCII, ascii_data );
    
    return (TIFF *) st;
}



