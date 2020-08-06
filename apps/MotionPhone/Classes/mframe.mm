/* mframe.C
 * (c) 1989 - 2010 Scott Snibbe
 */

#include "defs.h"
#include "Parameters.h"
#include "mframe.H"
#include "SnibbeUtils.h"
#include "MPArchiveFrame.h"
#include "MPArchiveBrush.h"

MFrame::MFrame()
{
    brush = new MBrush[gParams->maxBrushes()];
    next_brush = 0;
    n_brushes = 0;
    scaleDirty_ = false;
    
    erase_all_brushes();
    
    for ( unsigned int i = 0; i < gParams->maxBrushes(); ++i )
    {
        // the user data is in the index in the frame
        brush[i].setUserData( i );
    }
}

MFrame::~MFrame()
{
    delete []brush;
}

MBrush * 
MFrame::add_brush(
    MShape *shape,
    float *p1,
    float *p2,
    float width,
    float theta,
    int fill,
    MColor color,
    unsigned int z,
    int *index, 
    bool constantOutlineWidth )
{
    
    
    
    
    if (index) *index = next_brush;

    MBrush *pBrush = &brush[next_brush];
    
    MCOLOR_COPY(pBrush->color, color);
    
    
    
    pBrush->setShape( shape );
    pBrush->fill = fill;
    //pBrush->time = t;
    pBrush->setConstantOutlineWidth( constantOutlineWidth );
    pBrush->set_pts(p1, p2, width, theta);
    pBrush->setZOrder( z );
    
    
    
    
    next_brush++;
    n_brushes++;
    
    
    if (next_brush >= gParams->maxBrushes())
        next_brush = 0;
    if (n_brushes >= gParams->maxBrushes())
        n_brushes = gParams->maxBrushes();
    
    
    //SSLog( @"theta: %f\n", theta );
    
    //SSLog( @"adding brush, total brushes: %d\n", n_brushes );
    
    return pBrush;
    
}

MBrush * MFrame::get_brush( unsigned int iBrushIndex )
{
    if ( iBrushIndex < n_brushes )
    {
        return &brush[iBrushIndex];
    }
    
    return 0;
}

//
//
void MFrame::processDirtyScale()
{
 
    for ( int iBrush = 0; iBrush < n_brushes; ++iBrush )
    {
        
        MBrush& b = brush[iBrush];
         
        if ( b.hasShape() &&
             b.getConstantOutlineWidth() ) 
        {                        
            // retransform the shape       
            b.retransform();                        
        }
        
    }

}

#pragma mark archiving

//
//
MPArchiveFrame * MFrame::toArchiveFrame()
{
    MPArchiveFrame * aFrame = [[MPArchiveFrame alloc] init];
    
    for ( int i = 0; i < n_brushes; ++i )
    {
        MPArchiveBrush * aBrush = brush[i].toArchiveBrush();
        if ( aBrush )
        {
            [aFrame addBrush: aBrush];
        }
    }    
    
    return [aFrame autorelease];
}

//
//
void MFrame::fromArchiveFrame( MPArchiveFrame * src )
{

    erase_all_brushes();
    if ( src )
    {
        int iNumBrushes = [src numBrushes];
        for ( int i = 0; i < iNumBrushes; ++i )
        {
            MPArchiveBrush * ab = [src brushAtIndex: i];
            if ( ab )
            {                
                MBrush * emptyNewBrush = addEmptyBrush();
                emptyNewBrush->fromArchiveBrush( ab );
            }
        }        
    }

}

//void
//MFrame::add_brush(
//    MBrush *b,
//    int    *index)
//{
//    if (index) *index = next_brush;
//
//    memcpy(&brush[next_brush], b, sizeof(MBrush));
//
//    next_brush++;
//    n_brushes++;
//
//    if (next_brush >= gParams->maxBrushes())
//        next_brush = 0;
//    if (n_brushes >= gParams->maxBrushes())
//        n_brushes = gParams->maxBrushes();
//}
/*
void
MFrame::draw_brush(
    int index)
{
    if (index > 0 && index < gParams->maxBrushes())
        brush[index].draw();
}
*/

/*
void
MFrame::draw_brushGL(int index, ofxMSAShape3D *shape3D, bool wireframe)
{
    if (index > 0 && index < gParams->maxBrushes()) {
		if (wireframe)
			brush[index].drawGLLines(shape3D);
		else
			brush[index].drawGL(shape3D);	}
}
 */

