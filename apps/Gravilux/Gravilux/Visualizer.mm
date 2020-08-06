//
//  Visualizer.mm
//  Gravilux
//
//  Created by Colin Roache on 10/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "Visualizer.h"
#include "Gravilux.h"
#include "Parameters.h"
#include "FEperlin.h"
#include "FEspinning.h"
#include "FEline.h"
#include "FEupwards.h"
#include "FEquad.h"
#include "FEspine.h"
#include "FEpushPull.h"

#include "fmod_errors.h"
//#include "fmodiphone.h"

#define AUTOMATIC_LEVEL .25f
void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
    }
}


Visualizer::Visualizer()
{
	fmodchn = 0;
	fmodsnd = 0;
	FMOD::System_Create(&fmodsys);

//	FMOD_IPHONE_EXTRADRIVERDATA extradriverdata;
//	memset(&extradriverdata, 0, sizeof(FMOD_IPHONE_EXTRADRIVERDATA));
//	extradriverdata.sessionCategory = FMOD_IPHONE_SESSIONCATEGORY_MEDIAPLAYBACK;
//	extradriverdata.forceMixWithOthers = true;
//	ERRCHECK(fmodsys->init(1, FMOD_INIT_NORMAL, &extradriverdata));
//	ERRCHECK(FMOD_IPhone_MixWithOtherAudio(TRUE));
	
	specL = (float*)malloc(SPECLEN*sizeof(float));
	specR = (float*)malloc(SPECLEN*sizeof(float));

	forceState_ = new ForceState();
	forceState_->setOffset((ForceEmitter*)new FEperlin(NULL));
	emitters_.push_back((ForceEmitter*)new FEspinning(forceState_));
	emitters_.push_back((ForceEmitter*)new FEupwards(forceState_));
	/*emitters_.push_back((ForceEmitter*)new FEline(forceState_)); // not to be used*/
	emitters_.push_back((ForceEmitter*)new FEquad(forceState_));
	emitters_.push_back((ForceEmitter*)new FEspine(forceState_));
	emitters_.push_back((ForceEmitter*)new FEpushPull(forceState_));
	
	for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
		(*it)->state()->setStrength(AUTOMATIC_LEVEL);
		(*it)->stop();
	}
	vector<ForceEmitter*>::iterator iter = emitters_.begin();
	for (int i = 0; i < AUTO_SIMULTANEOUS_INPUTS; i++) {
		automatingEmitters.push_back(iter);
		iter++;
	}
	lastTransition = CFAbsoluteTimeGetCurrent();
	
	automatic_ = true;
	repeat_ = false;
	colorWalk_ = false;
	
	loaded_ = false;
	running_ = false;
	
	colorWalker_ = new ColorWalk();
}

Visualizer::~Visualizer()
{
	stop();
	ERRCHECK(fmodsys->release());
	free(specL);
	free(specR);
	for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
		delete (ForceEmitter*)(*it);
	}
	delete forceState_;
	automatingEmitters.clear();
	
	delete colorWalker_;
}

void
Visualizer::simulate(float dt)
{
	bool syncUI = false; // Set if we need a UI refresh, send notification once at end
	if (running_) {
		if (automatic_) {
			CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
			CFAbsoluteTime timeDelta = currentTime - lastTransition;
			if (timeDelta > AUTO_TRANSITION_TIME_S) {
				lastTransition = currentTime;
				
				// Randomly choose an active emitter, turn it off,
				// find a new inactive emitter and turn it on
				bool haveMoved = false;
				while (!haveMoved) {
					int newPosition = rand() % emitters_.size();
					bool newPositionIsInactive = true;
					for (vector<vector<ForceEmitter*>::iterator>::iterator scanner = automatingEmitters.begin(); scanner < automatingEmitters.end(); ++scanner) {
						if(*scanner == emitters_.begin() + newPosition) {
							newPositionIsInactive = false;
						}
					}
					if(newPositionIsInactive) {
						int automatingEmitterToMove = rand() % automatingEmitters.size();
						(**automatingEmitters[automatingEmitterToMove]).state()->setStrength(0.);
						(**automatingEmitters[automatingEmitterToMove]).stop();
						automatingEmitters[automatingEmitterToMove] = emitters_.begin() + newPosition;
						(**automatingEmitters[automatingEmitterToMove]).start();
						(**automatingEmitters[automatingEmitterToMove]).state()->setStrength(AUTOMATIC_LEVEL);
						haveMoved = true;
					}
				}		
			}
			syncUI = true;
		}
		
		bool paused = true;
		if (fmodchn)
			ERRCHECK(fmodchn->getPaused( &paused ));
		if ( !paused )
		{
//			ERRCHECK(fmodchn->getSpectrum( specL, SPECLEN, 0, FMOD_DSP_FFT_WINDOW_BLACKMAN ));
//			ERRCHECK(fmodchn->getSpectrum( specR, SPECLEN, 1, FMOD_DSP_FFT_WINDOW_BLACKMAN ));
		} else {
			memset( specL, 0, SPECLEN*sizeof(float) );
			memset( specR, 0, SPECLEN*sizeof(float) );
		};
		FMOD_TIMEUNIT timeUnit = FMOD_TIMEUNIT_PCM;
		unsigned int length,position;
		ERRCHECK(fmodsnd->getLength(&length, timeUnit));
		ERRCHECK(fmodchn->getPosition(&position, timeUnit));
		if (length <= position) {
			stop();
		}
		
		float lows = 0.;
		float mids = 0.;
		float highs = 0.;
		int iterations = floor(SPECLEN/3);
		for (int i = 0; i < iterations; i++) {
			lows += specL[i] + specR[i];
			mids += specL[iterations+i] + specR[iterations+i];
			highs += specL[(iterations*2)+i] + specR[(iterations*2)+i];
		}
		lows /= iterations * 2.;
		mids /= iterations * 2.;
		highs /= iterations * 2.;
		
		lows *= 10.;
		mids *= 100.;
		highs *= 1000.;
		
//		NSLog(@"lows:%f mids:%f highs:%f", lows, mids, highs);
		for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
			if ((*it)->state()->active() && (*it)->state()->strength() > 0.05) {
				(*it)->simulate(dt, lows, mids, highs);
			}
		}
		
		if(colorWalk_) {
			ColorSet colors = colorWalker_->simulate(lows+mids+highs);
			gGravilux->params()->setColorsWalk(colors);
		}
		
		if(running_ && automatic_) {
			this->syncUILevels();
		}
	}
}

