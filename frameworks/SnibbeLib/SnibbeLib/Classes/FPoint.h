//
//  FPoint.h
//  SnibbeLib
//
//  Created by Colin Roache on 6/18/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_FPoint_h
#define SnibbeLib_FPoint_h

typedef struct FPoint {
	FPoint() { x = y = 0.f; }
	FPoint(float _x, float _y) : x(_x), y(_y) {}
	FPoint(float *v) : x(*v), y(*(v+1)) {}
	
	FPoint & operator+=(const FPoint &rhs) {
		x += rhs.x;
		y += rhs.y;
		return *this;
	}
	FPoint & operator+=(const float &rhs) {
		x += rhs;
		y += rhs;
		return *this;
	}
	FPoint & operator-=(const FPoint &rhs) {
		x -= rhs.x;
		y -= rhs.y;
		return *this;
	}
	FPoint & operator-=(const float &rhs) {
		x -= rhs;
		y -= rhs;
		return *this;
	}
	FPoint & operator*=(const FPoint &rhs) {
		x *= rhs.x;
		y *= rhs.y;
		return *this;
	}
	FPoint & operator*=(const float &rhs) {
		x *= rhs;
		y *= rhs;
		return *this;
	}
	FPoint & operator/=(const FPoint &rhs) {
		x /= rhs.x;
		y /= rhs.y;
		return *this;
	}
	FPoint & operator/=(const float &rhs) {
		x /= rhs;
		y /= rhs;
		return *this;
	}
	FPoint operator+(const FPoint rhs) const {
		FPoint result = *this;
		result += rhs;
		return result;
	}
	FPoint operator+(const float rhs) const {
		FPoint result = *this;
		result += rhs;
		return result;
	}
	FPoint operator-(const FPoint rhs) const {
		FPoint result = *this;
		result -= rhs;
		return result;
	}
	FPoint operator-(const float rhs) const {
		FPoint result = *this;
		result -= rhs;
		return result;
	}
	FPoint operator*(const FPoint rhs) const {
		FPoint result = *this;
		result *= rhs;
		return result;
	}
	FPoint operator*(const float rhs) const {
		FPoint result = *this;
		result *= rhs;
		return result;
	}
	FPoint operator/(const FPoint rhs) const {
		FPoint result = *this;
		result /= rhs;
		return result;
	}
	FPoint operator/(const float rhs) const {
		FPoint result = *this;
		result /= rhs;
		return result;
	}
	FPoint perp() const {
		return cross();
	}
	FPoint cross() const {
		return FPoint(-y, x);
	}
	double cross(const FPoint p) const {
		return x*p.y - y*p.x;
	}
	float dot(const FPoint p) const {
		return x*p.x + y*p.y;
	}
	float mag() const {
		return sqrtf(mag2());
	}
	float mag2() const {
		return x*x+y*y;
	}
	FPoint normalized() {
		float magnitude = mag();
		return FPoint(x/magnitude, y/magnitude);
	}
	float x;
	float y;
} FPoint;

#endif
