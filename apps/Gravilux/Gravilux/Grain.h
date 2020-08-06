/*
 * Grain.h
 * Scott Snibbe
 *
 * (c) 1998-2010
 */

#pragma once

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#include "defs.h"
#include "ofxMSAShape3D.h"

#define ROUNDINT( d ) ((int)((d) + ((d) > 0 ? 0.5 : -0.5)))

class Grain {
public:
	Grain(CGPoint p, float mass = 1.0, float damp = 0.95, float heatScale = 0.003);
	
	void	applyForce(CGPoint f, bool addForce = false);
	void	applyForce(FPoint f, bool addForce = false);
	void	simulate(float dt);

	void	clearForce();

	void	draw();
	void	drawColor(Color *colors, int nColors);
	void	drawToPDF(CGContextRef pdfContext, float dotRadius, 
					  FPoint ptScale, int pointWidth, int pointHeight);

	void	drawToPDFColor(CGContextRef pdfContext, float dotRadius, FPoint ptScale, 
						   int pointWidth, int pointHeight, bool drawColor, Color *colors, int nColors);
	
	void drawCG(CGContextRef ctx);
	void drawColorCG(CGContextRef ctx, Color *colors, int nColors);
	
	void copyVertex(float * dstPtr);
	
	void drawVertexArray(ofxMSAShape3D *vertexArray);
	void drawVertexArrayColor(ofxMSAShape3D *vertexArray, Color *colors, int nColors);
	
	CGPoint pos() const { return pos_; }
	void	pos(CGPoint p) { pos_ = p; }

	CGPoint	vel() const { return vel_; }
	void	vel(CGPoint p) { vel_ = p; }

	float	damp() const { return damp_; }
	void	damp(float d) { damp_ = d; }
	
	float	radius() const { return radius_; }
	void	radius(float r) { radius_ = r; }
	
	float	heatScale() const { return heatScale_; }
	void	heatScale(float s) { heatScale_ = s; }

	void	showHeat(int val) { showHeat_ = val; }
	int		showHeat() { return showHeat_; }
	
	void	size(int s) { size_ = s; radius_ = (((float)s - 1)/ 7.0) * 1.5 + 0.5; } // 1-8 maps to 0.5 - 2
	int		size() { return size_; }
	
	void	setColorAnchors(CGColorRef	c1, CGColorRef c2, CGColorRef c3);
	CGColorRef	getGrey();
	CGColorRef	getColor(Color *colors, int nColors);
	float	getColorInterpValue();
private:

	void	drawDot();
	void	drawDotCG(CGContextRef ctx);

	CGPoint	pos_, lastPos_;
	CGPoint	vel_;
	CGPoint	acc_;

	float	damp_;
	float   mass_;
	float	massInv_;
	float	radius_;
	float	heatScale_; 

	bool	showHeat_, showColor_;
	//ofImage	*texture_;
	int		size_;
};

inline void
Grain::copyVertex(float * dstPtr) {
	(*dstPtr) = pos_.x;
	*(dstPtr+1) = pos_.y;
	*(dstPtr+2) = 0;
}

inline float
Grain::getColorInterpValue()
{
	float cval = 1;
	float length = vel_.x*vel_.x + vel_.y*vel_.y;
	cval = ((length*heatScale_)) + RANDOM(-0.078, 0.078);
	if (cval < 0) cval = 0;
	if (cval > 1) cval = 1;
	
	return cval;
}

inline CGColorRef
Grain::getGrey()
{
	float cval = 255;
	float length = vel_.x*vel_.x + vel_.y*vel_.y;
	cval = (255*(length*heatScale_)) + RANDOM(-20,20);
	if (cval < 0) cval = 0;
	if (cval > 255) cval = 255;
	
	CGColorRef c = CGColorCreate(CGColorSpaceCreateDeviceRGB(), (CGFloat[]){cval, cval, cval});
	return c;
}

inline CGColorRef
Grain::getColor(Color *colors, int nColors)
{
	int i1, i2;
	
	// interpolate between color anchors  $$$ - hardcoded to 3
	assert(nColors == 3);
	
	float interp = getColorInterpValue();
	
	if (interp < 0.5) {
		i1 = 0; i2 = 1;
		interp = interp * 2;
	} else {
		i1 = 1; i2 = 2;
		interp = (interp - 0.5) * 2;
	}
	
	CGColorRef cRef =  CGColorCreate(CGColorSpaceCreateDeviceRGB(), (CGFloat[]){LERP(colors[i1].r, colors[i2].r, interp), LERP(colors[i1].g, colors[i2].g, interp), LERP(colors[i1].b, colors[i2].b, interp)});	
	return cRef;
}

