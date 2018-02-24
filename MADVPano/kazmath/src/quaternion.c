/*
Copyright (c) 2008, Luke Benstead.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#include <assert.h>
#include <memory.h>

#include "../include/kazmath/utility.h"
#include "../include/kazmath/mat4.h"
#include "../include/kazmath/vec3.h"
#include "../include/kazmath/quaternion.h"

#ifndef NULL
#define NULL    ((void *)0)
#endif

///< Returns pOut, sets pOut to the conjugate of pIn
kmQuaternion* const kmQuaternionConjugate(kmQuaternion* pOut, const kmQuaternion* pIn)
{
    pOut->x = -pIn->x;
    pOut->y = -pIn->y;
    pOut->z = -pIn->z;
    pOut->w = pIn->w;

    return pOut;
}

///< Returns the dot product of the 2 quaternions
const kmScalar kmQuaternionDot(const kmQuaternion* q1, const kmQuaternion* q2)
{
    // A dot B = B dot A = AtBt + AxBx + AyBy + AzBz

    return (q1->w * q2->w +
            q1->x * q2->x +
            q1->y * q2->y +
            q1->z * q2->z);
}

///< Returns the exponential of the quaternion
kmQuaternion* kmQuaternionExp(kmQuaternion* pOut, const kmQuaternion* pIn)
{
    assert(0);

    return pOut;
}

///< Makes the passed quaternion an identity quaternion
kmQuaternion* kmQuaternionIdentity(kmQuaternion* pOut)
{
    pOut->x = 0.0;
    pOut->y = 0.0;
    pOut->z = 0.0;
    pOut->w = 1.0;

    return pOut;
}

///< Returns the inverse of the passed Quaternion
kmQuaternion* kmQuaternionInverse(kmQuaternion* pOut,
                                            const kmQuaternion* pIn)
{
    kmScalar l = kmQuaternionLength(pIn);
    kmQuaternion tmp;

    if (fabs(l) > kmEpsilon)
    {
        pOut->x = 0.0;
        pOut->y = 0.0;
        pOut->z = 0.0;
        pOut->w = 0.0;

        return pOut;
    }



    ///Get the conjugute and divide by the length
    kmQuaternionScale(pOut,
                kmQuaternionConjugate(&tmp, pIn), 1.0f / l);

    return pOut;
}

///< Returns true if the quaternion is an identity quaternion
int kmQuaternionIsIdentity(const kmQuaternion* pIn)
{
    return (pIn->x == 0.0 && pIn->y == 0.0 && pIn->z == 0.0 &&
                pIn->w == 1.0);
}

///< Returns the length of the quaternion
kmScalar kmQuaternionLength(const kmQuaternion* pIn)
{
    return sqrtf(kmQuaternionLengthSq(pIn));
}

///< Returns the length of the quaternion squared (prevents a sqrt)
kmScalar kmQuaternionLengthSq(const kmQuaternion* pIn)
{
    return pIn->x * pIn->x + pIn->y * pIn->y +
                        pIn->z * pIn->z + pIn->w * pIn->w;
}

///< Returns the natural logarithm
kmQuaternion* kmQuaternionLn(kmQuaternion* pOut,
                                        const kmQuaternion* pIn)
{
    /*
        A unit quaternion, is defined by:
        Q == (cos(theta), sin(theta) * v) where |v| = 1
        The natural logarithm of Q is, ln(Q) = (0, theta * v)
    */

    assert(0);

    return pOut;
}

///< Multiplies 2 quaternions together
extern
kmQuaternion* kmQuaternionMultiply(kmQuaternion* pOut,
                                 const kmQuaternion* q1,
                                 const kmQuaternion* q2)
{
    kmQuaternion result;
    result.w = q1->w * q2->w - q1->x * q2->x - q1->y * q2->y - q1->z * q2->z;
    result.x = q1->w * q2->x + q1->x * q2->w + q1->y * q2->z - q1->z * q2->y;
    result.y = q1->w * q2->y + q1->y * q2->w + q1->z * q2->x - q1->x * q2->z;
    result.z = q1->w * q2->z + q1->z * q2->w + q1->x * q2->y - q1->y * q2->x;

    pOut->w = result.w;
    pOut->x = result.x;
    pOut->y = result.y;
    pOut->z = result.z;
    
    return pOut;
}

