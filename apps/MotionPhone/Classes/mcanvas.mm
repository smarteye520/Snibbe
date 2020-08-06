/* MCanvas.C
 
 (c) 1989-2011 Scott Snibbe
 */

#include "mcanvas.H"
#include "MTouchTracker.h"
#include "MPNetworkManager.h"
#include "MPActionQueue.h"
#include "MPActionBrush.h"
#include "MPActionUpdateBrushVals.h"
#include "MPActionUndo.h"
#include "MShape.h"
#include "MShapeLibrary.h"
#import "MPActionBGColor.h"
#import "MPCanvasState.h"
#import "MPStrokeTracker.h"
#include "MPActionMessage.h"

//
//
void MCanvas::queueStroke(  CGPoint p0, CGPoint p1, float w, unsigned long t, float theta, MTouchKeyT touchKey, int curFrame, float alphaCoef  )
{
    if ( queueBrushStrokes_ )
    {
        PendingStroke p;
        p.p0 = p0;
        p.p1 = p1;
        p.w = w;
        p.t = t;
        p.theta = theta;
        p.curFrame = curFrame;
        p.alphaCoef = alphaCoef;
        p.touchKey = touchKey;
        
        queuedStrokes_.push_back( p );
    }
    
    numBrushStrokesToQueue_--;
    if ( numBrushStrokesToQueue_ <= 0 )
    {
        numBrushStrokesToQueue_ = 0;
        flushBrushStrokeQueue();
    }
}

//
//
void MCanvas::flushBrushStrokeQueue()
{
    int iNumStrokes = queuedStrokes_.size();
    
    if ( iNumStrokes > 0 )
    {
        // we do this so we can smooth out the theta among the first n strokes
        float theta = queuedStrokes_[iNumStrokes - 1].theta;    
        
        for ( int i = 0; i < iNumStrokes; ++i )
        {
            PendingStroke& p = queuedStrokes_[i];
            draw_onto_cframe( p.p0, p.p1, p.w, theta, p.touchKey, p.curFrame, true, p.alphaCoef );
        }
        
        queuedStrokes_.clear();
    }
}


// a touch has ended, do processing on the stroke (currently just apply
// gradual alpha transparency values to the end of the stroke)
void MCanvas::processStrokeEndForTouch( MTouchKeyT touchKey )
{

 
    if ( gParams->fadeStrokes() )
    {
            
        
        
        // update alpha for end of stroke
        
        int iNumBrushes = MPStrokeTracker::Tracker().numBrushesForStroke( touchKey );
        int iNumToModify = MIN( NUM_TOUCH_FADE_FRAMES, iNumBrushes / 2 );
        
        bool bNetworked = [[MPNetworkManager man] multiplayerSessionActive];
        
        
        if ( iNumToModify > 0 )
        {
            MPActionUpdateBrushVals * actionUpdate = 0;
            if ( bNetworked )
            {
                actionUpdate = static_cast<MPActionUpdateBrushVals *>( MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionUpdateBrushVals ) );
                actionUpdate->setValueType( eBrushUpdateAlpha );                        
            }
            
            float alphaIncrement =  1.0f / (iNumToModify + 1);                
            float curAlpha = alphaIncrement;
            
            // start at end and work backwards
            for ( int i = 0; i < iNumToModify; ++i )
            {            
                MPStrokeBrushData * brushData = MPStrokeTracker::Tracker().brushAtIndex( touchKey, iNumBrushes - 1 - i );
                float alpha = brushData->brush_->getAlpha();
                alpha *= curAlpha;
                brushData->brush_->setAlpha( alpha );
                curAlpha += alphaIncrement;
                
                //NSLog( @"setting alpha: %f, frame: %d, index: %d\n", alpha, brushData->frameNum_, brushData->brush_->getUserData() );
                
                // here we report this alpha update if we're in a networked session 
                if ( actionUpdate )
                {
                    actionUpdate->addValue( brushData->frameNum_, brushData->brush_->getUserData(), alpha);
                }
            }            
            
        }    
            
    }

}


#pragma mark archiving

#define VERBOSE_PRESAVE 1

//
//   
void MCanvas::postSave()
{
    if ( framesToSave_ )
    {
        delete[] framesToSave_;
        framesToSave_ = 0;
    }
}

//
//   
void MCanvas::preSave()
{
    
    
    
    if ( [MPNetworkManager man].multiplayerSessionActive )
    {
        
#if VERBOSE_PRESAVE        
        SSLog( @"Presave:\n" );
#endif
        

        // merge everyone's together for a mega save
        
        int iNumPlayers = [MPNetworkManager man].numPlayersInMatch;
        //int iNumPeers = iNumPlayers - 1;
        nextBrushZForSave = nextBrushZ;
        
        if ( !framesToSave_ )
        {
            framesToSave_ = new MFrame[nframes];
        }
        
        for ( int iFrame = 0; iFrame < nframes; ++iFrame )
        {
        
#if VERBOSE_PRESAVE

            SSLog( @"Frame: %d\n", iFrame );
#endif

            
#if VERBOSE_PRESAVE
            
            SSLog( @"\n" );
#endif
            
            
            framesToSave_[iFrame].erase_all_brushes();
                        
            // copy each player's frames into the destination save frames            
            
            std::vector<MFrame *> allPlayerFrames;
            allPlayerFrames.push_back( &(localFrames_[iFrame]) );
            unsigned int curMergedZ = 0;
            
            std::map<NSUInteger, MFrame *>::iterator itPeer;
            for ( itPeer = peerFrames_.begin(); itPeer != peerFrames_.end(); ++itPeer )
            {
                allPlayerFrames.push_back( &((itPeer->second)[iFrame]) );
            }
            
            
            // now we have an array of the current frame for all players
            
            unsigned int allPlayerCurBrushIndex[MULTIPLAYER_NUM_PLAYERS_MAX];   // tracks the current brush index for each player
            unsigned int allPlayerNumBrushes[MULTIPLAYER_NUM_PLAYERS_MAX]; 
            int totalNumPlayers = allPlayerFrames.size();
            
#if VERBOSE_PRESAVE
            
            SSLog( @"total num players: %d\n", totalNumPlayers );
#endif
            
            for ( int iBI = 0; iBI < totalNumPlayers; ++iBI )
            {
                allPlayerCurBrushIndex[iBI] = 0;
                allPlayerNumBrushes[iBI] = allPlayerFrames[iBI]->numBrushes();
                
#if VERBOSE_PRESAVE
                
                SSLog( @"num brushes player %d: %d\n", iBI, allPlayerNumBrushes[iBI] );
#endif
            }
            
            
            bool brushesStillToProcess = true;
            
            while (brushesStillToProcess )
            {
                
            
                int iNextPBrushPlayerIndex = 0;
                unsigned int lowestZ = 99999999;
                MBrush * nextBrush = 0;
                
                for ( int i = 0; i < iNumPlayers; ++i )
                {
                    
                    
                    if ( allPlayerCurBrushIndex[i] < allPlayerNumBrushes[i] )
                    {
                        MBrush * curPlayerBrush = allPlayerFrames[i]->get_brush( allPlayerCurBrushIndex[i] );
                        unsigned int nextZ = curPlayerBrush->getZOrder();
                        if ( nextZ < lowestZ )
                        {
                            lowestZ = nextZ;
                            iNextPBrushPlayerIndex = i;
                            nextBrush = curPlayerBrush;
                        }
                    }
                }
                
                if ( nextBrush )
                {            
                    
#if VERBOSE_PRESAVE
                    
                    SSLog( @"Saving brush from player: %d at z: %d\n", iNextPBrushPlayerIndex, lowestZ );
#endif
                    
                    // add a copy to our merged array
                    allPlayerCurBrushIndex[iNextPBrushPlayerIndex]++;
                    
                    MBrush * newCopiedBrush = framesToSave_[iFrame].addEmptyBrush();
                    newCopiedBrush->copyFrom( nextBrush );                                                
                    newCopiedBrush->setZOrder( curMergedZ++ );
                }
                else
                {                     
                    brushesStillToProcess = false;
                }
                                    
            }
            
            
            // calculate the next z based on the merged canvas
            nextBrushZForSave = MAX( nextBrushZForSave, curMergedZ );
                  
#if VERBOSE_PRESAVE
            
            SSLog( @"next brush Z for save is now: %d\n", nextBrushZForSave );
            SSLog( @"\n\n" );
#endif
            
        }
            
    }
    else
    {
        // just use local frames and data
        nextBrushZForSave = nextBrushZ;            
    }
    
}


