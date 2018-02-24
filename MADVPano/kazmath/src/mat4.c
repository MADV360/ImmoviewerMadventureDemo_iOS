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

/**
 * @file mat4.c
 */
#include <memory.h>
#include <assert.h>
#include <stdlib.h>

#include "../include/kazmath/utility.h"
#include "../include/kazmath/vec3.h"
#include "../include/kazmath/mat4.h"
#include "../include/kazmath/mat3.h"
#include "../include/kazmath/quaternion.h"
#include "../include/kazmath/plane.h"

#include "../include/kazmath/neon_matrix_impl.h"

/**
 * Fills a kmMat4 structure with the values from a 16
 * element array of floats
 * @Params pOut - A pointer to the destination matrix
 *            pMat - A 16 element array of floats
 * @Return Returns pOut so that the call can be nested
 */
kmMat4* const kmMat4Fill(kmMat4* pOut, const kmScalar* pMat)
{
    memcpy(pOut->mat, pMat, sizeof(kmScalar) * 16);
    return pOut;
}

/**
 * Sets pOut to an identity matrix returns pOut
 * @Params pOut - A pointer to the matrix to set to identity
 * @Return Returns pOut so that the call can be nested
 */
kmMat4* const kmMat4Identity(kmMat4* pOut)
{
    memset(pOut->mat, 0, sizeof(float) * 16);
    pOut->mat[0] = pOut->mat[5] = pOut->mat[10] = pOut->mat[15] = 1.0f;
    return pOut;
}


float getCell(const kmMat4 * pIn, int row, int col)
{
    return pIn->mat[row + 4*col];
}

void setCell(kmMat4 * pIn, int row, int col, float value)
{
    pIn->mat[row + 4*col] = value;
}

void swap(kmMat4 * pIn, int r1, int c1, int r2, int c2)
{
    float tmp = getCell(pIn,r1,c1);
    setCell(pIn,r1,c1,getCell(pIn,r2,c2));
    setCell(pIn,r2,c2, tmp);
}

//Returns an upper and a lower triangular matrix which are L and R in the Gauss algorithm
int gaussj(kmMat4 *a, kmMat4 *b)
{
    int i, icol = 0, irow = 0, j, k, l, ll, n = 4, m = 4;
    float big, dum, pivinv;
    int indxc[4] = {0};
    int indxr[4] = {0};
    int ipiv[4] = {0};

    for (j = 0; j < n; j++) {
        ipiv[j] = 0;
    }

    for (i = 0; i < n; i++) {
        big = 0.0f;
        for (j = 0; j < n; j++) {
            if (ipiv[j] != 1) {
                for (k = 0; k < n; k++) {
                    if (ipiv[k] == 0) {
                        if (abs(getCell(a,j, k)) >= big) {
                            big = abs(getCell(a,j, k));
                            irow = j;
                            icol = k;
                        }
                    }
                }
            }
        }
        ++(ipiv[icol]);
        if (irow != icol) {
            for (l = 0; l < n; l++) {
                swap(a,irow, l, icol, l);
            }
            for (l = 0; l < m; l++) {
                swap(b,irow, l, icol, l);
            }
        }
        indxr[i] = irow;
        indxc[i] = icol;
        if (getCell(a,icol, icol) == 0.0) {
            return KM_FALSE;
        }
        pivinv = 1.0f / getCell(a,icol, icol);
        setCell(a,icol, icol, 1.0f);
        for (l = 0; l < n; l++) {
            setCell(a,icol, l, getCell(a,icol, l) * pivinv);
        }
        for (l = 0; l < m; l++) {
            setCell(b,icol, l, getCell(b,icol, l) * pivinv);
        }

        for (ll = 0; ll < n; ll++) {
            if (ll != icol) {
                dum = getCell(a,ll, icol);
                setCell(a,ll, icol, 0.0f);
                for (l = 0; l < n; l++) {
                    setCell(a,ll, l, getCell(a,ll, l) - getCell(a,icol, l) * dum);
                }
                for (l = 0; l < m; l++) {
                    setCell(b,ll, l, getCell(a,ll, l) - getCell(b,icol, l) * dum);
                }
            }
        }
    }
//    This is the end of the main loop over columns of the reduction. It only remains to unscram-
//    ble the solution in view of the column interchanges. We do this by interchanging pairs of
//    columns in the reverse order that the permutation was built up.
    for (l = n - 1; l >= 0; l--) {
        if (indxr[l] != indxc[l]) {
            for (k = 0; k < n; k++) {
                swap(a,k, indxr[l], k, indxc[l]);
            }
        }
    }
    return KM_TRUE;
}

/**
 * Calculates the inverse of pM and stores the result in
 * pOut.
 * @Return Returns NULL if there is no inverse, else pOut
 */
kmMat4* const kmMat4Inverse(kmMat4* pOut, const kmMat4* pM)
{
    kmMat4 inv;
    kmMat4 tmp;

    kmMat4Assign(&inv, pM);

    kmMat4Identity(&tmp);

    if(gaussj(&inv, &tmp) == KM_FALSE) {
        return NULL;
    }

    kmMat4Assign(pOut, &inv);
    return pOut;
}
/**
 * Returns KM_TRUE if pIn is an identity matrix
 * KM_FALSE otherwise
 */
