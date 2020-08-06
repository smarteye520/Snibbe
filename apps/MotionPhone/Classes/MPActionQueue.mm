//
//  MPActionQueue.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MPAction.h"
#include "MPActionQueue.h"
#include "MPActionBrush.h"
#include "MPActionClear.h"
#include "MPActionUndo.h"
#include "MPActionUpdateBrushVals.h"
#include "MPActionBGColor.h"
#include "SnibbeUtils.h"
#include "MPNetworkManager.h"
#include "MPActionMessage.h"
#include "MPActionPool.h"

#define ACTION_QUEUE_DEBUGGING



// statics
MPActionQueue MPActionQueue::localWorkingQueue;
MPActionQueue MPActionQueue::serverWorkingQueue;
MPActionQueue MPActionQueue::serverTransferQueue;
MPActionQueue MPActionQueue::resolvedQueue;


//
// static
MPActionQueue& MPActionQueue::getLocalWorkingQueue()
{
    return localWorkingQueue;
}

//
// static
MPActionQueue& MPActionQueue::getServerWorkingQueue()
{
    return serverWorkingQueue;
}

//
// static
MPActionQueue& MPActionQueue::getServerTransferQueue()
{
    return serverTransferQueue;
}


//
// static
MPActionQueue& MPActionQueue::getResolvedQueue()
{
    return resolvedQueue;
}

//
// static
void MPActionQueue::clearAll()
{
    getLocalWorkingQueue().clear();
    getServerWorkingQueue().clear();
    getResolvedQueue().clear();
    getServerTransferQueue().clear();
}


//
//  
MPActionQueue::MPActionQueue()
{
    
}

//
//
MPActionQueue::~MPActionQueue()
{
    clear();
}