void MCanvas::loadFrame( MPArchiveFrame * frame, int iFramNum )
{
    MFrame * f = localFrameAtIndex( iFramNum );
    if ( f && frame )
    {
        f->fromArchiveFrame( frame );
        f->setScaleDirty( true );
    }
    
}

//
//
MPArchiveFrame * MCanvas::saveFrame( int iFrameNum )
{
    
    MFrame * saveFramesToUse = 0;
    
    if ( [MPNetworkManager man].multiplayerSessionActive )
    {
        saveFramesToUse = framesToSave_; // merged multiplayer frames                        
    }
    else
    {
        saveFramesToUse = localFrames_;        
    }
    
    if ( !saveFramesToUse )
    {
        return nil;
    }
    
    if (  iFrameNum >= 0 && iFrameNum < N_FRAMES )
    {
        MFrame * f = &saveFramesToUse[iFrameNum];
        if ( f )
        {
            return f->toArchiveFrame();
        }
        
    }

    
    return nil;
}

//
//
unsigned int MCanvas::calculateHighestZ()
{
    
    
    unsigned int highest = 0;
    
    for ( int frameIndex = 0; frameIndex < nframes; ++frameIndex )
    {
    
        int numLocalBrushes = localFrames_[frameIndex].numBrushes();
        MBrush * pLocalB = localFrames_[frameIndex].get_brush( numLocalBrushes -1 );
        if ( pLocalB )
        {
            highest = pLocalB->getZOrder();
        }
        
        if ( ![MPNetworkManager man].multiplayerSessionActive )
        {
            std::map<NSUInteger, MFrame *>::iterator it;
            for ( it = peerFrames_.begin(); it != peerFrames_.end(); ++it )
            {
                int numBrushes = (it->second)[frameIndex].numBrushes();
                MBrush * pB = (it->second)[frameIndex].get_brush( numBrushes -1 );
                unsigned int curZ = pB->getZOrder();
                if ( pB && curZ > highest )
                {
                    highest = curZ;
                }
            }
        }
    }
    
    return highest;
}

#pragma mark statics

// statics

// static
unsigned int MCanvas::nextBrushZ = 0;
unsigned int MCanvas::nextBrushZForSave = 0;


//
// static
unsigned int MCanvas::nextBrushZVal( bool bIncrement )
{
    if (bIncrement )
    {
        return nextBrushZ++;
    }
    else
    {
        return nextBrushZ;
    }
}

//
// static
void MCanvas::resetNextBrushZ()
{
    nextBrushZ = 0;
}


MCanvas::MCanvas(int width, int height, Parameters *params, ofxMSAShape3D *shape3D)
{
//    int i;

    params_ = params;
    
//    init_colors();
	
	this->shape3D = shape3D;
	
	win_size[X] = width;
	win_size[Y] = height;


    
    draw_swatch = FALSE;
    draw_grid = FALSE;
    
//    b_width = 40;
    b_width_delta = 0;
//    fill = TRUE;
//    b_type = LINE;
    
    
    numGridLinesX_ = 0;
    numGridLinesY_ = 0;
    interpGridAlpha_.setValue(0.0f);
    
    pen_down = FALSE;

//    auto_orient = TRUE;
	wireframe = TRUE;
    b_rotation = 0.0;
    bAllowDrawPeers_ = true;
    
    cframe = 0;
	running = true;

    nframes = N_FRAMES;

    allowGenerateBGColorChangedActions_ = true;
    curTime_ = 0.0f;
    lastZUpdateTime_ = 0.0f;
    setMinFrameTime( MIN_FRAME_TIME_MIN );
    lastFrameAdvanceTime_ = 0.0f;
    
    frame_direction = 1;

    forcedFrame_ = -1;
    
    localFrames_ = new MFrame[nframes];
        
    framesToSave_ = 0;
	
	initialize();
}

MCanvas::~MCanvas()
{
    //stop();

    destroyPeerFramesForAllPlayers();
    delete []localFrames_;
    
    if ( framesToSave_ )
    {
        delete []framesToSave_;
    }
}

void
MCanvas::initialize()
{

	/*
    for (i = 0; i < 2; i++) {
        if (the_process[i] == 0) {
            the_process[i] = getpid();
            the_canvas[i] = this;
            printf("assigned process %d to canvas 0x%x at position %d\n",
                   the_process[i], the_canvas[i], i);
            break;
        }
    }
	
    drawing_a = widget;
    glx_context = context;

    display = XtDisplay(drawing_a);

    GLwDrawingAreaMakeCurrent(drawing_a, glx_context);
    glShadeModel(GL_FLAT);
	*/
	    
    
    
    rotation = 0;
    translation[0] = translation[1] = 0.0;
    gridAlphaLastFrame_ = 0.0f;
    
//    bg_color = (int) (arc4random() % 256);
//    fg_color = (int) (arc4random() % 256);

    //timer_sec = 0;
    //timer_usec = 33333;

   // float gx, gy, len;

    /*
    // horizontal lines
    for (i = 0; i < N_ ; i++) {
        // just an interval between 0 and GRID_SIZE,
        // interpreted as an x-line or a y-line when drawing
        grid_lines[i][0] = //drand48() * GRID_SIZE*1.25;
		  FRAND(0,GRID_SIZE*1.25);
        grid_lines[i][1] = //drand48() * GRID_SIZE*1.25;
		  FRAND(0,GRID_SIZE*1.25);
    }
     */

    queueBrushStrokes( false );
    setNumBrushStrokesToQueue( 0 );
    

    pushCanvasState();
    calculateWindowDefaults();
    setScale( SCALE_DEFAULT );
    reshape_window();
    
    
}


//
// initiate the process of returning to a state of 0 transforms
void MCanvas::goHome()
{

    interpScale_.beginInterp( scale_, SCALE_DEFAULT, curTime_, GRID_GO_HOME_INTERP_TIME, eSmooth );
    interpTranslationX_.beginInterp( translation[X], 0.0f, curTime_, GRID_GO_HOME_INTERP_TIME, eSmooth );
    interpTranslationY_.beginInterp( translation[Y], 0.0f, curTime_, GRID_GO_HOME_INTERP_TIME, eSmooth );
    
}

//
// cancel the process of returning to a state of 0 transforms
void MCanvas::cancelGoHome()
{
    interpScale_.stop();
    interpTranslationX_.stop();
    interpTranslationY_.stop();
}

