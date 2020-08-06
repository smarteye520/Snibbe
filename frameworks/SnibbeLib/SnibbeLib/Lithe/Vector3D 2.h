/* Vector class
 *
 * Interface is based on the Inventor SbVec3f class,
 * with my own implementation.
 *
 * Scott Snibbe
 * (c) 1998
 */

#pragma once

#ifndef VECTOR_H
#define VECTOR_H

#ifndef ABS
#define ABS(X) ((X) < 0 ? -(X) : (X))
#endif

#include <math.h>
#include <cmath>

class Vector {
  public:
    // Default constructor
    Vector()	{ vec[0] = vec[1] = vec[2] = 0; }

    // Constructor given an array of 3 components
    Vector(const float v[3])
	 { vec[0] = v[0]; vec[1] = v[1]; vec[2] = v[2]; }

    // Constructor given 3 individual components
    Vector(float x, float y, float z=0.0)
	 { vec[0] = x; vec[1] = y; vec[2] = z; }

    // Returns right-handed cross product of vector and another vector
    Vector	cross(const Vector &v) const;

	float dot2d(const Vector &v) { return this->x()*v.x() + this->y()*v.y(); }
	float cross2d(const Vector &v) { return this->x()*v.y() - v.x()*this->y(); }

    // Returns dot (inner) product of vector and another vector
    float	dot(const Vector &v) const { return ( this->x() * v.x() + this->y() * v.y() + this->z() * v.z() ); }
    
	// compute the angle between 2 vectors, 0-2pi
	float angle(const Vector &v2);

    // Returns pointer to array of 3 components
    const float	*getValue() const	{ return vec; }

    // Returns 3 individual components
    void	getValue(float &x, float &y, float &z) const;

    float x() const { return vec[0]; }
    float y() const { return vec[1]; }
    float z() const { return vec[2]; }

	void x(float v) { vec[0] = v; }
	void y(float v) { vec[1] = v; }
	void z(float v) { vec[2] = v; }

    // Returns geometric length of vector
    float	length() const { return sqrt(dot(*this)); }
    float   lengthSq() { return dot(*this); }

    // Changes vector to be unit length, returns length before normalization
    float	normalize();

    // Negates each component of vector in place
    void	negate();

	// Absolute value in place
	Vector &	abs() { vec[0] = ABS(vec[0]); vec[1] = ABS(vec[1]); vec[2] = ABS(vec[2]); return *this; }

    // Sets value of vector from array of 3 components
    Vector &	setValue(const float v[3])
	 { vec[0] = v[0]; vec[1] = v[1]; vec[2] = v[2]; return *this; }

    // Sets value of vector from 3 individual components
    Vector &	setValue(float x, float y, float z)
	 { vec[0] = x; vec[1] = y; vec[2] = z; return *this; }

    // Accesses indexed component of vector
    float &	  operator [](int i) 		{ return (vec[i]); }
    const float & operator [](int i) const	{ return (vec[i]); }

    Vector &	operator =(Vector v) 
	{ setValue(v.vec); return *this; }

    // Component-wise scalar multiplication and division operators
    Vector &	operator *=(float d);
    Vector &	operator /=(float d)
	{ return *this *= (1.0 / d); }

	// Component-wise multiplication and division
    Vector &	operator *=(Vector v);
    Vector &	operator /=(Vector v);

	// Component-wise vector addition and subtraction operators
    Vector &	operator +=(Vector v);
    Vector &	operator -=(Vector v);

    // Nondestructive unary negation - returns a new vector
    Vector	operator -() const;

    // Component-wise binary scalar multiplication and division operators
    friend Vector	operator *(const Vector &v, float d);
    friend Vector	operator *(float d, const Vector &v)
	{ return v * d; }
    friend Vector	operator /(const Vector &v, float d)
	{ return v * (1.0 / d); }

    // Component-wise binary vector addition and subtraction operators
    friend Vector	operator +(const Vector &v1, const Vector &v2);
    friend Vector	operator -(const Vector &v1, const Vector &v2);

    friend Vector	operator *(const Vector &v1, const Vector &v2);
    friend Vector	operator /(const Vector &v1, const Vector &v2);

    // Equality comparison operator
    friend int		operator ==(const Vector &v1, const Vector &v2);
    friend int		operator !=(const Vector &v1, const Vector &v2)
	{ return !(v1 == v2); }