#if 0
inline void
Grain::drawDot()
{
	/*
	// switch size
	if (size_ == 1) {
		ofLine(ROUNDINT(pos_.x), ROUNDINT(pos_.y), ROUNDINT(pos_.x+1), ROUNDINT(pos_.y+1));

	} else {
		gTextures[size_-2]->draw(pos_.x, pos_.y);
	
	}
	*/
	
	//gTextures[size_-1]->draw(pos_.x, pos_.y);
	
	switch (size_) {
		default:
		case 1:
			ofLine(pos_.x, pos_.y, pos_.x+1, pos_.y);
			//ofLine(ROUNDINT(pos_.x), ROUNDINT(pos_.y), ROUNDINT(pos_.x+1), ROUNDINT(pos_.y+1));
			break;
		case 2:
			//ofLine(pos_.x-1, pos_.y, pos_.x+1, pos_.y);
			//ofLine(pos_.x, pos_.y-1, pos_.x, pos_.y+1);
			ofCircle(pos_.x, pos_.y, 1);
			//ofLine(ROUNDINT(pos_.x-1), ROUNDINT(pos_.y), ROUNDINT(pos_.x+1), ROUNDINT(pos_.y));
			//ofLine(ROUNDINT(pos_.x), ROUNDINT(pos_.y-1), ROUNDINT(pos_.x), ROUNDINT(pos_.y+1));
			break;
		case 3:
			ofCircle(pos_.x, pos_.y, 1.25);
			//ofRect(pos_.x-1, pos_.y-1, 2, 2);
			break;	
		case 4:
			ofCircle(pos_.x, pos_.y, 1.5);
			//ofLine(pos_.x-2, pos_.y, pos_.x+2, pos_.y);
			//ofLine(pos_.x, pos_.y-2, pos_.x, pos_.y+2);
			break;	
		case 5:
			ofCircle(pos_.x, pos_.y, 1.75);
			break;	
		case 6:
			ofCircle(pos_.x, pos_.y, 2.0);
			break;	
		case 7:
			ofCircle(pos_.x, pos_.y, 2.25);
			break;	
		case 8:
			ofCircle(pos_.x, pos_.y, 2.5);
			break;	
	}
	
}

inline void
Grain::draw()
{
	CGColor	c;
	
	if (showHeat_) {
		getGrey(c);
		
		ofSetColor(c.r, c.g, c.b, c.a);
	}
	drawDot();
}

inline void
Grain::drawColor(Color *colors, int nColors)
{
	CGColor	c;
	
	getColor(c, colors, nColors);
	
	ofSetColor(c.r*255.0, c.g*255.0, c.b*255.0, 255.0);
	
	drawDot();
}

inline void
Grain::drawCG(CGContextRef ctx)
{	
	CGColor	c;

	if (showHeat_) {
		getGrey(c);

		CGContextSetRGBStrokeColor(ctx, c.r/255.0, c.g/255.0, c.b/255.0, c.a/255.0);
	}
	CGContextSetLineWidth(ctx, radius_);
	CGContextSetLineCap(ctx, kCGLineCapSquare);
	
	CGContextMoveToPoint(ctx, pos_.x, pos_.y);
	CGContextAddLineToPoint(ctx, pos_.x, pos_.y);
	
	CGContextStrokePath(ctx);
}


#endif

inline void
Grain::drawVertexArrayColor(ofxMSAShape3D *vertexArray, Color *colors, int nColors)
{
	CGColorRef	c = getColor(colors, nColors);
	
	const CGFloat *compoents = CGColorGetComponents(c);

	vertexArray->setColor(compoents[0], compoents[1], compoents[2], 1.);
	
	CGColorRelease(c);
	
	vertexArray->addVertex(pos_.x, pos_.y);
}

inline void 
Grain::drawVertexArray(ofxMSAShape3D *vertexArray)
{
	CGColorRef	c;
	
	if (showHeat_) {
		c = getGrey();
		
		const CGFloat *compoents = CGColorGetComponents(c);
		
		vertexArray->setColor(compoents[0], compoents[1], compoents[2], 1.);
		
		CGColorRelease(c);
	}
	
	vertexArray->addVertex(pos_.x, pos_.y);
}

#define POINT_SCREEN_TO_PAGE(PS) { (PS).x *= ptScale.x; (PS).y *= ptScale.y; (PS).y = pointHeight - (PS).y; }

inline void
Grain::drawToPDFColor(CGContextRef pdfContext, float dotRadius, FPoint ptScale, 
					  int pointWidth, int pointHeight, bool drawColor, Color *colors, int nColors)
{
	CGColorRef	c;
	
	if (drawColor) {
//		getColor(c, colors, nColors);
//		CGContextSetRGBFillColor(pdfContext, c.r,c.g,c.b, 1);

	} else if (showHeat_) {
//		getGrey(c);	
		
//		CGContextSetRGBFillColor(pdfContext, c.r/255.0,c.g/255.0,c.b/255.0, 1);		
	} else {
//		CGContextSetRGBFillColor(pdfContext, 1,1,1, 1);
	}

	FPoint pt;
	pt.x = pos_.x; 
	pt.y = pos_.y;
	
	POINT_SCREEN_TO_PAGE(pt);
	
	CGRect pointRect = CGRectMake(0, 0, dotRadius*2, dotRadius*2);
	
	pointRect.origin.x = pt.x - dotRadius;
	pointRect.origin.y = pt.y - dotRadius;
	
	CGContextFillEllipseInRect(pdfContext, pointRect);
}
						   
inline void
Grain::drawToPDF(CGContextRef pdfContext, float dotRadius, FPoint ptScale, 
					  int pointWidth, int pointHeight)
{
	drawToPDFColor(pdfContext, dotRadius, ptScale, pointWidth, pointHeight, NO, nil, 0);
}

inline void	
Grain::applyForce(CGPoint f, bool addForce)
{
	if (!addForce)
		acc_.x = acc_.y = 0;
	acc_.x += f.x * massInv_;
	acc_.y += f.y * massInv_;
}

inline void	
Grain::applyForce(FPoint f, bool addForce)
{
	if (!addForce)
		acc_.x = acc_.y = 0;
	acc_.x += f.x * massInv_;
	acc_.y += f.y * massInv_;
}