//
//
void
MCanvas::reset_transforms()
{
    setScale( SCALE_DEFAULT );
    
    translation[0] = translation[1] = 0.0;
    
    rotation = 0;

    reshape_window();
}

//
//
void MCanvas::onTouchSequenceBegin()
{
    pushCanvasState();
    [[MPNetworkManager man] onBrushActionSequenceBegin];
}

//
//
void MCanvas::onTouchSequenceEnd()
{
    [[MPNetworkManager man] flushLocalActions];
}

//void
//MCanvas::sync_with_canvas(
//    MCanvas *other_canvas)
//{
//    //stop();
//
//    delete frame;
//
//    frame = other_canvas->frame;
//}


void
MCanvas::calculateWindowDefaults()
{
        
    float baseline = BASELINE_VIEWPORT_HALF_WIDTH; // backwards compatibility
    float w = win_size[X];
	float h = win_size[Y];
    
    if (w <= h) {
                
        vp_size_default[X] = 2*baseline;
        vp_size_default[Y] = 2*baseline*(GLfloat)h/(GLfloat)w;
    }
    else {
        
        vp_size_default[X] = 2*baseline*w/h;
        vp_size_default[Y] = 2*baseline;
    }
    
    win_scale_default[X] = vp_size_default[X] / win_size[X];
    win_scale_default[Y] = vp_size_default[Y] / win_size[Y];
    
    gWinScaleDefaultX = win_scale_default[X];
    
}


void
MCanvas::reshape_window()
{
    //Dimension   w, h;

    //stop();

    //GLwDrawingAreaMakeCurrent(drawing_a, glx_context);    

    //XtVaGetValues(drawing_a, XmNwidth, &w, XmNheight, &h, NULL);

	// account for aspect ratio $$$$
	float w = win_size[X];
	float h = win_size[Y];
	
    glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    float baseline = BASELINE_VIEWPORT_HALF_WIDTH; // backwards compatibility
    float zoomed = baseline * invScale_;
    
    
    if (w <= h) {
        glOrthof (-zoomed, zoomed, -zoomed*h/w, 
                 zoomed*h/w, -1.0, 1.0);
        // glRotatef(rotation, 0, 0, 1);
        glTranslatef(translation[X], translation[Y], 0.0);

        vp_size[X] = 2*zoomed;
        vp_size[Y] = 2*zoomed*(GLfloat)h/(GLfloat)w;
    }
    else {
        glOrthof (-zoomed*w/h, 
                 zoomed*w/h,
                 -zoomed, zoomed, -1.0, 1.0);
        // glRotatef(rotation, 0, 0, 1);
        glTranslatef(translation[X], translation[Y], 0.0);

        vp_size[X] = 2*zoomed*w/h;
        vp_size[Y] = 2*zoomed;
    }
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity ();
   
    //win_size[X] = w;
    //win_size[Y] = h;
    win_scale[X] = vp_size[X] / win_size[X];
    win_scale[Y] = vp_size[Y] / win_size[Y];
    
    
    // printf("scale = %g\n", scale);

    
    
    compute_grid_lines();
    
    //start();
}

void
MCanvas::transform_src_to_vp(
    float sx,
    float sy,
    float x,
    float y)
{
    
    // dgm - may need to revisit now that transform code has been modified
    
    // convert pts and w to vp coordinates
    x = sx * win_scale[X] - translation[X] - 0.5*vp_size[X];
    y = 0.5*vp_size[Y] - sy * win_scale[Y] - translation[Y];
}

int
MCanvas::pt_in_rect(
    float *pt,
    float left,
    float top,
    float right,
    float bottom)
{
    if (pt[X] >= left && pt[X] <= right && pt[Y] >= bottom && pt[Y] <= top)
        return TRUE;
    else
        return FALSE;
}

void
MCanvas::translate(
    float      *trans)
{
    
    cancelGoHome();
    
    // convert pixel translation to vp translation
    translation[X] += trans[X] / win_size[X] * vp_size[X];
    translation[Y] += trans[Y] / win_size[Y] * vp_size[Y];

    
    
    reshape_window();
}

void
MCanvas::translateNormalized(float *trans)
{
    cancelGoHome();
    
    // convert pixel translation to vp translation
    translation[X] += trans[X] * vp_size[X];
    translation[Y] += trans[Y] * vp_size[Y];
    
    //NSLog( @"new translation: %f, %f\n", translation[X], translation[Y] );
    
    reshape_window();
}

void
MCanvas::translateAbsolute(float *trans)
{
    cancelGoHome();
    
    translation[X] = trans[X];
    translation[Y] = trans[Y];
    
    reshape_window();
}
    
//
//
void MCanvas::setScale( float s )
{
    cancelGoHome();    
    
    doSetScale( s );
    
    //NSLog( @"setting scale: %f\n", s );
    
    reshape_window();
    
}

//
//
void MCanvas::updateBrushZ( unsigned int playerIDHash, int frameNum, unsigned int frameBrushIndex, unsigned int zOrder )
{
    MFrame * frames = framesForPlayer( playerIDHash );    
    if ( frameNum >= 0 && frameNum < nframes )
    {
        MFrame * pFrame = &frames[frameNum];
        
        MBrush * theBrush = pFrame->get_brush( frameBrushIndex );
        if ( theBrush )
        {
            //SSLog( @"updating brush z-order to %d from %d\n", zOrder, theBrush->getZOrder() );
            theBrush->setZOrder( zOrder );
        }
        else
        {
            SSLog( @"error, invalid frame brush index in updateBrushZ: %d\n", frameBrushIndex );
        }
    }
    else
    {
        SSLog( @"error, invalid frame num in updateBrushZ: %d\n", frameNum );
    }
    
    
}

//
//
void MCanvas::addBrushData( unsigned int playerIDHash, ShapeID shapeID, CGPoint p0, CGPoint p1, float w, MColor color, float theta, bool bFill, int frameNum, unsigned int zOrder, bool constantOutlineWidth )
{
    
    //SSLog( @"adding brush data for player %d, frame num: %d\n", playerIDHash, frameNum );
 
    MFrame * frames = framesForPlayer( playerIDHash );    
    if ( frameNum >= 0 && frameNum < nframes )
    {
        MFrame * pFrame = &frames[frameNum];
        
        float fPoint0[2] = { p0.x, p0.y };
        float fPoint1[2] = { p1.x, p1.y };
                
        int frameIndex = 0;        
        MShape * pShape = [[MShapeLibrary lib] shapeForID: shapeID];
        
        // default shape
        if ( !pShape )
        {
            pShape = [[MShapeLibrary lib] defaultShape];
        }
        
        if ( pShape )
        {        
            pFrame->add_brush( pShape, fPoint0, fPoint1, w, theta, bFill, color, zOrder, &frameIndex, constantOutlineWidth );
        }
        else
        {
            SSLog( @"error in MCanvas::addBrushData, unable to find shape for id: %d\n", shapeID );
        }
        
    }
    else
    {
        SSLog( @"error, invalid frame num in updateBrushZ: %d\n", frameNum );
    }
    
}

//
//
MBrush * MCanvas::getPlayerBrush ( unsigned int playerIDHash, int frameNum, unsigned int frameBrushIndex )
{
    MFrame * frames = framesForPlayer( playerIDHash );    
    if ( frameNum >= 0 && frameNum < nframes )
    {
        MFrame * pFrame = &frames[frameNum];
        
        MBrush * theBrush = pFrame->get_brush( frameBrushIndex );
        return theBrush;
    }
    
    return 0;
}

