//
//  MShapeSet.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MShapeSet.h"
#import "MShapePolygon.h"
#import "MShapeTexture.h"


const NSString * keySetName = @"Set Name";
const NSString * keyShapes = @"Shapes";
const NSString * keyShapeType = @"type";
const NSString * keyShapeName = @"name";
const NSString * keyShapeIconName = @"icon";
const NSString * keyShapeID = @"id";
const NSString * keyShapeShears = @"shears";
const NSString * keyShapeSolidDraw = @"solid draw";
const NSString * keyShapeConstrainShearX = @"constrain shear x";
const NSString * keyShapeLinePoints = @"line points";
const NSString * keyShapeStripIndices = @"strip indices";
const NSString * keyShapeTextureCoordinates = @"tex coords";
const NSString * keyShapeTexture = @"texture";
const NSString * keyShapeStripPoints = @"strip points";

NSString * shapeTypePoly = @"poly";
NSString * shapeTypeTex = @"tex";
NSString * shapeSolidFan = @"fan";
NSString * shapeSolidTriStrip = @"strip";


// private interface
@interface MShapeSet ()



@end


@implementation MShapeSet


#pragma mark -
#pragma mark public methods

////////////////////////////////////////////////////////////////////////////
// public methods
////////////////////////////////////////////////////////////////////////////