const int  kmMat4IsIdentity(const kmMat4* pIn)
{
    static const float identity [] = {     1.0f, 0.0f, 0.0f, 0.0f,
                                        0.0f, 1.0f, 0.0f, 0.0f,
                                        0.0f, 0.0f, 1.0f, 0.0f,
                                        0.0f, 0.0f, 0.0f, 1.0f
                                     };

    return (memcmp(identity, pIn->mat, sizeof(float) * 16) == 0);
}

/**
 * Sets pOut to the transpose of pIn, returns pOut
 */
kmMat4* const kmMat4Transpose(kmMat4* pOut, const kmMat4* pIn)
{
    int x, z;

    for (z = 0; z < 4; ++z) {
        for (x = 0; x < 4; ++x) {
        pOut->mat[(z * 4) + x] = pIn->mat[(x * 4) + z];
        }
    }

    return pOut;
}

/**
 * Assigns the value of pIn to pOut
 */
kmMat4* const kmMat4Assign(kmMat4* pOut, const kmMat4* pIn)
{
    assert(pOut != pIn && "You have tried to self-assign!!");

    memcpy(pOut->mat, pIn->mat, sizeof(float)*16);

    return pOut;
}

/**
 * Returns KM_TRUE if the 2 matrices are equal (approximately)
 */
const int kmMat4AreEqual(const kmMat4* pMat1, const kmMat4* pMat2)
{
    int i = 0;

    assert(pMat1 != pMat2 && "You are comparing the same thing!");

    for (i = 0; i < 16; ++i)
    {
        if (!(pMat1->mat[i] + kmEpsilon > pMat2->mat[i] &&
            pMat1->mat[i] - kmEpsilon < pMat2->mat[i])) {
            return KM_FALSE;
        }
    }

    return KM_TRUE;
}

/**
 * Builds a rotation matrix using the rotation around the Y-axis
 * The result is stored in pOut, pOut is returned.
 */
kmMat4* const kmMat4RotationY(kmMat4* pOut, const float radians)
{
    /*
         |  cos(A)  0   sin(A)  0 |
     M = |  0       1   0       0 |
         | -sin(A)  0   cos(A)  0 |
         |  0       0   0       1 |
    */

    pOut->mat[0] = cosf(radians);
    pOut->mat[1] = 0.0f;
    pOut->mat[2] = -sinf(radians);
    pOut->mat[3] = 0.0f;

    pOut->mat[4] = 0.0f;
    pOut->mat[5] = 1.0f;
    pOut->mat[6] = 0.0f;
    pOut->mat[7] = 0.0f;

    pOut->mat[8] = sinf(radians);
    pOut->mat[9] = 0.0f;
    pOut->mat[10] = cosf(radians);
    pOut->mat[11] = 0.0f;

    pOut->mat[12] = 0.0f;
    pOut->mat[13] = 0.0f;
    pOut->mat[14] = 0.0f;
    pOut->mat[15] = 1.0f;

    return pOut;
}