///< Normalizes a quaternion
kmQuaternion* kmQuaternionNormalize(kmQuaternion* pOut,
                                            const kmQuaternion* pIn)
{
    kmScalar length = kmQuaternionLength(pIn);
    assert(fabs(length) > kmEpsilon);
    kmQuaternionScale(pOut, pIn, 1.0f / length);

    return pOut;
}

///< Rotates a quaternion around an axis
kmQuaternion* kmQuaternionRotationAxis(kmQuaternion* pOut,
                                    const kmVec3* pV,
                                    kmScalar angle)
{
    kmScalar rad = angle * 0.5f;
    kmScalar scale    = sinf(rad);

    pOut->w = cosf(rad);
    pOut->x = pV->x * scale;
    pOut->y = pV->y * scale;
    pOut->z = pV->z * scale;

    return pOut;
}

// Extracts a quaternion from a rotation matrix, stores the result in quat and returns the result.
// This implementation is actually taken from the Quaternions article in Jeff LaMarche's excellent
// series on OpenGL programming for the iOS. Jeff's original source and explanation can be found here:
// http://iphonedevelopment.blogspot.com/2010/04/opengl-es-from-ground-up-9-intermission.html
// It has been adapted here for this library.
kmQuaternion* const kmQuaternionRotationMatrix(kmQuaternion* quat, const struct kmMat4* pIn) {
#define QUATERNION_TRACE_ZERO_TOLERANCE 0.0001f
    kmScalar trace, s;
    const kmScalar* m = pIn->mat;
    
    trace = m[0] + m[5] + m[10];
    if (trace > 0.0f) {
        s = sqrtf(trace + 1.0f);
        quat->w = s * 0.5f;
        s = 0.5f / s;
        
        quat->x = (m[9] - m[6]) * s;
        quat->y = (m[2] - m[8]) * s;
        quat->z = (m[4] - m[1]) * s;
    } else {
        enum {A,E,I} biggest;
        if (m[0] > m[5])
            if (m[10] > m[0])
                biggest = I;
            else
                biggest = A;
            else
                if (m[10] > m[0])
                    biggest = I;
                else
                    biggest = E;
        
        switch (biggest) {
            case A:
                s = sqrtf(m[0] - (m[5] + m[10]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->x = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[9] - m[6]) * s;
                    quat->y = (m[1] + m[4]) * s;
                    quat->z = (m[2] + m[8]) * s;
                    break;
                }
                s = sqrtf(m[10] - (m[0] + m[5]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->z = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[4] - m[1]) * s;
                    quat->x = (m[8] + m[2]) * s;
                    quat->y = (m[9] + m[6]) * s;
                    break;
                }
                s = sqrtf(m[5] - (m[10] + m[0]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->y = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[2] - m[8]) * s;
                    quat->z = (m[6] + m[9]) * s;
                    quat->x = (m[4] + m[1]) * s;
                    break;
                }
                break;
                
            case E:
                s = sqrtf(m[5] - (m[10] + m[0]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->y = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[2] - m[8]) * s;
                    quat->z = (m[6] + m[9]) * s;
                    quat->x = (m[4] + m[1]) * s;
                    break;
                }
                s = sqrtf(m[10] - (m[0] + m[5]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->z = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[4] - m[1]) * s;
                    quat->x = (m[8] + m[2]) * s;
                    quat->y = (m[9] + m[6]) * s;
                    break;
                }
                s = sqrtf(m[0] - (m[5] + m[10]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->x = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[9] - m[6]) * s;
                    quat->y = (m[1] + m[4]) * s;
                    quat->z = (m[2] + m[8]) * s;
                    break;
                }
                break;
                
            case I:
                s = sqrtf(m[10] - (m[0] + m[5]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->z = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[4] - m[1]) * s;
                    quat->x = (m[8] + m[2]) * s;
                    quat->y = (m[9] + m[6]) * s;
                    break;
                }
                s = sqrtf(m[0] - (m[5] + m[10]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->x = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[9] - m[6]) * s;
                    quat->y = (m[1] + m[4]) * s;
                    quat->z = (m[2] + m[8]) * s;
                    break;
                }
                s = sqrtf(m[5] - (m[10] + m[0]) + 1.0f);
                if (s > QUATERNION_TRACE_ZERO_TOLERANCE) {
                    quat->y = s * 0.5f;
                    s = 0.5f / s;
                    quat->w = (m[2] - m[8]) * s;
                    quat->z = (m[6] + m[9]) * s;
                    quat->x = (m[4] + m[1]) * s;
                    break;
                }
                break;
                
            default:
                break;
        }
    }
    return quat;
}

