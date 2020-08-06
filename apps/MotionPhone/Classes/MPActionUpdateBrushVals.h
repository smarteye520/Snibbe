//
//  MPActionUpdateBrushVals.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  class MPActionUpdateBrushVals
//  ----------------------------
//  Concrete MPAction class used to send value updates for aspects of a series
//  of brush objects
// 



#ifndef MotionPhone_MPActionUpdateBrushVals_h
#define MotionPhone_MPActionUpdateBrushVals_h

#include "MPAction.h"
#include "defs.h"

#define MAX_NUM_VAL_UPDATES_IN_SEQUENCE (NUM_TOUCH_FADE_FRAMES)


#define ACTION_BRUSHVALS_OFFSET_VALUE_TYPE 0
#define ACTION_BRUSHVALS_OFFSET_NUM_VALUES (ACTION_BRUSHVALS_OFFSET_VALUE_TYPE + ACTION_INT_BYTES)
#define ACTION_BRUSHVALS_OFFSET_VALUES (ACTION_BRUSHVALS_OFFSET_NUM_VALUES + ACTION_INT_BYTES)

#define ACTION_BRUSHVALS_SINGLE_VALUE_BYTES ( ACTION_INT_BYTES + ACTION_INT_BYTES + ACTION_FLOAT_BYTES )
#define ACTION_BRUSHVALS_VALUE_BYTES (MAX_NUM_VAL_UPDATES_IN_SEQUENCE * ACTION_BRUSHVALS_SINGLE_VALUE_BYTES )

#define ACTION_BRUSHVALS_BYTES ( ACTION_BRUSHVALS_OFFSET_VALUES + ACTION_BRUSHVALS_VALUE_BYTES )


enum
{
   eBrushUpdateAlpha = 1, 
};


struct MPBrushVal
{
    int          frameNum_;    
    unsigned int frameBrushIndex_;
    float        val_;
};


class MPActionUpdateBrushVals : public MPAction
{
public:
    
    MPActionUpdateBrushVals();
    virtual ~MPActionUpdateBrushVals();
    
    virtual void reset();
    
    virtual unsigned int actionNumBytes() const;    
    virtual void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    
    virtual void fromData( const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  );
    virtual void debugOut();
    virtual const char *actionDescription() { return "Update Brush Vals"; }
    virtual void perform();
    virtual bool canPerform() const;

        
    void addValue( int frameNum, unsigned int brushIndex, float fVal );
    void setValueType( int iValType ) { valueType_ = iValType; }
    
    /*
    void setData( ShapeID theID, CGPoint p1, CGPoint p2, float width, float theta, bool bFilled, MColor col, int frameNum, unsigned int brushIndex, unsigned int z );
    void setZOrder( unsigned int z );    
    
    */
    
protected:
    
    MPBrushVal values_[MAX_NUM_VAL_UPDATES_IN_SEQUENCE];
    int        numValues_;
    int        valueType_; // flag for the value this is applied to (alpha, etc...)
    
    
    
};



#endif