//
//
MPAction * MPActionQueue::queueAction( int playerID, MPActionT actionType )
{
    
 
    
    MPAction *newAction = constructAction( actionType );
    if ( newAction )
    {
        actions_.push_back( newAction );
    }

#if NETWORK_DEBUG_OUTPUT
    //SSLog( @"queue action of type: %d, total actions: %d\n", actionType, (int) actions_.size() );
#endif
    
    return newAction;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
//    MPActionQueue data representation
//    
//
//    bytes     value
//    -------------------------------
//    4         total bytes
//    4         total num action sequences
//
//    The remainder is made up of sequences of related actions.
//    Since the majority of action data will be brush strokes (which often
//    are multiple instances of the same stroke with common params)
//    we encode all actions as sequences rather than individual actions.
//   
//    for each action sequence
//    ------------------------
//    4         user id hash for the actions (*not necessarily the sender*)
//    1         action type
//    4         num actions in sequence
//    1         sizeof each action in sequence
//    1         sizeof common data for action sequence
//    ...       common data for action sequence (common data factored out of the individual actions)
//
//    ...       sequence action 1
//    ...       sequence action 2
//    ...       sequence action 3
//
/////////////////////////////////////////////////////////////////////////////////////////


// convert the queue to a data representation for network transfer according to the
// format above
int MPActionQueue::toData( unsigned char * outData, unsigned int& outDataSpaceRemaining, int maxActions )
{
    
    
    int totalBytes = 0;
    int totalNumSequences = 0;
    int iNumActions = actions_.size();
    if ( maxActions >= 0 )
    {
        iNumActions = MIN( iNumActions, maxActions );
    }
    
    if ( iNumActions == 0 )
    {
        return 0;
    }
    
    unsigned int initialSpaceRemaining = outDataSpaceRemaining;
    
//    unsigned int bytesRemainingInBuffer = MAX_QUEUE_DATA_SIZE;
//    
//    *(char *) &queueDataBuffer[0] = packetID;
//    bytesRemainingInBuffer -= 1;
    
    
    
    // continue here... need to update to new method of writing data 
    // in batches of common actions
    // also update from data
    // also update the setData and to/from for the actions
    
    
    // move past to tota bytes / num actions (fill out at end)
    unsigned char * pCurOut = outData + ACTION_INT_BYTES + ACTION_INT_BYTES; 
    
    
    outDataSpaceRemaining -= ACTION_INT_BYTES;
    outDataSpaceRemaining -= ACTION_INT_BYTES;
    
    
    
    
    int iNumAddedToData = 0;
    int iActionStartIndex = 0;
    int iActionCurIndex = 1;
    
    while( true )
    {
        

        
        if ( iActionCurIndex < iNumActions &&
             actions_[iActionCurIndex]->sharesCommonDataWith( actions_[iActionStartIndex] ) )
        {
            // sequence continues        
            
        }
        else
        {
            // end of sequence (or last action)    
            // include all actions in the range [iActionStartIndex, iActionCurIndex)
            
            // if we stopped due to running was the last action, so we should include the curIndex
//            int iActionToStopAt = (iActionCurIndex == iNumActions - 1) ? iActionCurIndex + 1 : iActionCurIndex;
//            
//            if (  )
//            {
//                
//            }
            
            if ( iActionCurIndex == iActionStartIndex )
            {
                // the case for actions that don't naturally go in sequences - they never
                // allow for a sequence, so we bump up the cur index
                //++iActionCurIndex;
                
                // this is wrong... need to not skip a cur index
            }
            
            
            unsigned int iNumInSequence = iActionCurIndex - iActionStartIndex;            
            
            
            assert( iNumInSequence > 0 );
            unsigned int iSizeOfSequenceAction = actions_[iActionStartIndex]->actionNumBytes();
            unsigned int iSizeOfSequenceCommonData = actions_[iActionStartIndex]->commonDataNumBytes();
            
            unsigned int sizeToBeUsedInSequence =   ACTION_INT_BYTES +  // id hash
                                                    ACTION_CHAR_BYTES + // action type
                                                    ACTION_INT_BYTES +  // num actions
                                                    ACTION_CHAR_BYTES + // size of each action
                                                    ACTION_CHAR_BYTES + // size of common data
                                                    iSizeOfSequenceCommonData + 
                                                    iSizeOfSequenceAction * iNumInSequence;
            
            if ( sizeToBeUsedInSequence >= outDataSpaceRemaining )
            {
                // abort!!!
                SSLog( @"Aborting MPActionQueue::toData - too much data!\n" );
                UIAlertView * avAlert = [[UIAlertView alloc] initWithTitle:@"Too Much Data" message:@"Warning, the canvas has too much data.  It cannot all be sent to other players" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [avAlert show];
                [avAlert release];
                
                break;
            }
            
            unsigned char actionType = (unsigned char) actions_[iActionStartIndex]->actionType();
            unsigned int userIDHash = actions_[iActionStartIndex]->playerIDHash();
            
            //SSLog( @"writing queue action sequence of %d actions, sizeof action: %d, sizeof common data: %d, action type: %d\n", iNumInSequence, iSizeOfSequenceAction, iSizeOfSequenceCommonData, actionType );
            
            // user id hash for sequence
            writeTypedBytes<unsigned int>( &pCurOut, userIDHash, ACTION_INT_BYTES, outDataSpaceRemaining );                        

            // action type for sequence            
            writeTypedBytes<unsigned char>( &pCurOut, actionType, ACTION_CHAR_BYTES, outDataSpaceRemaining );
            
            // num actions for sequence
            writeTypedBytes<unsigned int>( &pCurOut, iNumInSequence, ACTION_INT_BYTES, outDataSpaceRemaining );
            
            // sizeof each action in sequence
            writeTypedBytes<unsigned char>( &pCurOut, iSizeOfSequenceAction, ACTION_CHAR_BYTES, outDataSpaceRemaining );
          
            // sizeof common data for sequence
            writeTypedBytes<unsigned char>( &pCurOut, iSizeOfSequenceCommonData, ACTION_CHAR_BYTES, outDataSpaceRemaining );            
            
            // common data
            actions_[iActionStartIndex]->toCommonData( &pCurOut, outDataSpaceRemaining );
            
            // now the individual data for each action in the sequence            
            for ( int iAction = iActionStartIndex; iAction < iActionCurIndex; ++iAction )
            {                
                actions_[iAction]->toData( &pCurOut, outDataSpaceRemaining );
                ++iNumAddedToData;
            }
            
            ++totalNumSequences;
            
            // start a new sequence
            iActionStartIndex = iActionCurIndex;
            
            //NSLog( @"remain: %d\n", outDataSpaceRemaining );
            
        }
        
        if ( iActionCurIndex >= iNumActions )
        {
            // we're done
            break;
        }
        
        ++iActionCurIndex;
        
    }
    
    
    
    totalBytes = initialSpaceRemaining - outDataSpaceRemaining;
    
    //SSLog( @"action queue written to data: %d total bytes, %d num sequences\n", totalBytes, totalNumSequences );
    
    *(int *) outData = totalBytes;
    *(int *) (outData + ACTION_INT_BYTES) = totalNumSequences;
    
    return iNumAddedToData;
    
}

//
// Transforms data representation of action queue into actions and
// populates this queue.
// returns the number of bytes read
unsigned int MPActionQueue::fromData( unsigned char * pData, int iNetworkDataVersion )
{
    
    unsigned int totalBytesRead = 0;
    
    int totalBytes = 0;
    int totalNumSequences = 0;
    
    // total bytes in data
    readTypedBytes<int>( &pData, totalBytes, ACTION_INT_BYTES, totalBytesRead );
    
    // total num sequences
    readTypedBytes<int>( &pData, totalNumSequences, ACTION_INT_BYTES, totalBytesRead );
    
    for ( int iSeq = 0; iSeq < totalNumSequences; ++iSeq )
    {
        
        unsigned int userIDHash = 0;
        unsigned char actionType = 0;
        unsigned int numActionsInSequence = 0;
        unsigned char sizeOfEachAction = 0;
        unsigned char sizeOfCommonData = 0;
        
        // user id hash for sequence
        readTypedBytes<unsigned int>( &pData, userIDHash, ACTION_INT_BYTES, totalBytesRead );                        
        
        // action type for sequence            
        readTypedBytes<unsigned char>( &pData, actionType, ACTION_CHAR_BYTES, totalBytesRead );
                        
        // num actions for sequence
        readTypedBytes<unsigned int>( &pData, numActionsInSequence, ACTION_INT_BYTES, totalBytesRead );
                        
        // sizeof each action in sequence
        readTypedBytes<unsigned char>( &pData, sizeOfEachAction, ACTION_CHAR_BYTES, totalBytesRead );
        
        // sizeof common data for sequence
        readTypedBytes<unsigned char>( &pData, sizeOfCommonData, ACTION_CHAR_BYTES, totalBytesRead );            
        
        unsigned char *pCommonData = pData;
        
        // advance past common data
        pData += sizeOfCommonData;
        totalBytesRead += sizeOfCommonData;
        
        for ( int iAction = 0; iAction < numActionsInSequence; ++iAction )
        {
            MPAction * pNewAction = constructAction( (MPActionT) actionType, false ); 
            //assert( pNewAction );
            
            
            //SSLog( @"from data: setting action user ID hash to %d\n", userIDHash );
            
            if ( pNewAction )
            {
                pNewAction->setPlayerIDHash( userIDHash );
                
                // assign data! and add to queue...
                pNewAction->fromData( pCommonData, pData, iNetworkDataVersion );
                actions_.push_back( pNewAction );
            }
            else
            {
                // todo: warn
                //NSLog(@"warning, back action. id hash: %d, Num in sequence: %d\n", actionType, numActionsInSequence );
            }
                            
            pData += sizeOfEachAction;
            totalBytesRead += sizeOfEachAction;
        }
                        
    }
    
    return totalBytesRead;
}


//
//
void MPActionQueue::clear()
{
    int iNumActions = actions_.size();
    for ( int i = 0; i < iNumActions; ++i )
    {
        performDeleteAtIndex( i );
    }
    
    actions_.clear();
    
}

//
//
void MPActionQueue::clearNumActions( int iNumActions )
{
    
    int iNumTotalActions = actions_.size();
    int iNumToClear = MIN( iNumActions, iNumTotalActions );
    
    for ( int i = 0; i < iNumToClear; ++i )
    {
        performDeleteAtIndex( i );
    }
    
    actions_.erase( actions_.begin(), actions_.begin() + iNumToClear );    
    
}

//
// remove the contents of the queue and transfer ownership to
// the destination queue, inserting the actions in order at the
// queue's end
int MPActionQueue::transferActionsToQueue( MPActionQueue& dest, int maxActions )
{
    

    int iNumActions = actions_.size();
    
    if ( maxActions >= 0 )
    {
        iNumActions = MIN( iNumActions, maxActions );
    }
    
    for ( int i = 0; i < iNumActions; ++i )
    {
        dest.actions_.push_back( actions_[i] );
    }
    
    if ( maxActions >= 0 )
    {
        actions_.erase( actions_.begin(), actions_.begin() + iNumActions );    
    }
    else
    {
        actions_.clear();
    }
    
    return iNumActions;
}

//
//
void MPActionQueue::performActions( bool bCheckCanPerform, bool bClearPerformed )
{
    int iNumActions = actions_.size();
    int iNumPerformed = 0;
    MPNetworkManager * pMan = [MPNetworkManager man];
    
    for ( int i = 0; i < iNumActions; ++i )
    {       
        
        if ( pMan.playerRole_ != eMPClient && pMan.playerRole_ != eMPServer )
        {
            // sanity check
            break;
        }
        
        if ( bCheckCanPerform )
        {
            if ( !actions_[i]->canPerform() )
            {
                break;
            }
        }
        
#if NETWORK_DEBUG_OUTPUT
    //SSLog(@"%@ performing action of type: %d\n", pMan.playerRole_ == eMPClient ? @"client" : @"server", actions_[i]->actionType() );
#endif
        
        
        actions_[i]->perform();   

        iNumPerformed++;
    }
    
    if ( bClearPerformed )
    {
        if ( iNumPerformed == iNumActions )
        {
            clear();
        }
        else if ( iNumPerformed > 0 )        
        {
            // clear those performed off the front
            
            for ( int i = 0; i < iNumPerformed; ++i )
            {
                performDeleteAtIndex( i );
            }
            
            actions_.erase( actions_.begin(), actions_.begin() + iNumPerformed );
        }
        
    }
}

//
//
void MPActionQueue::debugOut()
{

    
    int iNumActions = actions_.size();
    SSLog( @"begin action queue (%d actions): \n------------------------------\n\n", iNumActions );
    
    for ( int i = 0; i < iNumActions; ++i )
    {
        actions_[i]->debugOut();
    }
    
    SSLog( @"end action queue: \n------------------------------\n\n" );
}


//
//
MPAction * MPActionQueue::actionAtIndex( int iIndex )
{
    if ( iIndex >= 0 && iIndex < actions_.size() )
    {
        return actions_[iIndex];
    }
    
    return 0;
}


// static
// construct a new concrete MPAction subclass based on the enumerated
// actionType
MPAction * MPActionQueue::constructAction( MPActionT actionType, bool useLocalPlayerIDHash )
{
    
    MPAction *pAction = 0;
    
    switch (actionType) {
            
        case eActionBrush:
            
            // try from the pool first for performance optimization
            //pAction = gPoolBrush.request();
            //if ( !pAction )
            {            
                pAction = new MPActionBrush();            
            }
            
            break;

        case eActionClear:
            pAction = new MPActionClear();            
            break;
            
        case eActionUndo:
            pAction = new MPActionUndo();            
            break;
            
        case eActionBGColor:
            pAction = new MPActionBGColor();            
            break;
        case eActionUpdateBrushVals:
            
            // try from the pool first for performance optimization
            //pAction = gPoolUpdateBrushVals.request();
            //if ( !pAction )
            {            
                pAction = new MPActionUpdateBrushVals();            
            }
            
            break;
        case eActionMessage:
            pAction = new MPActionMessage();
            break;            
        default:
            break;
    }
    
    if ( pAction && useLocalPlayerIDHash )
    {
        pAction->setPlayerIDHash( [MPNetworkManager man].localPlayerIDHash_ );
    }
 
    return pAction;
}

//
//    
void MPActionQueue::performDeleteAtIndex( int i )
{
    MPAction * pAction = actions_[i];
    if ( pAction->isPoolAction() )
    {     
        //  if we're using a pool action, don't delete.. just return to the pool
        pAction->setPoolIsFree( true );
    }
    else
    {
        delete pAction;
    }

}