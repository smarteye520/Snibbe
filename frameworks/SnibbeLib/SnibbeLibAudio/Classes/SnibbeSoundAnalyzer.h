//
//  SnibbeSoundAnalyzer.h
//  SnibbeLib
//
//  Created by Colin Roache on 5/8/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#pragma once
#include "SnibbeAudioUtils.h"
#define FMOD_FFT_REQUEST_WINDOW_WIDTH_DEFAULT	64
#define SPECTRUM_WIDTH_DEFAULT					3

class SnibbeSoundAnalyzer
{
private:
	bool			cached_;
	FMOD::Channel	*channel_;
	void			fillCache();
	
protected:
	float			*spectrums_[2];
	uint			spectrumWidth_,
					FMODWidth_;
	
public:
	SnibbeSoundAnalyzer();
	~SnibbeSoundAnalyzer();
	
	void	setChannel(FMOD::Channel *channel) { channel_ = channel; };
	
	void	clearCache();
	
	void spectrumStereo(float **leftSpectrum, float **rightSpectrum);
	void spectrumMono(float **monoSpectrum);
	uint spectrumWidth() { return spectrumWidth_; };
	void setSpectrumWidth(uint w);
};
