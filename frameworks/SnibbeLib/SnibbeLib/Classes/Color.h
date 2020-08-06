//
//  Color.h
//  SnibbeLib
//
//  Created by Scott Snibbe on 6/27/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_Color_h
#define SnibbeLib_Color_h

typedef struct Color {
	Color() { c[0]=c[1]=c[2]=c[3] = 0.f; }
	Color(float r, float g, float b, float a=1.0f) { c[0]=r; c[1]=g; c[2]=b; c[3]=a; }
	Color(Color *c2) { for (int i=0;i<4;i++) c[i] = c2->c[i]; }
    
    void set(float r, float g, float b, float a = 1.0f) { c[0]=r; c[1]=g; c[2]=b; c[3]=a; }
    void setRGB(float *values) { for (int i=0;i<3;i++) c[i] = values[i]; values[3] = 1.0f; }
    void setRGBA(float *values) { for (int i=0;i<4;i++) c[i] = values[i]; }
    
    void setR( float r ) { c[0] = r; }
    void setG( float g ) { c[1] = g; }
    void setB( float b ) { c[2] = b; }
    void setA( float a ) { c[3] = a; }
    
    float r() const {return c[0];}
    float g() const {return c[1];}
    float b() const {return c[2];}
    float a() const {return c[3];}
    
    float* values()    { return c; }
    
    float& operator[] (int x) { // works?
        return c[x];
    }
	
	Color & operator+=(const Color &rhs) {
        for (int i=0;i<4;i++) c[i] += rhs.c[i];
		return *this;
	}
	Color & operator+=(const float &rhs) {
        for (int i=0;i<4;i++) c[i] += rhs;
		return *this;
	}
	Color & operator-=(const Color &rhs) {
        for (int i=0;i<4;i++) c[i] -= rhs.c[i];
		return *this;
	}
	Color & operator-=(const float &rhs) {
        for (int i=0;i<4;i++) c[i] -= rhs;
		return *this;
	}
	Color & operator*=(const Color &rhs) {
        for (int i=0;i<4;i++) c[i] *= rhs.c[i];
		return *this;
	}
	Color & operator*=(const float &rhs) {
        for (int i=0;i<4;i++) c[i] *= rhs;
		return *this;
	}
	Color & operator/=(const Color &rhs) {
        for (int i=0;i<4;i++) c[i] /= rhs.c[i];
		return *this;
	}
	Color & operator/=(const float &rhs) {
        for (int i=0;i<4;i++) c[i] /= rhs;
		return *this;
	}
	Color operator+(const Color rhs) const {
		Color result = *this;
		result += rhs;
		return result;
	}
	Color operator+(const float rhs) const {
		Color result = *this;
		result += rhs;
		return result;
	}
	Color operator-(const Color rhs) const {
		Color result = *this;
		result -= rhs;
		return result;
	}
	Color operator-(const float rhs) const {
		Color result = *this;
		result -= rhs;
		return result;
	}
	Color operator*(const Color rhs) const {
		Color result = *this;
		result *= rhs;
		return result;
	}
	Color operator*(const float rhs) const {
		Color result = *this;
		result *= rhs;
		return result;
	}
	Color operator/(const Color rhs) const {
		Color result = *this;
		result /= rhs;
		return result;
	}
	Color operator/(const float rhs) const {
		Color result = *this;
		result /= rhs;
		return result;
	}

    // $$$ add in conversion to/from hsv
    // $$$ add in conversion to byte colors
    
	float c[4];
} Color;


#endif