	friend int		operator <(const Vector &v1, const Vector &v2)
	{ return (void*)&v1 < (void*)&v2; }

    // Equality comparison within given tolerance - the square of the
    // length of the maximum distance between the two vectors
    int		        equals(const Vector v, float tolerance) const;

  protected:
    float	vec[3];		// Storage for vector components
};

#ifndef M_PI
#define M_PI 3.141592654
#endif

//#define IS_NAN(F) ((F) != (F))

inline Vector
Vector::cross(const Vector &v) const
{
     Vector vc;

     vc.vec[0] = y() * v.z() - z() * v.y();
     vc.vec[1] = -x() * v.z() + z() * v.x();
     vc.vec[2] = x() * v.y() - y() * v.x();

     return vc;
}

// normalize before calling! $$$$
inline float
Vector::angle(const Vector &v2)
{
	float dot = this->dot2d(v2);
	float cross = this->cross2d(v2);

	// 0 to 2pi
	float angle = acosf(dot);
	if (cross < 0) angle = M_PI * 2 - angle;
    
    // sometimes the above makes NaN - quick fix
    if (std::isnan(angle))
        angle = 0.0;

	return angle;
}

inline void
Vector::getValue(float &x, float &y, float &z) const
{
     x = this->x(); y = this->y(); z = this->z();
}

/*
float
Vector::length() const
{
     return sqrt(dot(*this));
}
*/

inline float
Vector::normalize()
{
     float length = this->length();

	 if (length != 0) {
		*this /= length;
	 }

     return length;
}

inline void
Vector::negate()
{
     vec[0] = -vec[0];
     vec[1] = -vec[1];
     vec[2] = -vec[2];
}

inline Vector&
Vector::operator *=(float d) {
     vec[0] *= d;
     vec[1] *= d;
     vec[2] *= d;

     return *this;
}

inline Vector&
Vector::operator +=(Vector v) {
     vec[0] += v.x();
     vec[1] += v.y();
     vec[2] += v.z();

     return *this;
}

inline Vector&
Vector::operator *=(Vector v) {
     vec[0] *= v[0];
     vec[1] *= v[1];
     vec[2] *= v[2];

     return *this;
}
inline Vector&
Vector::operator /=(Vector v) {
     vec[0] /= v[0];
     vec[1] /= v[1];
     vec[2] /= v[2];

     return *this;
}


inline Vector&
Vector::operator -=(Vector v) {
     vec[0] -= v.x();
     vec[1] -= v.y();
     vec[2] -= v.z();

     return *this;
}

inline Vector
Vector::operator -() const {
     Vector v;
     v.vec[0] = -x();
     v.vec[1] = -y();
     v.vec[2] = -z();

     return v;
}

inline Vector
operator *(const Vector &v, float d)
{
     Vector vv;

     vv.vec[0] = v.x() * d;
     vv.vec[1] = v.y() * d;
     vv.vec[2] = v.z() * d;

     return vv;
}

inline Vector
operator +(const Vector &v1, const Vector &v2)
{
     Vector v;

     v.vec[0] = v1.x() + v2.x();
     v.vec[1] = v1.y() + v2.y();
     v.vec[2] = v1.z() + v2.z();

     return v;
}

inline Vector
operator -(const Vector &v1, const Vector &v2)
{
     Vector v;

     v.vec[0] = v1.x() - v2.x();
     v.vec[1] = v1.y() - v2.y();
     v.vec[2] = v1.z() - v2.z();

     return v;
}

inline Vector
operator *(const Vector &v1, const Vector &v2)
{
     Vector v;

     v.vec[0] = v1.x() * v2.x();
     v.vec[1] = v1.y() * v2.y();
     v.vec[2] = v1.z() * v2.z();

     return v;
}

inline Vector
operator /(const Vector &v1, const Vector &v2)
{
     Vector v;

     v.vec[0] = v1.x() / v2.x();
     v.vec[1] = v1.y() / v2.y();
     v.vec[2] = v1.z() / v2.z();

     return v;
}

inline int
operator ==(const Vector &v1, const Vector &v2)
{
     if (( v1.x() == v2.x() ) &&
	 ( v1.y() == v2.y() ) &&
	 ( v1.z() == v2.z() ) )
	  return true;
     else
	  return false;
}

inline int
Vector::equals(const Vector v, float tolerance) const
{
     float length = (*this - v).length();

     if (length < tolerance)
	  return true;
     else
	  return false;
}
#endif // VECTOR_H