void
MCanvas::draw_onto_cframe( CGPoint p0,
                           CGPoint p1,    
                           float w,  
                           float theta,
                           MTouchKeyT touchKey,
                           int frameNum, 
                           bool forceStroke, 
                           float alphaCoef )
{
    float width;//, theta;
    int   index;

	int cur_frame = (frameNum == -1 ? cframe : frameNum);
    
    if ( !forceStroke && queueBrushStrokes_ && numBrushStrokesToQueue_ > 0)
    {
        // we have the option of queuing this up...   
        
//        queueStroke( p0, p1, w, t, theta, cur_frame, alphaCoef );        
//        return;
    }
                
    
//	int cur_frame = cframe-1;
//	if (cur_frame < 0) cur_frame = nframes-1;

    
    // convert pts and w to vp coordinates
    p0.x = p0.x * win_scale[X] - translation[X] - 0.5*vp_size[X];
    p1.x = p1.x * win_scale[X] - translation[X] - 0.5*vp_size[X];
    p0.y = 0.5*vp_size[Y] - p0.y * win_scale[Y] - translation[Y];
    p1.y = 0.5*vp_size[Y] - p1.y * win_scale[Y] - translation[Y];

    width = w * win_scale_default[X];
    

    MColor c;
    gParams->getFGColor(c);        
    c[3] *= alphaCoef;
    
    // temp until we translate things into CGPoints
    float fPoint0[2] = { p0.x, p0.y };
    float fPoint1[2] = { p1.x, p1.y };
    
    
    //NSLog( @"brush frame: %d, x: %.2f, y: %.2f, key: %d\n", cur_frame, p0.x, p0.y, (int)touchKey );
    
    
    MBrush * addedBrush = localFrames_[cur_frame].add_brush(brushShape(), fPoint0, fPoint1, width, theta,
                                                            brushFill(), c, nextBrushZVal(), &index, gParams->constantOutlineWidth() );

        
    MPStrokeTracker::Tracker().addBrushForStroke( touchKey, addedBrush, cur_frame );
    
    // here we report this brush stroke if we're in a networked session        
    if ( [[MPNetworkManager man] multiplayerSessionActive] )
    {         
        
        MPActionBrush * brushAction = static_cast<MPActionBrush *>( MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionBrush ) );
        if ( brushAction )
        {
            
            // populate it                
            brushAction->setData( brushShape()->getShapeID(), p0, p1, width, theta, brushFill(), c, cur_frame, index, addedBrush->getZOrder(), addedBrush->getConstantOutlineWidth() );            
        }
        
    }    


}



// Recompute the location of the start and end points for all grid lines based
// on the current transformations applied to the canvas
void MCanvas::compute_grid_lines()
{
    
    numGridLinesX_ = 0;
    numGridLinesY_ = 0;
    
    float gridCellSideLen = vp_size[X] / GRID_NUM_CELLS_BY_WIDTH;
    gridCellSideLen /= invScale_;
    
    float top = -translation[Y] + vp_size[Y]*0.5;
    float bottom = -translation[Y] - vp_size[Y]*0.5;
    float left = -translation[X] - vp_size[X]*0.5;
    float right = -translation[X] + vp_size[X]*0.5;    
    
    float beyondLeft = (int)(left / gridCellSideLen) * gridCellSideLen - gridCellSideLen;                        
    float beyondRight = (int)(right / gridCellSideLen) * gridCellSideLen + gridCellSideLen;    
    float beyondBottom = (int)(bottom / gridCellSideLen) * gridCellSideLen - gridCellSideLen;
    float beyondTop = (int)(top / gridCellSideLen) * gridCellSideLen + gridCellSideLen;

    // first vertical lines    

    float curX = beyondLeft;
    while( curX <= beyondRight )
    {
        
        gridLinesY_[numGridLinesY_][0] = CGPointMake(curX, beyondBottom);
        gridLinesY_[numGridLinesY_][1] = CGPointMake(curX, beyondTop);
        numGridLinesY_++;
        curX += gridCellSideLen;
    }
    
    
    // now horizontal lines

    float curY = beyondBottom;
    while( curY <= beyondTop )
    {
        
        gridLinesX_[numGridLinesX_][0] = CGPointMake(beyondLeft, curY);
        gridLinesX_[numGridLinesX_][1] = CGPointMake(beyondRight, curY);
        numGridLinesX_++;
        curY += gridCellSideLen;
    }
    
    
    
    //vp_size
    
    
}

void
MCanvas::draw_the_grid(ofxMSAShape3D *shape3D, bool wireframe)
{
    

    
    GLfloat     g_color[3];    
    MColor c;
    gParams->getBGColor(c); 
    
    // calculate appropriate grid color
    
    g_color[0] = (c[0] + c[1] + c[2]) / 3;
    g_color[0] = g_color[0]-0.2;
    if (g_color[0] < 0)
        g_color[0] = g_color[0] + 0.4;
    g_color[2] = g_color[1] = g_color[0];

    
    glDisable(GL_TEXTURE_2D);
    
    shape3D->enableColor(true);
    shape3D->enableNormal(false);
    shape3D->enableTexCoord(false);    

    glLineWidth(GRID_LINE_WIDTH);
    shape3D->begin( GL_LINES );
    
    
    // the grid alpha interpolates in and out
    shape3D->setColor(g_color[0], g_color[1], g_color[2], interpGridAlpha_.curVal() );
      
    
    for ( int iX = 0; iX < numGridLinesX_; ++iX )
    {
        shape3D->addVertex( gridLinesX_[iX][0].x, gridLinesX_[iX][0].y );
        shape3D->addVertex( gridLinesX_[iX][1].x, gridLinesX_[iX][1].y );        
    }

    for ( int iY = 0; iY < numGridLinesY_; ++iY )
    {
        shape3D->addVertex( gridLinesY_[iY][0].x, gridLinesY_[iY][0].y );
        shape3D->addVertex( gridLinesY_[iY][1].x, gridLinesY_[iY][1].y );        
    }
    
    shape3D->end();
}