// generate the shape set from the contents of the given plist and
// perform any required resource loading
- (id) initFromPlist: (NSString *) pListName
{
    setName_ = 0;
    
    if ( ( self = [super init] ) )
    {
        if ( pListName )
        {
            
            NSString *path = [[NSBundle mainBundle] pathForResource:pListName ofType:@"plist"];            
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
            if ( dict )
            {
                
                //NSLog( @"shape description: %@\n", [dict description] );
                
                setName_ = [[dict objectForKey:keySetName] retain];
                NSArray *setShapes = [dict objectForKey:keyShapes];
                
                if ( setName_ && setShapes )
                { 
                
                    
                    for ( NSDictionary * curShapeDict in setShapes )
                    {
                        
                        NSString *shapeType = [curShapeDict objectForKey: keyShapeType];
                        NSString *shapeName = [curShapeDict objectForKey: keyShapeName];
                        NSString *shapeIconName = [curShapeDict objectForKey:keyShapeIconName];
                        NSNumber *shapeID = [curShapeDict objectForKey: keyShapeID];
                        NSNumber *shapeShears = [curShapeDict objectForKey: keyShapeShears];
                        NSNumber *shapeConstrainShearX = [curShapeDict objectForKey: keyShapeConstrainShearX];
                        NSString *shapeSolidDraw = [curShapeDict objectForKey: keyShapeSolidDraw];
                        
                        // polygon vals
                        NSArray *shapeLinePts = [curShapeDict objectForKey: keyShapeLinePoints];
                        NSArray *shapeStripIndices = [curShapeDict objectForKey: keyShapeStripIndices];

                        NSArray *shapeTexCoords = [curShapeDict objectForKey: keyShapeTextureCoordinates];
                        NSString *shapeTexture = [curShapeDict objectForKey:keyShapeTexture];
                        NSArray *shapeStripPoints = [curShapeDict objectForKey: keyShapeStripPoints];
                        
                        int shapeStripIndicesCount = 0;
                        if ( shapeStripIndices )
                        {
                            shapeStripIndicesCount = [shapeStripIndices count];
                        }
                        
                        if ( shapeType &&
                             shapeName &&
                             shapeIconName &&
                             shapeID )
                        {
                            
                            MShape * shape = 0;
                            
                            if ( [shapeType compare: shapeTypePoly options: NSCaseInsensitiveSearch] == NSOrderedSame )
                            {
                                shape = new MShapePolygon();
                                
                                // line points and tri strip index overrides for the polygons
                                
                                if ( shapeLinePts )
                                {
                                    int iCount = [shapeLinePts count];
                                    for ( int i = 0; i < iCount; ++i )
                                    {
                                        
                                        CGPoint pt = CGPointFromString( [shapeLinePts objectAtIndex: i] );                                                                
                                        int iStripIndex = i;              
                                        
                                        if ( shapeStripIndices )
                                        {
                                            if ( shapeStripIndicesCount > i )
                                            {
                                                iStripIndex = [[shapeStripIndices objectAtIndex:i] intValue];
                                            }
                                        }
                                        
                                        ((MShapePolygon *)shape)->addPolyPoint( pt, iStripIndex );
                                    }
                                    
                                    
                                }    
                                
                                
                                
                                
                            }
                            else if ( [shapeType compare: shapeTypeTex options: NSCaseInsensitiveSearch] == NSOrderedSame )
                            {
                                shape = new MShapeTexture();  
                                
                                // tri strip points and texture coords for the textures                                
                                
                                if ( !shapeStripPoints || !shapeTexCoords )
                                {
                                    // the default - simple quad
                                    
                                    ((MShapeTexture *)shape)->addTexturePoint( CGPointMake( -1.0f, 1.0f ), CGPointMake( 0.0f, 1.0f ) );
                                    ((MShapeTexture *)shape)->addTexturePoint( CGPointMake( 1.0f, 1.0f ), CGPointMake( 1.0f, 1.0f ) );
                                    ((MShapeTexture *)shape)->addTexturePoint( CGPointMake( -1.0f, -1.0f ), CGPointMake( 0.0f, 0.0f ) );
                                    ((MShapeTexture *)shape)->addTexturePoint( CGPointMake( 1.0f, -1.0f ), CGPointMake( 1.0f, 0.0f ) );
                                }
                                else
                                {
                                    // both are there!
                                    int iCount = [shapeStripPoints count];
                                    if ( iCount == [shapeTexCoords count] )
                                    {
                                        for ( int i = 0; i < iCount; ++i )
                                        {                                        
                                            CGPoint pt = CGPointFromString( [shapeStripPoints objectAtIndex: i] ); 
                                            CGPoint tex = CGPointFromString( [shapeTexCoords objectAtIndex: i] );                                                                
                                            ((MShapeTexture *)shape)->addTexturePoint( pt, tex );                                        
                                        }

                                    }
                                }
                                                                
                                if ( shapeTexture )
                                {
                                    ((MShapeTexture *)shape)->setTextureName( [shapeTexture UTF8String] );
                                    ((MShapeTexture *)shape)->loadTexture();                                    
                                }
                                
                                
                                
                                
                                
                            }
                            
                            if ( shape )
                            {
                                // fill out the common attribs
                                
                                                            
                                
                                shape->setShapeID( [shapeID intValue] );
                                shape->setName( [shapeName UTF8String] );
                                shape->setIconRootName( [shapeIconName UTF8String] );

                                if ( shapeShears )
                                {
                                    shape->setAllowShear( [shapeShears boolValue] );
                                }

                                if ( shapeConstrainShearX )
                                {
                                    shape->setConstrainShearXDir( [shapeConstrainShearX boolValue] );
                                }
                                
                                if ( shapeSolidDraw )
                                {
                                    if ( [shapeSolidDraw compare: shapeSolidTriStrip options: NSCaseInsensitiveSearch] == NSOrderedSame )
                                    {
                                        shape->setSolidDrawMode( GL_TRIANGLE_STRIP );
                                    }
                                    else if ( [shapeSolidDraw compare: shapeSolidFan options: NSCaseInsensitiveSearch] == NSOrderedSame )
                                    {
                                        shape->setSolidDrawMode( GL_TRIANGLE_FAN );                                        
                                    }
                                        
                                }
                            }
                            
                            shapes_.push_back( shape );
                            
                            
                        }
                    }
                }
                
            }
            
        }
        
        
    }
     
    
    return self;
}

//
//
- (void) dealloc
{
    
    int iNumShapes = shapes_.size();
    for ( int i = 0; i < iNumShapes; ++i )
    {
        delete shapes_[i];
    }
    
    shapes_.clear();
    
    if ( setName_ )
    {
        [setName_ release];     
    }
    
    [super dealloc];
}

//
//
- (int) numShapes
{
    return shapes_.size();
}

//
//
- (MShape *) shapeAtIndex: (int) iIndex
{

    if ( iIndex >= 0 && iIndex < shapes_.size() )
    {
        return shapes_[iIndex]; 
    }
    
    return 0;
}

//
//
- (MShape *) shapeForID: (ShapeID) theID
{
    int iNumShapes = shapes_.size();
    for ( int iS = 0; iS < iNumShapes; ++iS )
    {
        if ( shapes_[iS]->getShapeID() == theID )
        {
            return shapes_[iS];
        }
    }
    
    return 0;
}

#pragma mark -
#pragma mark private methods

////////////////////////////////////////////////////////////////////////////
// private methods
////////////////////////////////////////////////////////////////////////////


@end
