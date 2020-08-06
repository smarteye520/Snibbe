/* mframe.H
 *
 * Frame in a series of frames
 */

#pragma once

class MFrame;

#include "defs.H"
#include "mbrush.H"

@class MPArchiveFrame;

class MFrame {
 public:
    MFrame();
    ~MFrame();

    //void        set_color_table(MColor *ctable) { color_table = ctable; }
    //void        draw();
	
    void         drawGL(ofxMSAShape3D *shape3D, bool wireframe=FALSE);
    unsigned int drawGLRange(ofxMSAShape3D *shape3D, int brushIndexBegin, unsigned int maxZVal );
    
    void        erase_all_brushes();
    void        eraseBrushesFromIndex( int indexBeginErase );
    
    MBrush *    add_brush(MShape *shape,
                          float *p1, float *p2, float width, float
                          theta, int fill, MColor color, 
                          unsigned int z, int *index, bool constantOutlineWidth ); 

    MBrush *    get_brush( unsigned int iBrushIndex );
    int         numBrushes() const { return n_brushes; }
    
    bool        isScaleDirty() const { return scaleDirty_; }
    void        setScaleDirty( bool bDirty ) { scaleDirty_ = bDirty; }    
    void        processDirtyScale();
    
    
    // archiving
    
    MPArchiveFrame * toArchiveFrame();
    void             fromArchiveFrame( MPArchiveFrame * src );
    
    MBrush *    addEmptyBrush();
    
private:
    
    void        eraseBrushContentsAtIndex( int iIndex );
    
    //void        add_brush(MBrush *b, int *index);

    //void        draw_brush(int index);
    //void        draw_brushGL(int index, ofxMSAShape3D *shape3D, bool wireframe=FALSE);

    int        write(FILE *fp);
    int        read(FILE *fp);

    int         next_brush;
    int         n_brushes;

    MBrush      *brush;
    
    bool         scaleDirty_;

    //MColor      *color_table;
};