void
MCanvas::update( double curTime )
{
    if (!running) return;



    
    bool bReshape = false;
    
    curTime_ = curTime;
    interpGridAlpha_.update( curTime_ );

    interpScale_.update( curTime_ );
    interpTranslationX_.update( curTime_ );
    interpTranslationY_.update( curTime_ );
    bgFlashInterpolator_.update( curTime_ );
    
    
    if ( interpScale_.isInterpolating() )
    {
        doSetScale( interpScale_.curVal() );
        bReshape = true;
    }
    
    if ( interpTranslationX_.isInterpolating() &&
         interpTranslationY_.isInterpolating() )
    {
        translation[0] = interpTranslationX_.curVal();
        translation[1] = interpTranslationY_.curVal();
        bReshape = true;
    }
    

    
    if ( bReshape )
    {
        reshape_window();
    }
    
    

    double curFrameDuration = curTime_ - lastFrameAdvanceTime_;
    if ( curFrameDuration >= minFrameTime_ )
    {
	
        cframe += frame_direction;
        if (cframe >= nframes)
            cframe = 0;
        else if (cframe < 0)
            cframe = nframes-1;
        
        lastFrameAdvanceTime_ = curTime_;

        
        // since we're advancing the frame now, clear the dirty bit from the tracked touches
        MTouchData * curTouchData = MTouchTracker::Tracker().getFirstData();
        while ( curTouchData )
        {                
            curTouchData->drawnThisFrame_ = false;        
            curTouchData = MTouchTracker::Tracker().getNextData();
        }
        
        

    }
    
    // check that our next zVal is significantly high enough        
    // no need for this at the moment... skipping
    
    /*
    if ( curTime_ - lastZUpdateTime_ > MIN_Z_SANITY_CHECK_INTERVAL )
    {
        unsigned int highest = calculateHighestZ();
        
        nextBrushZ = MAX( nextBrushZ, highest );
        lastZUpdateTime_ = curTime_;
    }
     */
    
    
    
    // process dirty scale updates
    
    if ( localFrames_[cframe].isScaleDirty() )
    {
        localFrames_[cframe].processDirtyScale();
        localFrames_[cframe].setScaleDirty( false );
    }

    
    if ( [[MPNetworkManager man] multiplayerSessionActive] )
    {
        std::map<NSUInteger, MFrame *>::iterator itPeer;
        for ( itPeer = peerFrames_.begin(); itPeer != peerFrames_.end(); ++itPeer )
        {
                        
            if ( (itPeer->second)[cframe].isScaleDirty() )
            {
                (itPeer->second)[cframe].processDirtyScale();
                (itPeer->second)[cframe].setScaleDirty( false );
            }
                            
        }        
    }
    

    
}




//
// Single player drawing
// ----------------------
// Just draw all the brushes in the current frame in order, low
// z to high.  Simple.
// 
// Multiplayer session drawing
// ----------------------------
// - while (still frames somewhere to draw)
//  - determine which of the players' frame has the lowest next zOrder (and the second lowest)
//  - draw the brushes from that player's frame starting with that zOrder up until the second lowest player's zOrder
//  - repeat

void
MCanvas::drawGL(bool wireframe)
{
    
    
//    if ( [[MPNetworkManager man] multiplayerSessionActive] )
//    {
//        SSLog( @"drawing... (%s)\n", [MPNetworkManager man].playerRole_ == eMPClient ? "client" : "server" );
//    }
    
    
    int savedCFrame = cframe;
    if ( forcedFrame_ >= 0 )
    {
        cframe = forcedFrame_;
    }
    
    preDraw();
        
    MColor c;
    gParams->getBGColor(c);
    
    
    // here we implement the background flash effect that's used when the canvas
    // is erased.  It's done cheaply by just changing the gl clear color
    
    if ( bgFlashInterpolator_.isInterpolating() )
    {
     
        float val = bgFlashInterpolator_.curVal();
        const float valueDeltaCoef = 0.66f;
        
        // modify val to go from 0 to 1 and back
        if ( val > BG_FLASH_PERCENT_FULL )
        {
            // winding down (longer)
            val = (1.0f - val) / (1.0f - BG_FLASH_PERCENT_FULL);
        }
        else
        {
            // winding up
            
            val = val / BG_FLASH_PERCENT_FULL;
        }
                
        val = MAX( val, 0.0f );
        val = MIN( val, 1.0f );        
        
        c[0] = c[0] + (1.0f - c[0]) * valueDeltaCoef * val;
        c[1] = c[1] + (1.0f - c[1]) * valueDeltaCoef * val;
        c[2] = c[2] + (1.0f - c[2]) * valueDeltaCoef * val;
    }
        
    
    
    glClearColor (c[0], c[1], c[2], 1.0);    
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	shape3D->setClientStates();
	
    if ( draw_grid || gridAlphaLastFrame_ > .00001 )
    {	
		draw_the_grid(shape3D, wireframe);
    }

    
    gridAlphaLastFrame_ = interpGridAlpha_.curVal();

	if ( [[MPNetworkManager man] multiplayerSessionActive] && bAllowDrawPeers_ )
    {
    
        // multiplayer session is active... 
        
        
        MFrame * allPlayerFrames[MULTIPLAYER_NUM_PLAYERS_MAX];              // frames for all players in the multiplayer match
        unsigned int allPlayerCurBrushIndex[MULTIPLAYER_NUM_PLAYERS_MAX];   // tracks the current brush index for each player (aka num brushes drawn so far)
        unsigned int allPlayerNumBrushes[MULTIPLAYER_NUM_PLAYERS_MAX];      // total number of brushes in the current frame for each player
        unsigned int allPlayersNextBrushZ[MULTIPLAYER_NUM_PLAYERS_MAX];     // storage for the z value of the next brush to be drawn by each player
        
        allPlayerFrames[0] = localFrames_;
        
        std::vector<unsigned int> peerHashIDs;
        [[MPNetworkManager man] collectPeerIDHashValues: &peerHashIDs];
        
        int iNumPeers = peerHashIDs.size();
        
        //NSLog( @"active, num peers %d..\n", iNumPeers );
        
        assert( iNumPeers < MULTIPLAYER_NUM_PLAYERS_MAX );
        iNumPeers = MIN( iNumPeers, MULTIPLAYER_NUM_PLAYERS_MAX - 1 );
        
        for ( int iPeer = 0; iPeer < iNumPeers; ++iPeer )
        {
            allPlayerFrames[iPeer+1] = framesForPlayer( peerHashIDs[iPeer] );
        }
        
        int iNumPlayers = iNumPeers + 1; // all peers plus me

        const unsigned int highZVal = 999999999;
        
        for ( int i = 0; i < iNumPlayers; ++i )
        {
            allPlayerCurBrushIndex[i] = 0;
            allPlayerNumBrushes[i] = allPlayerFrames[i][cframe].numBrushes();
            allPlayersNextBrushZ[i] = highZVal;
        }
        
        
        // this is the real way... 
        
    
        int iNumBrushesTotalDrawn = 0;
        const unsigned int maxLoops = 2000;
        unsigned int numLoopIterations = 0;
        
        while ( true )
        {
            
            // find the lowest z among the brushes that are next to draw for each frame
            unsigned int lowestZ = highZVal;
            int lowestZIndex = 0;
            
            unsigned int nextLowestZ = highZVal;
            int nextLowestZIndex = 0;
            
            bool anyLeft = false;
            
            for ( int iPlayer = 0; iPlayer < iNumPlayers; ++iPlayer )
            {
                unsigned int playerCurBrushIndex = allPlayerCurBrushIndex[iPlayer];
                allPlayersNextBrushZ[iPlayer] = highZVal; 
                

                
                if ( playerCurBrushIndex < allPlayerNumBrushes[iPlayer] )
                {                                        
                    // there are brushes left to draw for this player
                    MBrush * playerBrush = allPlayerFrames[iPlayer][cframe].get_brush( playerCurBrushIndex );
                    unsigned int curBrushZ = playerBrush->getZOrder();
                    
                    if ( curBrushZ < lowestZ )
                    {                
                        // found a new lowest brush z value
                        lowestZ = curBrushZ;
                        lowestZIndex = iPlayer;                                                
                    }

                    
                    // even if we didn't find the lowest with this player, store the value so the second pass
                    // can find the next lowest value
                    
                    allPlayersNextBrushZ[iPlayer] = curBrushZ;  
                    anyLeft = true;
                    
                }
            }
            
            

            
            if ( !anyLeft || numLoopIterations > maxLoops )
            {
                break;
            }
            else
            {
                
                
                // now find the next lowest z values by excluding the                                     
                for ( int iPlayer = 0; iPlayer < iNumPlayers; ++iPlayer )
                {                                     
                    if ( iPlayer != lowestZIndex &&
                        allPlayersNextBrushZ[iPlayer] < nextLowestZ )
                    {                    
                        nextLowestZ = allPlayersNextBrushZ[iPlayer];
                        nextLowestZIndex = iPlayer;                                                                                
                    }
                }
                
                unsigned int maxZToDraw = nextLowestZ-1;
                maxZToDraw = MAX( maxZToDraw, lowestZ + 1 ); // if by some freak chance there are players with identical brush z values
                
                
                // draw and update                                
                unsigned int numDrawn = allPlayerFrames[lowestZIndex][cframe].drawGLRange( shape3D, allPlayerCurBrushIndex[lowestZIndex], maxZToDraw );                
                assert( numDrawn > 0 );
                //SSLog( @"drawing player at index: %d, brush index begin: %d, max z: %d, num drawn %d..\n", lowestZIndex, allPlayerCurBrushIndex[lowestZIndex], nextLowestZ -1, numDrawn );
                allPlayerCurBrushIndex[lowestZIndex] += numDrawn;     
                iNumBrushesTotalDrawn += numDrawn;
                
            }
            
            ++numLoopIterations;
            
            
        }
        
        if ( iNumBrushesTotalDrawn == 0 )
        {
            // nothing to draw... but if we never render anything 
            // the buffer retains contents from last frame
            shape3D->begin(GL_TRIANGLE_STRIP);  
        }
        
        shape3D->end();
        
                        
        
//        for ( int i = 0; i < iNumPlayers; ++i )
//        {
//            allPlayerFrames[i][cframe].drawGL( shape3D, wireframe );                        
//        }
        
        
    }
    else
    {
        // just draw the local frames - no multiplayer session
        localFrames_[cframe].drawGL(shape3D, wireframe);	        
    }
    

		
     
    

    
    // performance mode hacks
    
    if ( gDrawPerformanceBrushSizeIndicator )
    {
        
        // draw a 1-pixel line in the lower right that corresponds to current brush
        // width as an aid for performance mode
        
        shape3D->begin(GL_LINES);

        float brushWidth = gParams->brushWidth();        
        
        MColor col;
        gParams->getFGColor( col );                
        shape3D->setColor(col[0], col[1], col[2], gPerformanceBrushSizeIndicatorAlpha);            

        // simulate the length of the brush by using the same calculations used in
        // shape drawing (x 2 b/c of scaling both sides of a full shape - either side of 0.0)
        float lineLength = brushWidth * win_scale_default[X] * 2.0; 

        // this value is 511/512, which works for iPad 1/2.  may need to change for other platforms
        // or to be able to adapt to other platforms
        const float lastPixelHalfWidthMultiplier = 0.4990234375;
        
        shape3D->addVertex(vp_size[X] * .5, vp_size[Y] * lastPixelHalfWidthMultiplier );                
        shape3D->addVertex( vp_size[X] * .5 - lineLength,  vp_size[Y] * lastPixelHalfWidthMultiplier  );
                        
        shape3D->end();
    }
    
    if ( gDrawPerformanceFGColorIndicator )
    {
        // draw a small triangle in the upper right that corresponds to current brush color
        
        shape3D->begin( GL_TRIANGLES );
        
        MColor col;
        gParams->getFGColor( col );                
        shape3D->setColor(col[0], col[1], col[2], gPerformanceFGColorIndicatorAlpha );            
                
        const float triSideLen = vp_size[Y] * .5 * 0.037;
        
        shape3D->addVertex(-vp_size[X] * .5, vp_size[Y] * .5 - triSideLen );                
        shape3D->addVertex(-vp_size[X] * .5, vp_size[Y] * .5  );                
        shape3D->addVertex(-vp_size[X] * .5 + triSideLen, vp_size[Y] * .5 );                
        
        shape3D->end();
    }
    
    
    shape3D->restoreClientStates();
	glDisable(GL_BLEND);
    
    
    // restore
    if ( forcedFrame_ >= 0 )
    {
        cframe = savedCFrame;
    }
}