///< Create a quaternion from yaw, pitch and roll
kmQuaternion* kmQuaternionRotationYawPitchRoll(kmQuaternion* pOut,
                                                kmScalar yaw,
                                                kmScalar pitch,
                                                kmScalar roll)
{
    kmScalar    ex, ey, ez;        // temp half euler angles
    kmScalar    cr, cp, cy, sr, sp, sy, cpcy, spsy;        // temp vars in roll,pitch yaw

    ex = kmDegreesToRadians(pitch) / 2.0f;    // convert to rads and half them
    ey = kmDegreesToRadians(yaw) / 2.0f;
    ez = kmDegreesToRadians(roll) / 2.0f;

    cr = cosf(ex);
    cp = cosf(ey);
    cy = cosf(ez);

    sr = sinf(ex);
    sp = sinf(ey);
    sy = sinf(ez);

    cpcy = cp * cy;
    spsy = sp * sy;

    pOut->w = cr * cpcy + sr * spsy;

    pOut->x = sr * cpcy - cr * spsy;
    pOut->y = cr * sp * cy + sr * cp * sy;
    pOut->z = cr * cp * sy - sr * sp * cy;

    kmQuaternionNormalize(pOut, pOut);

    return pOut;
}

///< Interpolate between 2 quaternions
kmQuaternion* kmQuaternionSlerp(kmQuaternion* pOut,
                                const kmQuaternion* q1,
                                const kmQuaternion* q2,
                                kmScalar t)
{

 /*float CosTheta = Q0.DotProd(Q1);
  float Theta = acosf(CosTheta);
  float SinTheta = sqrtf(1.0f-CosTheta*CosTheta);

  float Sin_T_Theta = sinf(T*Theta)/SinTheta;
  float Sin_OneMinusT_Theta = sinf((1.0f-T)*Theta)/SinTheta;

  Quaternion Result = Q0*Sin_OneMinusT_Theta;
  Result += (Q1*Sin_T_Theta);

  return Result;*/

    if (q1->x == q2->x &&
        q1->y == q2->y &&
        q1->z == q2->z &&
        q1->w == q2->w) {

        pOut->x = q1->x;
        pOut->y = q1->y;
        pOut->z = q1->z;
        pOut->w = q1->w;

        return pOut;
    }
    {
        kmScalar ct = kmQuaternionDot(q1, q2);
        kmScalar theta = acosf(ct);
        kmScalar st = sqrtf(1.0 - kmSQR(ct));

        kmScalar stt = sinf(t * theta) / st;
        kmScalar somt = sinf((1.0 - t) * theta) / st;

        kmQuaternion temp, temp2;
        kmQuaternionScale(&temp, q1, somt);
        kmQuaternionScale(&temp2, q2, stt);
        kmQuaternionAdd(pOut, &temp, &temp2);
    }
    return pOut;
}

///< Get the axis and angle of rotation from a quaternion
void kmQuaternionToAxisAngle(const kmQuaternion* pIn,
                                kmVec3* pAxis,
                                kmScalar* pAngle)
{
    kmScalar     tempAngle;        // temp angle
    kmScalar    scale;            // temp vars

    tempAngle = acosf(pIn->w);
    scale = sqrtf(kmSQR(pIn->x) + kmSQR(pIn->y) + kmSQR(pIn->z));

    if (((scale > -kmEpsilon) && scale < kmEpsilon)
        || (scale < 2*kmPI + kmEpsilon && scale > 2*kmPI - kmEpsilon))        // angle is 0 or 360 so just simply set axis to 0,0,1 with angle 0
    {
        *pAngle = 0.0f;

        pAxis->x = 0.0f;
        pAxis->y = 0.0f;
        pAxis->z = 1.0f;
    }
    else
    {
        *pAngle = tempAngle * 2.0f;        // angle in radians

        pAxis->x = pIn->x / scale;
        pAxis->y = pIn->y / scale;
        pAxis->z = pIn->z / scale;
        kmVec3Normalize(pAxis, pAxis);
    }
}

