//
//  SSClock.h
//  SnibbeLib
//
//  Created by Colin Roache on 6/20/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_SSClock_h
#define SnibbeLib_SSClock_h
#include <vector>
class SSClock {
private:
	SSClock();
	
	float	time_;
	float	pauseOffset_, pauseTime_;
	bool	paused_;
	std::vector<bool> pauses_;
	
protected:
	float	systemTime();
	
public:
	static SSClock& clock(void * key=0);
	void update(float t);
	void reset();
	void pause();
	void resume();
	bool paused() { return paused_; };
	~SSClock();
	
	float	timef();
};

#endif