void
Visualizer::load(const char *path)
{
	fmodchn = 0;
	fmodsnd = 0;
//	ERRCHECK(fmodsys->createSound(path, FMOD_SOFTWARE | FMOD_2D | FMOD_CREATESTREAM | FMOD_LOOP_NORMAL, 0, &fmodsnd));
//	ERRCHECK(fmodsys->playSound(FMOD_CHANNEL_FREE,fmodsnd,true,&fmodchn));
	ERRCHECK(fmodchn->setLoopCount(repeat_?-1:0));
	
	loaded_ = (fmodchn && fmodsnd);
}

void
Visualizer::start()
{
	if (fmodchn) {
//		ERRCHECK(FMOD_IPhone_MixWithOtherAudio(false));
		ERRCHECK(fmodchn->setPaused(false));
		running_ = true;
		for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
			(*it)->start();
		}
		gGravilux->params()->setColorSource(colorWalk_);
	}
	syncUI();
}

void
Visualizer::stop()
{
	running_ = false;
	for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
		(*it)->stop();
	}
	if (fmodchn) {
		ERRCHECK(fmodchn->setPaused(true));
//		ERRCHECK(FMOD_IPhone_MixWithOtherAudio(true));
	}
	gGravilux->params()->setColorSource(false);
	syncUI();
}

int
Visualizer::nEmitters()
{
	return emitters_.size();
}

float
Visualizer::emitterStrength(int i)
{
	if (i < 0 || i >= nEmitters()) {
		return -1.;
	}
	return emitters_[i]->state()->strength();
}

void
Visualizer::setEmitterStrength(int i, float strength)
{
	if (i >= 0 && i < nEmitters()) {
		emitters_.at(i)->state()->setStrength(strength);
	}
}

bool
Visualizer::emitterState(int i)
{
	if (i < 0 || i >= nEmitters()) {
		return false;
	}
	return emitters_[i]->state()->active();
}

void
Visualizer::setEmitterState(int i, bool active)
{
	if (i >= 0 && i < nEmitters()) {
		if (active)
			emitters_.at(i)->start();
		else
			emitters_.at(i)->stop();
	}
}


void
Visualizer::automatic(bool a)
{
	automatic_ = a;
	for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
		(*it)->start();
		(*it)->state()->setStrength(0.);
	}
	
	if(automatic_) {
		for (vector<vector<ForceEmitter*>::iterator>::iterator it = automatingEmitters.begin(); it != automatingEmitters.end(); ++it) {
			(**it)->state()->setStrength(AUTOMATIC_LEVEL);
		}
	}
	syncUILevels();
	syncUI();
};

bool
Visualizer::repeat()
{
	if (fmodchn) {
		int loopcount = 0;
		ERRCHECK(fmodchn->getLoopCount(&loopcount)); // Return what is actually happening, not what we expect

		repeat_ = (loopcount == -1);
	}
	return repeat_;
}
void
Visualizer::repeat(bool b)
{
	repeat_ = b;
	if(fmodchn) {
		int loopCount = repeat_?-1:0;
		ERRCHECK(fmodchn->setLoopCount(loopCount));
	}
	syncUI();
}

void
Visualizer::colorWalk(bool c)
{
	colorWalk_ = c;
	gGravilux->params()->setColorSource(c);
	syncUI();
}

void
Visualizer::syncUI()
{
	
	if (fmodchn) {
		int loopCount = 0;
		ERRCHECK(fmodchn->getLoopCount( &loopCount ));
		repeat_ = (loopCount == -1);
		
		bool paused = true;
		ERRCHECK(fmodchn->getPaused( &paused ));
		running_ = !paused;
	}
	gGravilux->params()->setColorSource(running_ && colorWalk_);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateUIVisualizer" object:nil];
}

void
Visualizer::syncUILevels()
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateUIVisualizerLevels" object:[NSNotificationCenter defaultCenter]];
}
