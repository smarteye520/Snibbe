#pragma once
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "ofxMSAShape3D.h"

class Grain;
class Parameters;
class Force;
class ForceState;
class Visualizer;

//#define MINROWS 2
//#define MAXROWS 200
//#define DEFHEATSCALE 0.0001
#define GRAVITY_CONSTANT 5000
#define SHAKE_FORCE 2.0
#define MAXTOUCHES 10

class Gravilux  {
	
public:
	Gravilux();
	~Gravilux();
	
	void setup();
	void update();
	void draw();
	void exit();
	
	void drawInContext(CGContextRef ctx);
	void drawVertexArray();
	void drawForceState(ForceState * fs = NULL);
	
	void keyPressed(int key) {}
	void keyReleased(int key)  {}
	
	ForceState * forceState() { return forceState_; };
	Visualizer * visualizer() { return visualizer_; };
//	void touches(NSSet * touches);
//	void touchesBegan(NSSet * touches);
//	void touchesMoved(NSSet * touches);
//	void touchesEnded(NSSet * touches);
	
	void gotMemoryWarning();
	void deviceOrientationChanged(int newOrientation);
	
	void initGrains();
	void resetGrains();
	void resetGrainsType(NSString * text, UIInterfaceOrientation orientation, int rowSkip);
	UIImage * renderType(NSString * text, UIInterfaceOrientation orientation);
	void resetGrainsRandomImage(UIImage *image);
	void resetGrainsMatrixImage(UIImage *imageRef, int rowSkip);
	void resetGrainsFontImage(unsigned char * data, int rowSkip);
	void initTextures();
	void showHeat(bool h);
	void showHeatColor(bool h);
	void setStarSize(int s);
	bool interactedYet() { return interactedYet_; };
	void resetIdleTimer(bool set);
	bool running() { return running_; };
	void setRunning(bool r) { running_ = r; }
	Parameters* params() { return params_; }
	
	//vector<ofImage*> textures() { return textures_; }
	
	CGContextRef createPDFFile(CGRect pageRect, const char *filename);
	bool drawToPDF(NSString *path,
				   float dotSize, // all values in points, 72dpi
				   float pointWidth, float pointHeight);
	
private:	
//	InterfaceViewController		*interfaceViewController_;
	Parameters					*params_;
	
	
	ofxMSAShape3D vertexArrayObject;
	
	Grain**		grains_;
	//vector<ofImage*>	textures_;
	int			nGrains_;
	int			nAllocGrains_;
	bool		running_, drawVertexArray_;
	float		sizeScale_;//, heatScale_;
	float		dt_, actualDt_, lastTime_;
	bool		interactedYet_, bottomTap_, firstTap_, showSplash_;
	float		maxVelocity_;
	
//	FPoint		touchPoints_[MAXTOUCHES];
//	bool		touchDown_[MAXTOUCHES];
//	NSSet		 *activeTouches;
	ForceState	*forceState_;
	Visualizer	*visualizer_;
	
	void allocGrains();
	void allocGrains(int nGrains);
	void wrapGrains();
	bool applyForceState(ForceState* fs, bool addForce);
//	void applyPointForce(Force* force, bool addForce);
	void clearPointForces();
//	bool isShaking(float threshold);
	void simulate(float dt);
	void setDamp(float d);
	void drawGrains();
};

