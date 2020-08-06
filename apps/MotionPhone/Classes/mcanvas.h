/* MCanvas.H
 *
 * Motion Canvas
 * (c) 1989-2011 Scott Snibbe
 */

#pragma once

class MCanvas;

#include "defs.H"
#include "mframe.H"
#include "Parameters.h"
#include <map>
#include <vector>
#include "SnibbeInterpolator.h"
#include "MPCanvasState.h"


#define SCALE_MAX 3.0f
#define SCALE_MIN 0.4f
#define SCALE_DEFAULT 1.0f

// for backwards compat
#define BASELINE_VIEWPORT_HALF_WIDTH 5.0f

#define MAX_GRID_LINES 200
#define GRID_NUM_CELLS_BY_WIDTH 5
#define GRID_LINE_WIDTH 1.0f
#define GRID_LINE_ALPHA_MAX 0.65f
#define GRID_ALPHA_INTERP_TIME 0.5f

#define GRID_GO_HOME_INTERP_TIME 1.0f
#define LINE_WIDTH 2.0f 

@class MPArchiveFrame;

//
//
struct PendingStroke 
{    
    CGPoint p0;
    CGPoint p1;
    float w;
    unsigned long t;
    float theta;
    int curFrame;
    float alphaCoef;
    MTouchKeyT touchKey;
};


class MCanvas {
public:
    MCanvas (int width, int height, Parameters *params, ofxMSAShape3D *shape3D);
    ~MCanvas ();
    
	void		initialize();
    //void        sync_with_canvas(MCanvas *other_canvas);
    void        calculateWindowDefaults();
	void		reshape_window();
	/*
     void        start() { set_timer(TRUE); }
     void        stop() { set_timer(FALSE); }
     void        set_fps(int frame_rate);
     int         get_fps() { return timer_usec == 0 ? 0 : 1000000 / timer_usec; }
     int         get_fps_ms() { return timer_usec / 1000; }
	 */
	
    void        set_frame_direction(int d) { frame_direction = d > 0 ? 1 : -1; }
    int         getFrameDirection() const { return frame_direction; }
    
    void        step(int nframes);
    void        test();
    void        update( double curTime );

    
    void        drawGL(bool wireframe=FALSE);
    void        translate(float *trans);
    void        translateNormalized(float *trans);
    void        translateAbsolute(float *trans);
    void        setScale( float s );
    float       scale() const { return scale_; }
    float       inverseScale() const { return invScale_; }
    
    void        getTransforms( float& scale, float& translateX, float& translateY ) { scale = scale_; translateX = translation[X]; translateY = translation[Y]; }
    
    void        goHome();
    void        cancelGoHome();
    
    void        reset_transforms();
    
    void        onTouchSequenceBegin();
    void        onTouchSequenceEnd();
    
    void        onRequestUndo();
    void        revertBrushesToState( MPCanvasState * pState );
    void        revertPeerBrushesToState( unsigned int playerIDHash, MPCanvasState * pState );
    
    void        onRequestEraseCanvas( bool flash = true );
    void        eraseCanvas(  bool onlyLocal = false, bool flash = true );
    void        erasePeerCanvas( unsigned int playerIDHash );
    
    void        onBGColorChanged();
    
    // Draw one brush onto current frame for user feedback.
    // width is in pixels.

    
    void        updateBrushZ( unsigned int playerIDHash, int frameNum, unsigned int frameBrushIndex, unsigned int zOrder );
    void        addBrushData( unsigned int playerIDHash, ShapeID shapeID, CGPoint p0, CGPoint p1, float w, MColor color, float theta, bool bFill, int frameNum, unsigned int zOrder, bool constantOutlineWidth );
    
    MBrush *    getPlayerBrush ( unsigned int playerIDHash, int frameNum, unsigned int frameBrushIndex );
    