kmQuaternion* kmQuaternionScale(kmQuaternion* pOut,
                                        const kmQuaternion* pIn,
                                        kmScalar s)
{
    pOut->x = pIn->x * s;
    pOut->y = pIn->y * s;
    pOut->z = pIn->z * s;
    pOut->w = pIn->w * s;

    return pOut;
}

kmQuaternion* kmQuaternionAssign(kmQuaternion* pOut, const kmQuaternion* pIn)
{
    memcpy(pOut, pIn, sizeof(float) * 4);

    return pOut;
}

kmQuaternion* kmQuaternionAdd(kmQuaternion* pOut, const kmQuaternion* pQ1, const kmQuaternion* pQ2)
{
    pOut->x = pQ1->x + pQ2->x;
    pOut->y = pQ1->y + pQ2->y;
    pOut->z = pQ1->z + pQ2->z;
    pOut->w = pQ1->w + pQ2->w;

    return pOut;
}

/** Adapted from the OGRE engine!

    Gets the shortest arc quaternion to rotate this vector to the destination
    vector.
@remarks
    If you call this with a dest vector that is close to the inverse
    of this vector, we will rotate 180 degrees around the 'fallbackAxis'
    (if specified, or a generated axis if not) since in this case
    ANY axis of rotation is valid.
*/

kmQuaternion* kmQuaternionRotationBetweenVec3(kmQuaternion* pOut, const kmVec3* vec1, const kmVec3* vec2, const kmVec3* fallback) {

    kmVec3 v1, v2;
    kmScalar a;

    kmVec3Assign(&v1, vec1);
    kmVec3Assign(&v2, vec2);

    kmVec3Normalize(&v1, &v1);
    kmVec3Normalize(&v2, &v2);

    a = kmVec3Dot(&v1, &v2);

    if (a >= 1.0) {
        kmQuaternionIdentity(pOut);
        return pOut;
    }

    if (a < (1e-6f - 1.0f))    {
        if (fabs(kmVec3LengthSq(fallback)) < kmEpsilon) {
            kmQuaternionRotationAxis(pOut, fallback, kmPI);
        } else {
            kmVec3 axis;
            kmVec3 X;
            X.x = 1.0;
            X.y = 0.0;
            X.z = 0.0;


            kmVec3Cross(&axis, &X, vec1);

            //If axis is zero
            if (fabs(kmVec3LengthSq(&axis)) < kmEpsilon) {
                kmVec3 Y;
                Y.x = 0.0;
                Y.y = 1.0;
                Y.z = 0.0;

                kmVec3Cross(&axis, &Y, vec1);
            }

            kmVec3Normalize(&axis, &axis);

            kmQuaternionRotationAxis(pOut, &axis, kmPI);
        }
    } else {
        kmScalar s = sqrtf((1+a) * 2);
        kmScalar invs = 1 / s;

        kmVec3 c;
        kmVec3Cross(&c, &v1, &v2);

        pOut->x = c.x * invs;
        pOut->y = c.y * invs;
        pOut->z = c.z * invs;
        pOut->w = s * 0.5f;

        kmQuaternionNormalize(pOut, pOut);
    }

    return pOut;

}

kmVec3* kmQuaternionMultiplyVec3(kmVec3* pOut, const kmQuaternion* q, const kmVec3* v) {
    kmVec3 uv, uuv, qvec;

    qvec.x = q->x;
    qvec.y = q->y;
    qvec.z = q->z;

    kmVec3Cross(&uv, &qvec, v);
    kmVec3Cross(&uuv, &qvec, &uv);

    kmVec3Scale(&uv, &uv, (2.0f * q->w));
    kmVec3Scale(&uuv, &uuv, 2.0f);

    kmVec3Add(pOut, v, &uv);
    kmVec3Add(pOut, pOut, &uuv);

    return pOut;
}

