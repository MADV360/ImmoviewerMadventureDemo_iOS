//
// Created by admin on 16/8/24.
//

#ifndef APP_ANDROID_GLCOLORLOOKUPFILTER_H
#define APP_ANDROID_GLCOLORLOOKUPFILTER_H

#include "GLFilter.h"

class GLColorLookupFilter : public GLFilter {
public:

    GLColorLookupFilter();

    void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);

    void prepareGLProgramSlots(GLint program);

    void releaseGLObjects();

    inline void setIntensity(float intensity) {_intensity = intensity;}
    inline float getIntensity() {return _intensity;}

    inline void setLookupTexture(GLint lookupTexture) {_lookupTexture = lookupTexture;};

protected:

    GLint _uniTexture;
    GLint _uniLookupTexture;
    GLint _uniIntensity;

    GLint _atrPosition;
    GLint _atrTexcoord;

    float _intensity;
    GLint _lookupTexture;
};

//typedef AutoRef<GLColorLookupFilter> GLColorLookupFilterRef;

#endif //APP_ANDROID_GLCOLORLOOKUPFILTER_H