kmMat4* const kmMat4RotationYBy(kmMat4* pOut, const float radians) {
    kmMat4 rotationMat;
    kmMat4RotationY(&rotationMat, radians);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

/**
 * Builds a rotation matrix from pitch, yaw and roll. The resulting
 * matrix is stored in pOut and pOut is returned
 */
kmMat4* const kmMat4RotationPitchYawRoll(kmMat4* pOut, const kmScalar pitch, const kmScalar yaw, const kmScalar roll)
{
    double cr = cos(pitch);
    double sr = sin(pitch);
    double cp = cos(yaw);
    double sp = sin(yaw);
    double cy = cos(roll);
    double sy = sin(roll);
    double srsp = sr * sp;
    double crsp = cr * sp;

    pOut->mat[0] = (kmScalar) cp * cy;
    pOut->mat[4] = (kmScalar) cp * sy;
    pOut->mat[8] = (kmScalar) - sp;

    pOut->mat[1] = (kmScalar) srsp * cy - cr * sy;
    pOut->mat[5] = (kmScalar) srsp * sy + cr * cy;
    pOut->mat[9] = (kmScalar) sr * cp;

    pOut->mat[2] = (kmScalar) crsp * cy + sr * sy;
    pOut->mat[6] = (kmScalar) crsp * sy - sr * cy;
    pOut->mat[10] = (kmScalar) cr * cp;

    pOut->mat[3] = pOut->mat[7] = pOut->mat[11] = 0.0;
    pOut->mat[15] = 1.0;

    return pOut;
}

kmMat4* const kmMat4RotationPitchYawRollBy(kmMat4* pOut, const kmScalar pitch, const kmScalar yaw, const kmScalar roll) {
    kmMat4 rotationMat;
    kmMat4RotationPitchYawRoll(&rotationMat, pitch,yaw,roll);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

/** Builds a scaling matrix */
kmMat4* const kmMat4Scaling(kmMat4* pOut, const kmScalar x, const kmScalar y, const kmScalar z)
{
    memset(pOut->mat, 0, sizeof(float) * 16);
    pOut->mat[0] = x;
    pOut->mat[5] = y;
    pOut->mat[10] = z;
    pOut->mat[15] = 1.0f;

    return pOut;
}

kmMat4* const kmMat4ByScaling(kmMat4* pOut, const kmScalar x, const kmScalar y, const kmScalar z) {
    kmMat4 rotationMat;
    kmMat4Scaling(&rotationMat, x,y,z);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

/**
 * Builds a translation matrix. All other elements in the matrix
 * will be set to zero except for the diagonal which is set to 1.0
 */
kmMat4* const kmMat4Translation(kmMat4* pOut, const kmScalar x, const kmScalar y, const kmScalar z)
{
    //FIXME: Write a test for this
    memset(pOut->mat, 0, sizeof(float) * 16);

    pOut->mat[0] = 1.0f;
    pOut->mat[5] = 1.0f;
    pOut->mat[10] = 1.0f;

    pOut->mat[12] = x;
    pOut->mat[13] = y;
    pOut->mat[14] = z;
    pOut->mat[15] = 1.0f;

    return pOut;
}

kmMat4* const kmMat4TranslationBy(kmMat4* pOut, const kmScalar x, const kmScalar y, const kmScalar z) {
    kmMat4 rotationMat;
    kmMat4Translation(&rotationMat, x,y,z);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

/**
 * Get the up vector from a matrix. pIn is the matrix you
 * wish to extract the vector from. pOut is a pointer to the
 * kmVec3 structure that should hold the resulting vector
 */
kmVec3* const kmMat4GetUpVec3(kmVec3* pOut, const kmMat4* pIn)
{
    pOut->x = pIn->mat[4];
    pOut->y = pIn->mat[5];
    pOut->z = pIn->mat[6];

    kmVec3Normalize(pOut, pOut);

    return pOut;
}

/** Extract the right vector from a 4x4 matrix. The result is
 * stored in pOut. Returns pOut.
 */
kmVec3* const kmMat4GetRightVec3(kmVec3* pOut, const kmMat4* pIn)
{
    pOut->x = pIn->mat[0];
    pOut->y = pIn->mat[1];
    pOut->z = pIn->mat[2];

    kmVec3Normalize(pOut, pOut);

    return pOut;
}

/**
 * Extract the forward vector from a 4x4 matrix. The result is
 * stored in pOut. Returns pOut.
 */
kmVec3* const kmMat4GetForwardVec3(kmVec3* pOut, const kmMat4* pIn)
{
    pOut->x = pIn->mat[8];
    pOut->y = pIn->mat[9];
    pOut->z = pIn->mat[10];

    kmVec3Normalize(pOut, pOut);

    return pOut;
}

/**
 * Creates a perspective projection matrix in the
 * same way as gluPerspective
 */
kmMat4* const kmMat4PerspectiveProjection(kmMat4* pOut, kmScalar fovY,
                                    kmScalar aspect, kmScalar zNear,
                                    kmScalar zFar)
{
    kmScalar r = kmDegreesToRadians(fovY / 2);
    kmScalar deltaZ = zFar - zNear;
    kmScalar s = sin(r);
    kmScalar cotangent = 0;

    if (deltaZ == 0 || s == 0 || aspect == 0) {
        return NULL;
    }

    //cos(r) / sin(r) = cot(r)
    cotangent = cos(r) / s;

    kmMat4Identity(pOut);
    pOut->mat[0] = cotangent / aspect;
    pOut->mat[5] = cotangent;
    pOut->mat[10] = -(zFar + zNear) / deltaZ;
    pOut->mat[11] = -1;
    pOut->mat[14] = -2 * zNear * zFar / deltaZ;
    pOut->mat[15] = 0;

    return pOut;
}

/** Creates an orthographic projection matrix like glOrtho */
kmMat4* const kmMat4OrthographicProjection(kmMat4* pOut, kmScalar left,
                                     kmScalar right, kmScalar bottom,
                                     kmScalar top, kmScalar nearVal,
                                     kmScalar farVal)
{
    kmScalar tx = -((right + left) / (right - left));
    kmScalar ty = -((top + bottom) / (top - bottom));
    kmScalar tz = -((farVal + nearVal) / (farVal - nearVal));

    kmMat4Identity(pOut);
    pOut->mat[0] = 2 / (right - left);
    pOut->mat[5] = 2 / (top - bottom);
    pOut->mat[10] = -2 / (farVal - nearVal);
    pOut->mat[12] = tx;
    pOut->mat[13] = ty;
    pOut->mat[14] = tz;

    return pOut;
}

/**
 * Builds a translation matrix in the same way as gluLookAt()
 * the resulting matrix is stored in pOut. pOut is returned.
 */
kmMat4* const kmMat4LookAt(kmMat4* pOut, const kmVec3* pEye,
                     const kmVec3* pCenter, const kmVec3* pUp)
{
    kmVec3 f, up, s, u;
    kmMat4 translate;

    kmVec3Subtract(&f, pCenter, pEye);
    kmVec3Normalize(&f, &f);

    kmVec3Assign(&up, pUp);
    kmVec3Normalize(&up, &up);

    kmVec3Cross(&s, &f, &up);
    kmVec3Normalize(&s, &s);

    kmVec3Cross(&u, &s, &f);
    kmVec3Normalize(&s, &s);

    kmMat4Identity(pOut);

    pOut->mat[0] = s.x;
    pOut->mat[4] = s.y;
    pOut->mat[8] = s.z;

    pOut->mat[1] = u.x;
    pOut->mat[5] = u.y;
    pOut->mat[9] = u.z;

    pOut->mat[2] = -f.x;
    pOut->mat[6] = -f.y;
    pOut->mat[10] = -f.z;

    kmMat4Translation(&translate, -pEye->x, -pEye->y, -pEye->z);
    kmMat4Multiply(pOut, pOut, &translate);

    return pOut;
}

/**
 * Extract a 3x3 rotation matrix from the input 4x4 transformation.
 * Stores the result in pOut, returns pOut
 */
kmMat3* const kmMat4ExtractRotation(kmMat3* pOut, const kmMat4* pIn)
{
    pOut->mat[0] = pIn->mat[0];
    pOut->mat[1] = pIn->mat[1];
    pOut->mat[2] = pIn->mat[2];

    pOut->mat[3] = pIn->mat[4];
    pOut->mat[4] = pIn->mat[5];
    pOut->mat[5] = pIn->mat[6];

    pOut->mat[6] = pIn->mat[8];
    pOut->mat[7] = pIn->mat[9];
    pOut->mat[8] = pIn->mat[10];

    return pOut;
}

/**
 * Take the rotation from a 4x4 transformation matrix, and return it as an axis and an angle (in radians)
 * returns the output axis.
 */
kmVec3* const kmMat4RotationToAxisAngle(kmVec3* pAxis, kmScalar* radians, const kmMat4* pIn)
{
    /*Surely not this easy?*/
    kmQuaternion temp;
    kmMat3 rotation3;
    kmMat4ExtractRotation(&rotation3, pIn);
    kmMat4 rotation;
    kmMat4Identity(&rotation);
    rotation.mat[0] = rotation3.mat[0];
    rotation.mat[1] = rotation3.mat[1];
    rotation.mat[2] = rotation3.mat[2];
    rotation.mat[4] = rotation3.mat[3];
    rotation.mat[5] = rotation3.mat[4];
    rotation.mat[6] = rotation3.mat[5];
    rotation.mat[8] = rotation3.mat[6];
    rotation.mat[9] = rotation3.mat[7];
    rotation.mat[10] = rotation3.mat[8];
    kmQuaternionRotationMatrix(&temp, &rotation);
    kmQuaternionToAxisAngle(&temp, pAxis, radians);
    return pAxis;
}

/** Build a 4x4 OpenGL transformation matrix using a 3x3 rotation matrix,
 * and a 3d vector representing a translation. Assign the result to pOut,
 * pOut is also returned.
 */
kmMat4* const kmMat4RotationTranslation(kmMat4* pOut, const kmMat3* rotation, const kmVec3* translation)
{
    pOut->mat[0] = rotation->mat[0];
    pOut->mat[1] = rotation->mat[1];
    pOut->mat[2] = rotation->mat[2];
    pOut->mat[3] = 0.0f;

    pOut->mat[4] = rotation->mat[3];
    pOut->mat[5] = rotation->mat[4];
    pOut->mat[6] = rotation->mat[5];
    pOut->mat[7] = 0.0f;

    pOut->mat[8] = rotation->mat[6];
    pOut->mat[9] = rotation->mat[7];
    pOut->mat[10] = rotation->mat[8];
    pOut->mat[11] = 0.0f;

    pOut->mat[12] = translation->x;
    pOut->mat[13] = translation->y;
    pOut->mat[14] = translation->z;
    pOut->mat[15] = 1.0f;

    return pOut;
}

kmMat4* const kmMat4RotationTranslationBy(kmMat4* pOut, const kmMat3* rotation, const kmVec3* translation) {
    kmMat4 rotationMat;
    kmMat4RotationTranslation(&rotationMat, rotation,translation);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

kmPlane* const kmMat4ExtractPlane(kmPlane* pOut, const kmMat4* pIn, const kmEnum plane)
{
    float t = 1.0f;

    switch(plane) {
        case KM_PLANE_RIGHT:
            pOut->a = pIn->mat[3] - pIn->mat[0];
            pOut->b = pIn->mat[7] - pIn->mat[4];
            pOut->c = pIn->mat[11] - pIn->mat[8];
            pOut->d = pIn->mat[15] - pIn->mat[12];
        break;
        case KM_PLANE_LEFT:
            pOut->a = pIn->mat[3] + pIn->mat[0];
            pOut->b = pIn->mat[7] + pIn->mat[4];
            pOut->c = pIn->mat[11] + pIn->mat[8];
            pOut->d = pIn->mat[15] + pIn->mat[12];
        break;
        case KM_PLANE_BOTTOM:
            pOut->a = pIn->mat[3] + pIn->mat[1];
            pOut->b = pIn->mat[7] + pIn->mat[5];
            pOut->c = pIn->mat[11] + pIn->mat[9];
            pOut->d = pIn->mat[15] + pIn->mat[13];
        break;
        case KM_PLANE_TOP:
            pOut->a = pIn->mat[3] - pIn->mat[1];
            pOut->b = pIn->mat[7] - pIn->mat[5];
            pOut->c = pIn->mat[11] - pIn->mat[9];
            pOut->d = pIn->mat[15] - pIn->mat[13];
        break;
        case KM_PLANE_FAR:
            pOut->a = pIn->mat[3] - pIn->mat[2];
            pOut->b = pIn->mat[7] - pIn->mat[6];
            pOut->c = pIn->mat[11] - pIn->mat[10];
            pOut->d = pIn->mat[15] - pIn->mat[14];
        break;
        case KM_PLANE_NEAR:
            pOut->a = pIn->mat[3] + pIn->mat[2];
            pOut->b = pIn->mat[7] + pIn->mat[6];
            pOut->c = pIn->mat[11] + pIn->mat[10];
            pOut->d = pIn->mat[15] + pIn->mat[14];
        break;
        default:
            assert(0 && "Invalid plane index");
    }

    t = sqrtf(pOut->a * pOut->a +
                    pOut->b * pOut->b +
                    pOut->c * pOut->c);
    pOut->a /= t;
    pOut->b /= t;
    pOut->c /= t;
    pOut->d /= t;

    return pOut;
}
////////////////////////
// Returns a kmVec3 structure constructed from the vector components.
kmVec3 kmVec3Make(kmScalar x, kmScalar y, kmScalar z) {
    kmVec3 v;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

// Multiplies pM1 with pM2, stores the result in pOut, returns pOut
kmMat4* const kmMat4Multiply(kmMat4* pOut, const kmMat4* pM1, const kmMat4* pM2) {
//#if defined(__ARM_NEON__) : http://stackoverflow.com/questions/19634756/error-when-creating-an-archive-of-my-cocos2d-app
#if defined(_ARM_ARCH_7)
    float mat[16];
    
    // Invert column-order with row-order
    NEON_Matrix4Mul( &pM2->mat[0], &pM1->mat[0], &mat[0] );
    
#else
    float mat[16];
    
    const float *m1 = pM1->mat, *m2 = pM2->mat;
    
    mat[0] = m1[0] * m2[0] + m1[4] * m2[1] + m1[8] * m2[2] + m1[12] * m2[3];
    mat[1] = m1[1] * m2[0] + m1[5] * m2[1] + m1[9] * m2[2] + m1[13] * m2[3];
    mat[2] = m1[2] * m2[0] + m1[6] * m2[1] + m1[10] * m2[2] + m1[14] * m2[3];
    mat[3] = m1[3] * m2[0] + m1[7] * m2[1] + m1[11] * m2[2] + m1[15] * m2[3];
    
    mat[4] = m1[0] * m2[4] + m1[4] * m2[5] + m1[8] * m2[6] + m1[12] * m2[7];
    mat[5] = m1[1] * m2[4] + m1[5] * m2[5] + m1[9] * m2[6] + m1[13] * m2[7];
    mat[6] = m1[2] * m2[4] + m1[6] * m2[5] + m1[10] * m2[6] + m1[14] * m2[7];
    mat[7] = m1[3] * m2[4] + m1[7] * m2[5] + m1[11] * m2[6] + m1[15] * m2[7];
    
    mat[8] = m1[0] * m2[8] + m1[4] * m2[9] + m1[8] * m2[10] + m1[12] * m2[11];
    mat[9] = m1[1] * m2[8] + m1[5] * m2[9] + m1[9] * m2[10] + m1[13] * m2[11];
    mat[10] = m1[2] * m2[8] + m1[6] * m2[9] + m1[10] * m2[10] + m1[14] * m2[11];
    mat[11] = m1[3] * m2[8] + m1[7] * m2[9] + m1[11] * m2[10] + m1[15] * m2[11];
    
    mat[12] = m1[0] * m2[12] + m1[4] * m2[13] + m1[8] * m2[14] + m1[12] * m2[15];
    mat[13] = m1[1] * m2[12] + m1[5] * m2[13] + m1[9] * m2[14] + m1[13] * m2[15];
    mat[14] = m1[2] * m2[12] + m1[6] * m2[13] + m1[10] * m2[14] + m1[14] * m2[15];
    mat[15] = m1[3] * m2[12] + m1[7] * m2[13] + m1[11] * m2[14] + m1[15] * m2[15];
    
#endif
    
    memcpy(pOut->mat, mat, sizeof(float)*16);
    
    return pOut;
}

const kmScalar kmMat4Determinant(const kmMat4* pIn)
{
    kmScalar output = 0;

    kmMat3 subMat0, subMat4, subMat8, subMat12;
    const float subMat0Data[] = {pIn->mat[5], pIn->mat[6], pIn->mat[7],
                                 pIn->mat[9], pIn->mat[10], pIn->mat[11],
                                 pIn->mat[13], pIn->mat[14], pIn->mat[15]};
    const float subMat4Data[] = {pIn->mat[1], pIn->mat[2], pIn->mat[3],
                                 pIn->mat[9], pIn->mat[10], pIn->mat[11],
                                 pIn->mat[13], pIn->mat[14], pIn->mat[15]};
    const float subMat8Data[] = {pIn->mat[1], pIn->mat[2], pIn->mat[3],
                                 pIn->mat[5], pIn->mat[6], pIn->mat[7],
                                 pIn->mat[13], pIn->mat[14], pIn->mat[15]};
    const float subMat12Data[] = {pIn->mat[1], pIn->mat[2], pIn->mat[3],
                                 pIn->mat[5], pIn->mat[6], pIn->mat[7],
                                 pIn->mat[9], pIn->mat[10], pIn->mat[11]};
    kmMat3Fill(&subMat0, subMat0Data);
    kmMat3Fill(&subMat4, subMat4Data);
    kmMat3Fill(&subMat8, subMat8Data);
    kmMat3Fill(&subMat12, subMat12Data);

    output += pIn->mat[0] * kmMat3Determinant(&subMat0);
    output -= pIn->mat[4] * kmMat3Determinant(&subMat4);
    output += pIn->mat[8] * kmMat3Determinant(&subMat8);
    output -= pIn->mat[12] * kmMat3Determinant(&subMat12);

    return output;
}

// Builds a rotation matrix that rotates around all three axes, y (yaw), x (pitch), z (roll),
// (equivalently to separate rotations, in that order), stores the result in pOut and returns the result.
kmMat4* kmMat4RotationYXZ(kmMat4* pOut, const kmScalar xRadians, const kmScalar yRadians, const kmScalar zRadians) {
    /*
     |  cycz + sxsysz   czsxsy - cysz   cxsy  0 |
     M = |  cxsz            cxcz           -sx    0 |
     |  cysxsz - czsy   cyczsx + sysz   cxcy  0 |
     |  0               0               0     1 |
     
     where cA = cos(A), sA = sin(A) for A = x,y,z
     */
    kmScalar* m = pOut->mat;
    
    kmScalar cx = cosf(xRadians);
    kmScalar sx = sinf(xRadians);
    kmScalar cy = cosf(yRadians);
    kmScalar sy = sinf(yRadians);
    kmScalar cz = cosf(zRadians);
    kmScalar sz = sinf(zRadians);
    
    m[0] = (cy * cz) + (sx * sy * sz);
    m[1] = cx * sz;
    m[2] = (cy * sx * sz) - (cz * sy);
    m[3] = 0.0;
    
    m[4] = (cz * sx * sy) - (cy * sz);
    m[5] = cx * cz;
    m[6] = (cy * cz * sx) + (sy * sz);
    m[7] = 0.0;
    
    m[8] = cx * sy;
    m[9] = -sx;
    m[10] = cx * cy;
    m[11] = 0.0;
    
    m[12] = 0.0;
    m[13] = 0.0;
    m[14] = 0.0;
    m[15] = 1.0;
    
    return pOut;
}

kmMat4* const kmMat4RotationYXZBy(kmMat4* pOut, const kmScalar xRadians, const kmScalar yRadians, const kmScalar zRadians) {
    kmMat4 rotationMat;
    kmMat4RotationYXZ(&rotationMat, xRadians,yRadians,zRadians);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

// Builds a rotation matrix that rotates around all three axes, z (roll), y (yaw), x (pitch),
// (equivalently to separate rotations, in that order), stores the result in pOut and returns the result.
kmMat4* kmMat4RotationZYX(kmMat4* pOut, const kmScalar xRadians, const kmScalar yRadians, const kmScalar zRadians) {
    /*
     |  cycz  -cxsz + sxsycz   sxsz + cxsycz  0 |
     M = |  cysz   cxcz + sxsysz  -sxcz + cxsysz  0 |
     | -sy     sxcy            cxcy           0 |
     |  0      0               0              1 |
     
     where cA = cos(A), sA = sin(A) for A = x,y,z
     */
    kmScalar* m = pOut->mat;
    
    kmScalar cx = cosf(xRadians);
    kmScalar sx = sinf(xRadians);
    kmScalar cy = cosf(yRadians);
    kmScalar sy = sinf(yRadians);
    kmScalar cz = cosf(zRadians);
    kmScalar sz = sinf(zRadians);
    
    m[0] = cy * cz;
    m[1] = cy * sz;
    m[2] = -sy;
    m[3] = 0.0;
    
    m[4] = -(cx * sz) + (sx * sy * cz);
    m[5] = (cx * cz) + (sx * sy * sz);
    m[6] = sx * cy;
    m[7] = 0.0;
    
    m[8] = (sx * sz) + (cx * sy * cz);
    m[9] = -(sx * cz) + (cx * sy * sz);
    m[10] = cx * cy;
    m[11] = 0.0;
    
    m[12] = 0.0;
    m[13] = 0.0;
    m[14] = 0.0;
    m[15] = 1.0;
    
    return pOut;
}

kmMat4* const kmMat4RotationZYXBy(kmMat4* pOut, const kmScalar xRadians, const kmScalar yRadians, const kmScalar zRadians) {
    kmMat4 rotationMat;
    kmMat4RotationZYX(&rotationMat, xRadians,yRadians,zRadians);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

// Builds a rotation matrix around the X-axis, stores the result in pOut and returns the result
kmMat4* const kmMat4RotationX(kmMat4* pOut, const float radians) {
    /*
     |  1  0       0       0 |
     M = |  0  cos(A) -sin(A)  0 |
     |  0  sin(A)  cos(A)  0 |
     |  0  0       0       1 |
     */
    kmScalar* m = pOut->mat;
    
    m[0] = 1.0f;
    m[1] = 0.0f;
    m[2] = 0.0f;
    m[3] = 0.0f;
    
    m[4] = 0.0f;
    m[5] = cosf(radians);
    m[6] = sinf(radians);
    m[7] = 0.0f;
    
    m[8] = 0.0f;
    m[9] = -sinf(radians);
    m[10] = cosf(radians);
    m[11] = 0.0f;
    
    m[12] = 0.0f;
    m[13] = 0.0f;
    m[14] = 0.0f;
    m[15] = 1.0f;
    
    return pOut;
}

kmMat4* const kmMat4RotationXBy(kmMat4* pOut, const float radians) {
    kmMat4 rotationMat;
    kmMat4RotationX(&rotationMat, radians);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

// Builds a rotation matrix around the Z-axis, stores the result in pOut and returns the result
kmMat4* const kmMat4RotationZ(kmMat4* pOut, const float radians) {
    /*
     |  cos(A)  -sin(A)   0   0 |
     M = |  sin(A)   cos(A)   0   0 |
     |  0        0        1   0 |
     |  0        0        0   1 |
     */
    kmScalar* m = pOut->mat;
    
    m[0] = cosf(radians);
    m[1] = sinf(radians);
    m[2] = 0.0f;
    m[3] = 0.0f;
    
    m[4] = -sinf(radians);;
    m[5] = cosf(radians);
    m[6] = 0.0f;
    m[7] = 0.0f;
    
    m[8] = 0.0f;
    m[9] = 0.0f;
    m[10] = 1.0f;
    m[11] = 0.0f;
    
    m[12] = 0.0f;
    m[13] = 0.0f;
    m[14] = 0.0f;
    m[15] = 1.0f;
    
    return pOut;
}

kmMat4* const kmMat4RotationZBy(kmMat4* pOut, const float radians) {
    kmMat4 rotationMat;
    kmMat4RotationZ(&rotationMat, radians);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

// Build a rotation matrix from an axis and an angle, stores the result in pOut and returns the result.
kmMat4* const kmMat4RotationAxisAngle(kmMat4* pOut, const kmVec3* axis, kmScalar radians) {
    /*
     |      									|
     | C + XX(1 - C)   -ZS + XY(1-C)  YS + ZX(1-C)   0 |
     |                                                 |
     M =  | ZS + XY(1-C)    C + YY(1 - C)  -XS + YZ(1-C)  0 |
     |                                                 |
     | -YS + ZX(1-C)   XS + YZ(1-C)   C + ZZ(1 - C)  0 |
     |                                                 |
     |      0              0               0         1 |
     
     where X, Y, Z define axis of rotation and C = cos(A), S = sin(A) for A = angle of rotation
     */
    kmScalar ca = cosf(radians);
    kmScalar sa = sinf(radians);
    
    kmVec3 rax;
    kmVec3Normalize(&rax, axis);
    
    pOut->mat[0] = ca + rax.x * rax.x * (1 - ca);
    pOut->mat[1] = rax.z * sa + rax.y * rax.x * (1 - ca);
    pOut->mat[2] = -rax.y * sa + rax.z * rax.x * (1 - ca);
    pOut->mat[3] = 0.0f;
    
    pOut->mat[4] = -rax.z * sa + rax.x * rax.y * (1 - ca);
    pOut->mat[5] = ca + rax.y * rax.y * (1 - ca);
    pOut->mat[6] = rax.x * sa + rax.z * rax.y * (1 - ca);
    pOut->mat[7] = 0.0f;
    
    pOut->mat[8] = rax.y * sa + rax.x * rax.z * (1 - ca);
    pOut->mat[9] = -rax.x * sa + rax.y * rax.z * (1 - ca);
    pOut->mat[10] = ca + rax.z * rax.z * (1 - ca);
    pOut->mat[11] = 0.0f;
    
    pOut->mat[12] = 0.0f;
    pOut->mat[13] = 0.0f;
    pOut->mat[14] = 0.0f;
    pOut->mat[15] = 1.0f;
    
    return pOut;
}

kmMat4* const kmMat4RotationAxisAngleBy(kmMat4* pOut, const kmVec3* axis, kmScalar radians) {
    kmMat4 rotationMat;
    kmMat4RotationAxisAngle(&rotationMat, axis, radians);
    kmMat4Multiply(pOut, &rotationMat, pOut);
    return pOut;
}

// Builds a rotation matrix from a quaternion to a rotation matrix,
// stores the result in pOut and returns the result
kmMat4* const kmMat4RotationQuaternion(kmMat4* pOut, const kmQuaternion* pQ) {
    /*
     |       2     2									|
     | 1 - 2Y  - 2Z    2XY + 2ZW      2XZ - 2YW		 0	|
     |													|
     |                       2     2					|
     M = | 2XY - 2ZW       1 - 2X  - 2Z   2YZ + 2XW		 0	|
     |													|
     |                                      2     2		|
     | 2XZ + 2YW       2YZ - 2XW      1 - 2X  - 2Y	 0	|
     |													|
     |     0			   0			  0          1  |
     */
    kmScalar* m = pOut->mat;
    
    kmScalar twoXX = 2.0f * pQ->x * pQ->x;
    kmScalar twoXY = 2.0f * pQ->x * pQ->y;
    kmScalar twoXZ = 2.0f * pQ->x * pQ->z;
    kmScalar twoXW = 2.0f * pQ->x * pQ->w;
    
    kmScalar twoYY = 2.0f * pQ->y * pQ->y;
    kmScalar twoYZ = 2.0f * pQ->y * pQ->z;
    kmScalar twoYW = 2.0f * pQ->y * pQ->w;
    
    kmScalar twoZZ = 2.0f * pQ->z * pQ->z;
    kmScalar twoZW = 2.0f * pQ->z * pQ->w;
    
    m[0] = 1.0f - twoYY - twoZZ;
    m[1] = twoXY - twoZW;
    m[2] = twoXZ + twoYW;
    m[3] = 0.0f;
    
    m[4] = twoXY + twoZW;
    m[5] = 1.0f - twoXX - twoZZ;
    m[6] = twoYZ - twoXW;
    m[7] = 0.0f;
    
    m[8] = twoXZ - twoYW;
    m[9] = twoYZ + twoXW;
    m[10] = 1.0f - twoXX - twoYY;
    m[11] = 0.0f;
    
    m[12] = 0.0f;
    m[13] = 0.0f;
    m[14] = 0.0f;
    m[15] = 1.0f;
    
    return pOut;
}

kmMat4* const kmMat4RotationQuaternionBy(kmMat4* pOut, const kmQuaternion* pQ) {
    kmMat4 rotationMat;
    kmMat4RotationQuaternion(&rotationMat, pQ);
    kmMat4Multiply(pOut, &rotationMat, pOut);
    return pOut;
}

// Builds a transformation matrix that translates, rotates and scales according to the specified vectors,
// stores the result in pOut and returns the result
kmMat4* kmMat4Transformation(kmMat4* pOut, const kmVec3 translation, const kmVec3 rotation, const kmVec3 scale) {
    /*
     |  gxR0  gyR4  gzR8   tx |
     M = |  gxR1  gyR5  gzR9   ty |
     |  gxR2  gyR6  gzR10  tz |
     |  0     0     0      1  |
     
     where Rn is an element of the rotation matrix (R0 - R15).
     where tx = translation.x, ty = translation.y, tz = translation.z
     where gx = scale.x, gy = scale.y, gz = scale.z
     */
    
    // Start with basic rotation matrix
    kmMat4RotationYXZ(pOut, rotation.x, rotation.y, rotation.z);
    
    // Adjust for scale and translation
    kmScalar* m = pOut->mat;
    
    m[0] *= scale.x;
    m[1] *= scale.x;
    m[2] *= scale.x;
    m[3] = 0.0;
    
    m[4] *= scale.y;
    m[5] *= scale.y;
    m[6] *= scale.y;
    m[7] = 0.0;
    
    m[8] *= scale.z;
    m[9] *= scale.z;
    m[10] *= scale.z;
    m[11] = 0.0;
    
    m[12] = translation.x;
    m[13] = translation.y;
    m[14] = translation.z;
    m[15] = 1.0;
    
    return pOut;
}

kmMat4* kmMat4TransformationBy(kmMat4* pOut, const kmVec3 translation, const kmVec3 rotation, const kmVec3 scale) {
    kmMat4 rotationMat;
    kmMat4Transformation(&rotationMat, translation, rotation, scale);
    kmMat4Multiply(pOut, pOut, &rotationMat);
    return pOut;
}

float kmMatGet(const kmMat4* pIn, int row, int col) {
    return pIn->mat[row + 4*col];
}

void kmMatSet(kmMat4* pIn, int row, int col, float value) {
    pIn->mat[row + 4*col] = value;
}

void kmMatSwap(kmMat4* pIn, int r1, int c1, int r2, int c2) {
    float tmp = kmMatGet(pIn,r1,c1);
    kmMatSet(pIn,r1,c1,kmMatGet(pIn,r2,c2));
    kmMatSet(pIn,r2,c2, tmp);
}

// Returns an upper and a lower triangular matrix which are L and R in the Gauss algorithm
int kmGaussJordan(kmMat4* a, kmMat4* b) {
    int i, icol = 0, irow = 0, j, k, l, ll, n = 4, m = 4;
    float big, dum, pivinv;
    int indxc[4];
    int indxr[4];
    int ipiv[4];
    
    for (j = 0; j < n; j++) {
        ipiv[j] = 0;
    }
    
    for (i = 0; i < n; i++) {
        big = 0.0f;
        for (j = 0; j < n; j++) {
            if (ipiv[j] != 1) {
                for (k = 0; k < n; k++) {
                    if (ipiv[k] == 0) {
                        if (abs(kmMatGet(a,j, k)) >= big) {
                            big = abs(kmMatGet(a,j, k));
                            irow = j;
                            icol = k;
                        }
                    }
                }
            }
        }
        ++(ipiv[icol]);
        if (irow != icol) {
            for (l = 0; l < n; l++) {
                kmMatSwap(a,irow, l, icol, l);
            }
            for (l = 0; l < m; l++) {
                kmMatSwap(b,irow, l, icol, l);
            }
        }
        indxr[i] = irow;
        indxc[i] = icol;
        if (kmMatGet(a,icol, icol) == 0.0) {
            return KM_FALSE;
        }
        pivinv = 1.0f / kmMatGet(a,icol, icol);
        kmMatSet(a,icol, icol, 1.0f);
        for (l = 0; l < n; l++) {
            kmMatSet(a,icol, l, kmMatGet(a,icol, l) * pivinv);
        }
        for (l = 0; l < m; l++) {
            kmMatSet(b,icol, l, kmMatGet(b,icol, l) * pivinv);
        }
        
        for (ll = 0; ll < n; ll++) {
            if (ll != icol) {
                dum = kmMatGet(a,ll, icol);
                kmMatSet(a,ll, icol, 0.0f);
                for (l = 0; l < n; l++) {
                    kmMatSet(a,ll, l, kmMatGet(a,ll, l) - kmMatGet(a,icol, l) * dum);
                }
                for (l = 0; l < m; l++) {
                    kmMatSet(b,ll, l, kmMatGet(a,ll, l) - kmMatGet(b,icol, l) * dum);
                }
            }
        }
    }
    //    This is the end of the main loop over columns of the reduction. It only remains to unscram-
    //    ble the solution in view of the column interchanges. We do this by interchanging pairs of
    //    columns in the reverse order that the permutation was built up.
    for (l = n - 1; l >= 0; l--) {
        if (indxr[l] != indxc[l]) {
            for (k = 0; k < n; k++) {
                kmMatSwap(a,k, indxr[l], k, indxc[l]);
            }
        }
    }
    return KM_TRUE;
}
