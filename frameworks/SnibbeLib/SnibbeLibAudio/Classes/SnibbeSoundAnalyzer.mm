//
//  SnibbeSoundAnalyzer.mm
//  SnibbeLib
//
//  Created by Colin Roache on 5/8/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeSoundAnalyzer.h"

SnibbeSoundAnalyzer::SnibbeSoundAnalyzer()
{
	FMODWidth_ = FMOD_FFT_REQUEST_WINDOW_WIDTH_DEFAULT;
	spectrums_[0] = (float*)malloc(FMODWidth_*sizeof(float));
	spectrums_[1] = (float*)malloc(FMODWidth_*sizeof(float));
	setSpectrumWidth(SPECTRUM_WIDTH_DEFAULT);
}

SnibbeSoundAnalyzer::~SnibbeSoundAnalyzer()
{
	free(spectrums_[0]);
	free(spectrums_[1]);
}

void
SnibbeSoundAnalyzer::spectrumStereo(float **leftSpectrum, float **rightSpectrum)
{
	fillCache();
	*leftSpectrum = spectrums_[0];
	*rightSpectrum = spectrums_[1];
}

void
SnibbeSoundAnalyzer::spectrumMono(float **monoSpectrum)
{
	fillCache();
	for (int i = 0; i < FMODWidth_; i++) {
		(*monoSpectrum)[i] = (spectrums_[0][i] + spectrums_[1][i]) / 2.f;
	}
}

void
SnibbeSoundAnalyzer::setSpectrumWidth(uint w)
{
	spectrumWidth_ = w;
}

void
SnibbeSoundAnalyzer::fillCache()
{
	if (!cached_) {
		cached_ = TRUE;
		bool paused = true;
		if (channel_)
			ERRCHECK(channel_->getPaused( &paused ));
		if ( !paused )
		{
			ERRCHECK(channel_->getSpectrum( spectrums_[0], FMODWidth_, 0, FMOD_DSP_FFT_WINDOW_BLACKMAN ));
			ERRCHECK(channel_->getSpectrum( spectrums_[1], FMODWidth_, 1, FMOD_DSP_FFT_WINDOW_BLACKMAN ));
		} else {
			memset( spectrums_[0], 0, FMODWidth_*sizeof(float) );
			memset( spectrums_[1], 0, FMODWidth_*sizeof(float) );
		};
	}
}

void
SnibbeSoundAnalyzer::clearCache()
{
	cached_ = FALSE;
}