void
MFrame::drawGL(ofxMSAShape3D *shape3D, bool wireframe)
{

    
    //shape3D->begin(GL_TRIANGLE_STRIP);

    //glLineWidth(3.0);
    
    if ( n_brushes > 0 )
    {
        
        for ( int iBrush = 0; iBrush < n_brushes; ++iBrush )
        {
            
            if (brush[iBrush].hasShape() ) 
            {            
                if (wireframe)
                {
                    brush[iBrush].drawGLLines(shape3D);
                }
                else
                {
                    brush[iBrush].drawGL(shape3D);
                }            
            }
            
        }
    }
    else
    {
        // nothing to draw... but if we never render anything 
        // the buffer retains contents from last frame
        shape3D->begin(GL_TRIANGLE_STRIP);        
    }
    
    
    
    
    // the individual shape instances handle starting and stopping
    // the shape3D begin/end calls... here is the final one
    
    shape3D->end();
    
    /*
    for (i = 0; i < gParams->maxBrushes(); i++) {
        if (brush[i].type != NONE) {
//            glColor3f(color_table[brush[i].color][0], 
//                      color_table[brush[i].color][1], 
//                      color_table[brush[i].color][2]);
			if (wireframe)
				brush[i].drawGLLines(shape3D);
			else
				brush[i].drawGL(shape3D);

        }
    }
     */
    
    //shape3D->end();
}


//
// Draw the brushes beginning with the given brush index and continuing in order,
// not exceeding the maximum z value.  Return the number of brushes drawn.
unsigned int MFrame::drawGLRange(ofxMSAShape3D *shape3D, int brushIndexBegin, unsigned int maxZVal )
{
    unsigned int iNumBrushesDrawn = 0;
    
    int iCurBrushIndex = brushIndexBegin;
    while( iCurBrushIndex < n_brushes )
    {
     
        if ( brush[iCurBrushIndex].getZOrder() <= maxZVal )
        {
            if (brush[iCurBrushIndex].hasShape() ) 
            {        
                //SSLog( @"brush z: %d\n", brush[iCurBrushIndex].getZOrder() );
                brush[iCurBrushIndex].drawGL(shape3D);            
            }

            ++iNumBrushesDrawn;
            ++iCurBrushIndex; 
        }
        else
        {
            break;
        }
    }
    
    // in this function we don't call shape end... we let the called do that in this
    // context since many of these will be chained together
    
    return iNumBrushesDrawn;
}

void
MFrame::erase_all_brushes()
{
    int i;

    for (i = 0; i < gParams->maxBrushes(); i++) 
    {
        eraseBrushContentsAtIndex( i );        
    }
    next_brush = 0;
    n_brushes = 0;
}

//
// remove brushes from the end of the frame, starting at the given index
void MFrame::eraseBrushesFromIndex( int indexBeginErase )
{
    
    if ( indexBeginErase >= 0 && indexBeginErase < n_brushes )
    {
    
        for ( int i = indexBeginErase; i < n_brushes; ++i )
        {    
            eraseBrushContentsAtIndex( i );        
        }
        
        next_brush = indexBeginErase;
        n_brushes = indexBeginErase;
    }

 }


//
//
MBrush * MFrame::addEmptyBrush()
{
        
    MBrush *pBrush = &brush[next_brush];
        
    next_brush++;
    n_brushes++;
    
    if (next_brush >= gParams->maxBrushes())
        next_brush = 0;
    if (n_brushes >= gParams->maxBrushes())
        n_brushes = gParams->maxBrushes();    
    
    return pBrush;

}

//
//
void MFrame::eraseBrushContentsAtIndex( int iIndex )
{
    if ( iIndex >= 0 && iIndex < n_brushes )
    {
        brush[iIndex].clear();
        brush[iIndex].setShape( 0 );
    }
}

/*
int
MFrame::write(FILE *fp)
{
    fwrite((void *) this, sizeof(MFrame), 1, fp);

    // write out all the brushes
    fwrite((void *) brush, sizeof(MBrush), gParams->maxBrushes(), fp);

    return 1;
}

int
MFrame::read(FILE *fp)
{
    MFrame save_frame;
    memcpy(&save_frame, this, sizeof(MFrame));

    fread((void *) this, sizeof(*this), 1, fp);

    this->brush = save_frame.brush;
    this->color_table = save_frame.color_table;

    // read in all the brushes
    fread((void *) brush, sizeof(MBrush), gParams->maxBrushes(), fp);    
    return 1;
}
 */