/*
static void
next_frame_cb()
{
    MCanvas     *this_canvas;
    int         i;

    pid_t       process = getpid();

    for (i= 0; i < 2; i++)
        if (the_process[i] == process) {
          
            //printf("next_frame_cb: process %d, canvas %x, position %d\n",
            //       process, the_canvas[i], i);

            this_canvas = the_canvas[i];
            break;
        }

    this_canvas->next_frame();
}
*/

/*
void
MCanvas::set_timer(
    int on)
{
    running = on;

   if (on) {
      getitimer(ITIMER_REAL, &value);
      value.it_interval.tv_sec = timer_sec;
      value.it_interval.tv_usec = timer_usec;
      value.it_value.tv_sec = timer_sec;
      value.it_value.tv_usec = timer_usec;
      
      setitimer(ITIMER_REAL, &value, NULL);
      sigset(SIGALRM, (void (*)(...))next_frame_cb);
   } else {
      getitimer(ITIMER_REAL, &value);
      value.it_interval.tv_sec = 0;
      value.it_interval.tv_usec = 0;
      value.it_value.tv_sec = 0;
      value.it_value.tv_usec = 0;

      setitimer(ITIMER_REAL, &value, NULL);
      sigignore(SIGALRM);
   }
}
*/
/*
void
MCanvas::set_fps(int frame_rate)
{
    if (frame_rate < 0)
        frame_direction = -1;
    else
        frame_direction = 1;

    // if (frame_rate == 1 || frame_rate == 0 || frame_rate == -1) {
    if (frame_rate == 0) {
        timer_sec = 0;
        timer_usec = 0;
       return;
    } else if (frame_rate == 1 || frame_rate == -1) {
        timer_sec = 0;
        timer_usec = 999999;
    } else {
        timer_sec = 0;
        timer_usec = abs(1000000 / frame_rate);
    }
    // printf("setting frame rate: %d fps, %d microseconds\n", frame_rate, timer_usec);
*/
/* -- was already commented out
    getitimer(ITIMER_REAL, &value);
    value.it_interval.tv_sec = timer_sec;
    value.it_interval.tv_usec = timer_usec;

    if (value.it_value.tv_usec == 0)
        value.it_value.tv_usec = timer_usec;

    setitimer(ITIMER_REAL, &value, NULL);
    sigset(SIGALRM, (void (*)())next_frame_cb);
*/
//}






//
//
void MCanvas::onRequestUndo()
{
    
    if ( canvasStateStack_.size() > 0 )
    {
        if ( [[MPNetworkManager man] multiplayerSessionActive] )
        {            
            // send network request
            MPActionUndo * pAction = static_cast<MPActionUndo *>( MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionUndo ) );            
            pAction->setData( canvasStateStack_[canvasStateStack_.size()-1] );
            [[MPNetworkManager man] flushLocalActions];
        }
        
              
        // always process locally immediately
        revertBrushesToState( &canvasStateStack_[canvasStateStack_.size()-1] );
        popCanvasState();
                
    }
    
}

//
// 
void MCanvas::revertBrushesToState( MPCanvasState * pState )
{
    if ( pState )
    {
        for ( int i = 0; i < N_FRAMES; ++i )
        {
            localFrames_[i].eraseBrushesFromIndex( pState->numBrushesForFrame( i ) );
        }
    }
}