    void        draw_onto_cframe( CGPoint p0, CGPoint p1, float w, //MColor color,
                                  float theta, MTouchKeyT touchKey, int frameNum = -1, bool forceStroke = false, float alphaCoef = 1.0f );
    
    void        transform_src_to_vp(float sx, float sy, 
                                    float x, float y);
    int         pt_in_rect(float *pt, float left, float top, float
                           right, float bottom);
    
    void        compute_grid_lines();
    void        draw_the_grid(ofxMSAShape3D *shape3D, bool wireframe);
    
    int         save_to_file(char *filename);
    int         read_from_file(char *filename);
    
    //    void        set_brush_type(int bType) { assert (bType < MBrushType_NUM && bType >= 0);  b_type = (MBrushType) bType; }
    //    void        set_auto_orient(bool a) { auto_orient = a; }
    //    void        set_fill(bool f)    { fill = f; }
    
    MShape *    brushShape()    { return params_->brushShape(); }
    bool        brushOrient()   { return params_->brushOrient(); }
    bool        brushFill()     { return params_->brushFill(); }
    float       brushWidth()    { return params_->brushWidth(); }
    void        setBrushWidth(float w)    {  params_->setBrushWidth(w); }
    
    void        setPenDown(bool pd) { pen_down = pd; }
    
    //    unsigned int  getBGColorIndex()   { return bg_color; }
    //    void          setBGColorIndex(int i)   { assert (i < NCOLORS); bg_color = i; }
    //    unsigned int  getFGColorIndex()   { return fg_color; }
    //    void          setFGColorIndex(int i)   { assert (i < NCOLORS); fg_color = i; }
    //    
    //    void          indexToColor(int ci, MColor &c)  { assert (ci < NCOLORS); MCOLOR_COPY(c, colors[ci]); }
    //    
//    MBrush      *inqBrush(int myself, int fr, int b_index)
//    { if (myself)
//        return &frame[fr].brush[b_index];
//    else
//        return &otherframe[fr].brush[b_index]; }
    
    int         inq_cframe()        { return cframe; }
    void        set_cframe(int c)   { if (cframe >= 0 && cframe < nframes) cframe = c; }
    int         numFrames() const   { return nframes; }
    double      minFrameTime() const { return minFrameTime_; }
    void        setMinFrameTime( double t ) { minFrameTime_ = t; }
    
    
    float       line_width()        {return LINE_WIDTH * scale_ / win_size[X]; }
    
    void        setDrawGrid( bool bDraw );
    
    void write_sequence();
    
    //unsigned long inq_time() { return time; }
    
    // networking integration
    
    void        ensurePeerFramesCreatedForPlayer( NSUInteger playerID );
    void        destroyPeerFramesForPlayer( NSUInteger playerID );
    void        destroyPeerFramesForAllPlayers();

    void        sendCanvasToPeers();
    
    // stroke smoothing
    void        queueBrushStrokes( bool bQueue ) { queueBrushStrokes_ = bQueue; }
    void        setNumBrushStrokesToQueue( int iNumToQueue ) { numBrushStrokesToQueue_ = iNumToQueue; }
    void        queueStroke( CGPoint p0, CGPoint p1, float w, unsigned long t, float theta, MTouchKeyT touchKey, int curFrame, float alphaCoef );                                                        
    void        flushBrushStrokeQueue();
    
    void        processStrokeEndForTouch( MTouchKeyT touchKey );
    
    static unsigned int nextBrushZVal( bool bIncrement = true );
    static unsigned int nextBrushZValForSave() { return nextBrushZForSave; }
    static void setNextBrushZVal( unsigned int iNext ) { nextBrushZ = iNext; }
    
    
    void        forceFrameNum( int iFrame ) { forcedFrame_ = iFrame; } // -1 for don't force
    
    // archiving
    
    void        postSave();
    void        preSave();
    void        loadFrame( MPArchiveFrame * frame, int iFramNum );
    MPArchiveFrame * saveFrame( int iFrameNum );
    
