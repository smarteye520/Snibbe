//
//  MPActionBrush.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MPActionBrush_h
#define MotionPhone_MPActionBrush_h

#include "MPAction.h"






// data offsets for common brush data

#define ACTION_BRUSH_OFFSET_SHAPE_ID 0
#define ACTION_BRUSH_OFFSET_WIDTH (ACTION_SHAPE_ID_BYTES)
#define ACTION_BRUSH_OFFSET_FILLED (ACTION_BRUSH_OFFSET_WIDTH + ACTION_FLOAT_BYTES)
#define ACTION_BRUSH_OFFSET_COLOR (ACTION_BRUSH_OFFSET_FILLED + ACTION_CHAR_BYTES)
#define ACTION_BRUSH_OFFSET_FRAME_DIR (ACTION_BRUSH_OFFSET_COLOR + ACTION_COLOR_BYTES)
#define ACTION_BRUSH_OFFSET_CONSTANT_WIDTH (ACTION_BRUSH_OFFSET_FRAME_DIR + ACTION_CHAR_BYTES)

#define ACTION_BRUSH_BYTES_COMMON (ACTION_BRUSH_OFFSET_CONSTANT_WIDTH + ACTION_CHAR_BYTES)

// data offsets for all other brush data (specific to each frame in a stroke)

#define ACTION_BRUSH_OFFSET_PT_1 0
#define ACTION_BRUSH_OFFSET_PT_2 (ACTION_BRUSH_OFFSET_PT_1 + ACTION_POINT_BYTES)
#define ACTION_BRUSH_OFFSET_THETA (ACTION_BRUSH_OFFSET_PT_2 + ACTION_POINT_BYTES)
#define ACTION_BRUSH_OFFSET_FRAME_NUM (ACTION_BRUSH_OFFSET_THETA + ACTION_FLOAT_BYTES)
#define ACTION_BRUSH_OFFSET_BRUSH_INDEX (ACTION_BRUSH_OFFSET_FRAME_NUM + ACTION_INT_BYTES)
#define ACTION_BRUSH_OFFSET_Z_ORDER (ACTION_BRUSH_OFFSET_BRUSH_INDEX + ACTION_INT_BYTES)

#define ACTION_BRUSH_BYTES (ACTION_BRUSH_OFFSET_Z_ORDER + ACTION_INT_BYTES)







class MPActionBrush : public MPAction
{
public:
    
    MPActionBrush();
    virtual ~MPActionBrush();
    
    virtual void reset();
    
    virtual unsigned int actionNumBytes() const;
    
    virtual void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    virtual void toCommonData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    virtual unsigned int  commonDataNumBytes() { return ACTION_BRUSH_BYTES_COMMON; }
    
    virtual void fromData( const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  );
    virtual void debugOut();
    virtual const char *actionDescription() { return "Brush Stroke"; }
    virtual void perform();
    virtual bool canPerform() const;
    virtual bool sharesCommonDataWith( MPAction * other );
    
    void setData( ShapeID theID, CGPoint p1, CGPoint p2, float width, float theta, bool bFilled, MColor col, int frameNum, unsigned int brushIndex, unsigned int z, bool constantWidth );
    void setZOrder( unsigned int z );    
    

    
protected:
    
    // attributes likely to be constant in a touch sequence.
    // these are factored out by networking code, so we don't keep
    // them in the buffer with the other data below
    
    unsigned char actionData_[ACTION_BRUSH_BYTES];
    
    ShapeID shapeID_;
    float   width_;
    unsigned int color_;
    char    filled_;
    char    frameDir_;
    bool constantWidth_;
    
    //MColor  color_;
    
    // attributes likely to change in a touch sequence.  stored directly in a buffer,
    // ready to copy for network transmission
    
//    CGPoint      p1_;
//    CGPoint      p2_;
//    float        theta_;
//    int          frameNum_;
//    unsigned int frameBrushIndex_;
//    unsigned int zOrder_;
    
    

    
};


#endif