//
//
void MCanvas::revertPeerBrushesToState( unsigned int playerIDHash, MPCanvasState * pState )
{
    if ( pState )
    {
        std::map<NSUInteger, MFrame *>::iterator it = peerFrames_.find( playerIDHash );
        if ( it != peerFrames_.end() )
        {                
            for ( int i = 0; i < N_FRAMES; ++i )
            {
                it->second[i].eraseBrushesFromIndex( pState->numBrushesForFrame( i ) );
            }
        }
    }
}

//
//
void MCanvas::onRequestEraseCanvas(bool flash)
{
        
    if ( [[MPNetworkManager man] multiplayerSessionActive] )
    {            
        // send network request
        MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionClear );        
        [[MPNetworkManager man] flushLocalActions];
    }
    
    
    // always process locally immediately
    eraseCanvas( true, flash );            
    

}


void MCanvas::eraseCanvas( bool onlyLocal, bool flash )
{
    
    if ( !onlyLocal )
    {
        // erase peer frames
        std::map<NSUInteger, MFrame *>::iterator it;
        for ( it = peerFrames_.begin(); it != peerFrames_.end(); ++it )
        {
            
            for ( int iFrame = 0; iFrame < nframes; iFrame++)
            {
                (it->second)[iFrame].erase_all_brushes();                
            }
            
        }
    }
    
    // erase local frames
    for ( int iFrame = 0; iFrame < nframes; iFrame++)
    {
        localFrames_[iFrame].erase_all_brushes();                
    }
    
    clearCanvasState();
    
    
    
    shape3D->clear();
    
    if ( !onlyLocal )
    {
        resetNextBrushZ();
    }
    
    
    if ( flash )
    {
        if ( bgFlashInterpolator_.isInterpolating() )
        {
            float startVal = 0.0f;
            float curVal =  bgFlashInterpolator_.curVal();
            if ( curVal <= BG_FLASH_PERCENT_FULL )
            {
                startVal = curVal;
            }
            else
            {
                float percentDown = (curVal - BG_FLASH_PERCENT_FULL) / ( 1.0f - BG_FLASH_PERCENT_FULL );
                startVal = (1.0f - percentDown) * BG_FLASH_PERCENT_FULL;
            }                
            
            bgFlashInterpolator_.beginInterp( startVal, 1.0f, curTime_, TIME_BG_FLASH );
        }
        else
        {
            
        
            bgFlashInterpolator_.beginInterp( 0.0f, 1.0f, curTime_, TIME_BG_FLASH );
            
            
        }
    }
    
}

//
//
void MCanvas::erasePeerCanvas( unsigned int playerIDHash )
{
    std::map<NSUInteger, MFrame *>::iterator it = peerFrames_.find( playerIDHash );
    if ( it != peerFrames_.end() )
    {
        for ( int iFrame = 0; iFrame < nframes; iFrame++)
        {
            (it->second)[iFrame].erase_all_brushes();                
        }                     
    }    
}

//
// the local user just changed the bg color
void MCanvas::onBGColorChanged()
{
    
    if ( [[MPNetworkManager man] multiplayerSessionActive] )
    {            
        // send network request
        
        if ( allowGenerateBGColorChangedActions_ )
        {
            MColor col;
            gParams->getBGColor( col );                
            
            MPActionBGColor *pAction =  static_cast<MPActionBGColor *>( MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionBGColor ) );
            
            pAction->setColor( col );
            
            [[MPNetworkManager man] flushLocalActions];
        }
        
    }
    
}

/*
int
MCanvas::save_to_file(
    char *filename)
{
    FILE        *fp;
    int         i, l;
    char        command[256];
    char        uncomp_fname[256];
    pid_t       pid;

    strcpy(uncomp_fname, filename);
    l = strlen(filename);
    if (l > 0 && filename[l-1] == 'z')
        uncomp_fname[l-3] = 0;

   if (!(fp = fopen(uncomp_fname, "w"))) {
      cerr << "Trouble opening file for write: " << filename << "\n";
      return FALSE;
   }

    // write # frames, brushes per frame, color table size
    fwrite((void *) this, sizeof(*this), 1, fp);
    
    // write all the frames
    for (i = 0; i < nframes; i++)
        frame[i].write(fp);

    for (i = 0; i < nframes; i++)
        otherframe[i].write(fp);

    fclose(fp);


//    sprintf(command, "gzip -f %s\n", uncomp_fname);
//    system(command);
    
    if (fork() == 0) {
        printf("compressing ouput file\n");
        execl(GZIP_PATH, GZIP_PATH, "-f", uncomp_fname, 0);
    }
    
    return TRUE;
}
*/

/*
int
MCanvas::read_from_file(
    char *filename)
{
    FILE        *fp;
    int         i, l;
    char        command[256];
    char        uncomp_fname[256];

    strcpy(uncomp_fname, filename);
    l = strlen(filename);
    if (l > 0 && filename[l-1] == 'z') {
        uncomp_fname[l-3] = 0;

        sprintf(command, "gzip -d -f %s > %s", filename,
                uncomp_fname); 
        system(command);

//        printf("uncompressing input file\n");
//        if (fork() == 0) {
//            execl(GZIP_PATH, GZIP_PATH,
//                  "-f", "-d", filename, 0);
//        }
//        wait(0);

    }

   if (!(fp = fopen(uncomp_fname, "r"))) {
      cerr << "Trouble opening file for read: " << uncomp_fname << "\n";
      return FALSE;
   }

    MCanvas     save_canvas;

    // save a copy of the current state
    memcpy(&save_canvas, this, sizeof(MCanvas));

    fread((void *) this, sizeof(*this), 1, fp);

    // restore allocated data...
    this->frame = save_canvas.frame;
    this->otherframe = save_canvas.otherframe;
    this->drawing_a = save_canvas.drawing_a;
    this->glx_context = save_canvas.glx_context;
    this->display = save_canvas.display;

    // Now read in frames
    for (i = 0; i < nframes; i++)
        frame[i].read(fp);

    for (i = 0; i < nframes; i++)
        otherframe[i].read(fp);

    fclose(fp);

    reshape_window();
	
//    if (fork() == 0) {
//        printf("compressing original file\n");
//        if (fork() == 0) {
//            execl(GZIP_PATH, GZIP_PATH, "-f", uncomp_fname, 0);
//        }
//    }

    sprintf(command, GZIP_PATH" -f %s", uncomp_fname);
    system(command);

    return TRUE;    
}
*/