    static void setNextBrushZ( unsigned int z ) { nextBrushZ = z; }    
        
    void        allowBGColorChangedActions( bool b ) { allowGenerateBGColorChangedActions_ = b; }
    unsigned int calculateHighestZ();
    
    void        setAllowDrawPeers( bool bAllow ) { bAllowDrawPeers_ = bAllow; }
    
private:
    
    // managing canvas state stack
    void        pushCanvasState();
    void        popCanvasState();
    void        clearCanvasState();
    
    static unsigned int nextBrushZ;
    static unsigned int nextBrushZForSave;
    
    static void resetNextBrushZ();
    

    
    void        preDraw();
    void        doSetScale( float s );    
    void        setDirtyScale();    
    MFrame *    framesForPlayer( unsigned int playerIDHash );
    MFrame *    localFrameAtIndex( int iFrameIndex );
    
    
    Parameters  *params_;
    int         do_selection_check;
    float       sel_rect[4];    // l, t, r, b
    
    int         draw_grid;              // whether to display swatch fg color
    int         draw_swatch;            // whether to display swatch fg color

    GLfloat     scale_;                 // scale multiplier
    GLfloat     invScale_;              // inverse of scale multiplier    
    
    GLfloat     rotation;
    GLfloat     translation[2];
    GLint       win_size[2];
    GLfloat     win_scale[2];
    GLfloat     win_scale_default[2];   // the win scale value when zoom_ is 1.0f
    GLfloat     vp_size_default[2];     // size in vp coord's when zoom_ is 1.0f
    GLfloat     vp_size[2];             // size in vp coord's
    
    int         frame_rate;             // -30 to 30, including 0
    
    //    bool        auto_orient;
	bool		wireframe;
    
    //    MBrushType  b_type;
    //    bool        fill;
    //    unsigned int         bg_color;
    //    unsigned int         fg_color;
    //    float       b_width;
    float       b_rotation;
    float       b_width_delta;
    //    MColor      colors[N_COLORS];
    
    bool        pen_down;
    bool        filter_orient;
    
    int         nframes;        // number of frames
    
    void        init_colors();
    void        set_timer(int on);
    void        write_frame(char *name);
    
	ofxMSAShape3D	*shape3D;
    // Widget      drawing_a;
    // GLXContext  glx_context;
    // Display     *display;
    
    // itimerval   value;
    bool         running;
    //int         timer_sec;
    //int         timer_usec;
    
    //unsigned long time;
    
    int         frame_direction;
    int         cframe;         // current frame
    int         forcedFrame_;
    bool        bAllowDrawPeers_;
    // int         ncolors;
    
    
    CGPoint     gridLinesX_[MAX_GRID_LINES][2];
    CGPoint     gridLinesY_[MAX_GRID_LINES][2];
    
    int         numGridLinesX_;
    int         numGridLinesY_;
            
    
    MFrame                         *localFrames_;  // local frames for this canvas
    std::map<NSUInteger, MFrame *>  peerFrames_;   // frames for other players' canvases
    MFrame                         *framesToSave_;
    
    std::vector<MPCanvasState>      canvasStateStack_;
    
    SnibbeInterpolator<float, double> interpGridAlpha_;
    float gridAlphaLastFrame_;
    
    SnibbeInterpolator<float, double> interpScale_;
    SnibbeInterpolator<float, double> interpTranslationX_;
    SnibbeInterpolator<float, double> interpTranslationY_;    
    
    // for smoothing out the initial angle of strokes
    bool queueBrushStrokes_;
    int  numBrushStrokesToQueue_;
    std::vector<PendingStroke> queuedStrokes_;
    
    
    double      curTime_;
    double      minFrameTime_;
    double      lastFrameAdvanceTime_;
    double      lastZUpdateTime_;
    
    bool        allowGenerateBGColorChangedActions_;
    
    SnibbeInterpolator<float, double> bgFlashInterpolator_;
};