/*
// Write the canvas as a sequence of rgb images
void
MCanvas::write_sequence()
{
   char name[64];

   int old_fps = get_fps();
   set_fps(0); // stop playing

   set_cframe(nframes-1);        // so next_frame will put us @ start
   
   do {
      next_frame();
      sprintf(name, "frame%02d.rgb", cframe);
      printf("%s\n",name);
      write_frame(name);
   } while (cframe != nframes-1);

   // restart the animation
   set_fps(old_fps);
   start();
}
*/
/*
#define MAX_WIDTH 2048

extern "C" {
IMAGE *iopen(char *file, char *mode, unsigned int type, unsigned int dim,
             unsigned int xsize, unsigned int ysize, unsigned int zsize);
int iclose(IMAGE *image);
int putrow(IMAGE *image, unsigned short *buffer, unsigned int y, unsigned
           int z);
}

void
MCanvas::write_frame(
    char *name)
{
   IMAGE                *image;
   unsigned long        *row_buf;
   GLint                y, x;
   short                *rbuf, *gbuf, *bbuf;
   char                 *data;

    // open the image file
   if( (image=iopen(name, "w", RLE(1), 3,
                    win_size[X], win_size[Y], 3)) == NULL ) {
      fprintf(stderr,"MCanvas::write_frame: can't open file to save image: %s\n", 
              name);
      return;
   }

   row_buf = (unsigned long *)malloc(win_size[X] * sizeof(long));
   rbuf = (short *)malloc(win_size[X]*sizeof(short));
   gbuf = (short *)malloc(win_size[X]*sizeof(short));
   bbuf = (short *)malloc(win_size[X]*sizeof(short));

   GLwDrawingAreaMakeCurrent(drawing_a, glx_context);
   glReadBuffer(GL_FRONT);

   for (y = 0; y < win_size[Y]; y++) {
      glReadPixels(0, y, win_size[X], 1, GL_RGB, GL_UNSIGNED_BYTE, row_buf);

      data = (char *) row_buf;

      for(x = 0; x < win_size[X]; x++) {
         rbuf[x] = *data++;
         gbuf[x] = *data++;
         bbuf[x] = *data++;
      }
      putrow(image, (unsigned short *) rbuf, y, 0);
      putrow(image, (unsigned short *) gbuf, y, 1);
      putrow(image, (unsigned short *) bbuf, y, 2);
   }
   iclose(image);
}
*/

// if the pen is down but user hasn't moved, add a brush on this frame for continuity's sake.
// we do this just before drawing.
void MCanvas::preDraw()
{
    
    
    if ( pen_down )
    {
        
        MTouchData * curTouchData = MTouchTracker::Tracker().getFirstData();
        while ( curTouchData )
        {                                
            
            if ( !curTouchData->drawnThisFrame_ && !curTouchData->performanceTouch_ && curTouchData->orientationValid_ ) 
            {                       
                draw_onto_cframe( curTouchData->prevPos_, curTouchData->pos_, brushWidth(), curTouchData->orientation_, curTouchData->touchKey_, cframe, false, curTouchData->calculateTouchAlpha() );
                curTouchData->drawnThisFrame_ = true;      
                curTouchData->everDrawn_ = true; 
                curTouchData->numFrames_ += 1;
            }
            
            
            curTouchData = MTouchTracker::Tracker().getNextData();
            
        }
    }
    
    
}



//
//
void MCanvas::doSetScale( float s )
{    

    s = MIN( s, SCALE_MAX );
    s = MAX( s, SCALE_MIN  );    
    
    scale_ = s; 
    invScale_ = 1.0f / scale_;
    
    setDirtyScale();
        
    
}


//
//
void MCanvas::setDirtyScale()
{
    // we need to inform interested parties that the scale has changed
    
    for ( int iFrame = 0; iFrame < nframes; ++iFrame )
    {
        localFrames_[iFrame].setScaleDirty( true );
    }
    
    if ( [[MPNetworkManager man] multiplayerSessionActive] )
    {
        std::map<NSUInteger, MFrame *>::iterator itPeer;
        for ( itPeer = peerFrames_.begin(); itPeer != peerFrames_.end(); ++itPeer )
        {
            for ( int iFrame = 0; iFrame < nframes; ++iFrame )
            {
                (itPeer->second)[iFrame].setScaleDirty( true );
            }            
        }        
    }
}


// return either the local player frame array or another player's frame
// array if in a multiplayer state
MFrame * MCanvas::framesForPlayer( unsigned int playerIDHash )
{
    
    if ( playerIDHash == [MPNetworkManager man].localPlayerIDHash_ )
    {
        return localFrames_;
    }
    else
    {
        std::map<NSUInteger, MFrame *>::iterator it = peerFrames_.find( playerIDHash );
        if ( it != peerFrames_.end() )
        {
            return it->second;
        }
        
    }
    
    return 0;
    
}

//
//
MFrame * MCanvas::localFrameAtIndex( int iFrameIndex )
{
    if ( iFrameIndex >= 0 && iFrameIndex < N_FRAMES )
    {
        return &localFrames_[iFrameIndex];
    }
    
    return 0;
}


//
//
void MCanvas::setDrawGrid( bool bDraw )
{
    if ( draw_grid != bDraw )
    {        
        interpGridAlpha_.beginInterp( interpGridAlpha_.curVal(), bDraw ? GRID_LINE_ALPHA_MAX : 0.0f, curTime_, GRID_ALPHA_INTERP_TIME );        
        draw_grid = bDraw;
    }
}

#pragma mark networking integration

//
//
void MCanvas::ensurePeerFramesCreatedForPlayer( NSUInteger playerID )
{
    
    if ( peerFrames_.find(playerID) == peerFrames_.end() )
    {
        MFrame  * newFrames = new MFrame[nframes];
        peerFrames_[playerID] = newFrames;                
    }
    
}

//
//
void MCanvas::destroyPeerFramesForPlayer( NSUInteger playerID )
{
    std::map<NSUInteger, MFrame *>::iterator it = peerFrames_.find(playerID);
    if ( it != peerFrames_.end() )
    {
        delete[] it->second;
        peerFrames_.erase(playerID);
    }
}

//
//    
void MCanvas::destroyPeerFramesForAllPlayers()
{
    std::map<NSUInteger, MFrame *>::iterator it;
    for ( it = peerFrames_.begin(); it != peerFrames_.end(); ++it )
    {
        delete[] it->second;
    }
    
    peerFrames_.clear();
}

//
// send the entire state of the canvs to peers over the network
void MCanvas::sendCanvasToPeers()
{
    
    bool bNetworked = [[MPNetworkManager man] multiplayerSessionActive];
    
#if NETWORK_DEBUG_OUTPUT
    SSLog( @"sending canvas to peers called\n" );
#endif
    
    if ( bNetworked )
    {
        
#if NETWORK_DEBUG_OUTPUT
        SSLog( @"sending canvas to peers carried out\n" );
#endif
        
        
        MPActionMessage * actionMsg = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionMessage );
        actionMsg->setMessageType( eActionMsgDontDrawPeers );       
        
        
        // send background color    
        onBGColorChanged();
        

        // send all brush strokes in our canvas
        
        for ( int iFrame = 0; iFrame < nframes; ++iFrame )
        {
            MFrame * playerFrame = localFrameAtIndex( iFrame );
            if ( playerFrame )
            {
                int iNumBrushes = playerFrame->numBrushes();
                for ( int iB = 0; iB < iNumBrushes; ++iB )
                {
                    MBrush * pB = playerFrame->get_brush( iB );
                    if ( pB )
                    {
                        
                        MPActionBrush * brushAction = static_cast<MPActionBrush *>( MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionBrush ) );
                        if ( brushAction )
                        {                   
                            // populate it with the brush data
                            pB->populateBrushAction( brushAction, iFrame );
                        }
                    }
                }
            }                        
        }
    
        MPActionMessage * actionMsg2 = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( [MPNetworkManager man].localPlayerIDHash_, eActionMessage );
        actionMsg2->setMessageType( eActionMsgDrawPeers );       

        
        [[MPNetworkManager man] flushLocalActions];
    }
    
    
}

//
//
void MCanvas::pushCanvasState()
{
    // SSLog( @"pushing canvas state...\n" );
    
    MPCanvasState curCanvasState;
    curCanvasState.snapshot( localFrames_ );
    canvasStateStack_.push_back(curCanvasState);
    
}

//
//
void MCanvas::popCanvasState()
{
    
    canvasStateStack_.pop_back();
}

//
//
void MCanvas::clearCanvasState()
{
    canvasStateStack_.clear();    
}

