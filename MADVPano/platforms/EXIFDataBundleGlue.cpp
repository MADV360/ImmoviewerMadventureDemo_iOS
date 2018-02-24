//
// Created by QiuDong on 2017/8/14.
//
#include "EXIFDataBundleGlue.h"
#include "EXIFParser.h"
#include "Log.h"

static jclass clazz_EXIFDataBundle = NULL;
static jfieldID field_EXIFDataBundle_nativePointer = NULL;

void ensureClazzAndFields(JNIEnv* env, jobject self) {
    if (NULL == clazz_EXIFDataBundle)
    {
        clazz_EXIFDataBundle = env->GetObjectClass(self);
        field_EXIFDataBundle_nativePointer = env->GetFieldID(clazz_EXIFDataBundle, "nativePointer", "J");
    }
}

EXIFDataBundle* getCppEXIFDataBundleFromJava(JNIEnv* env, jobject self) {
    ensureClazzAndFields(env, self);
    jlong pointer = env->GetLongField(self, field_EXIFDataBundle_nativePointer);
    EXIFDataBundle* ret = (EXIFDataBundle*) (void*) pointer;
    return ret;
}

//void setCppEXIFDataBundleFromJava(JNIEnv* env, jobject self, EXIFDataBundle* ptrEXIFDataBundle) {
//    ensureClazzAndFields(env, self);
//    jlong pointer = (jlong) ptrEXIFDataBundle;
//    env->SetLongField(self, field_EXIFDataBundle_nativePointer, pointer);
//}

/*
 * Class:     EXIFDataBundle
 * Method:    getDateTime
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getDateTime(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return NULL;

    std::string cppstrDataTime = dataBundle->getDateTime();
    jstring jstrDataTime = env->NewStringUTF(cppstrDataTime.c_str());
    return jstrDataTime;
}

/*
 * Class:     EXIFDataBundle
 * Method:    getMaker
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getMaker(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return NULL;

    std::string cppstrMaker = dataBundle->getMaker();
    jstring jstrMaker = env->NewStringUTF(cppstrMaker.c_str());
    return jstrMaker;
}

/*
 * Class:     EXIFDataBundle
 * Method:    getDeviceModel
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getDeviceModel(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return NULL;

    std::string cppstrModel = dataBundle->getDeviceModel();
    jstring jstrModel = env->NewStringUTF(cppstrModel.c_str());
    return jstrModel;
}

/*
 * Class:     EXIFDataBundle
 * Method:    getExposureTime
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getExposureTime(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return NULL;

    std::string cppstrExposureTime = dataBundle->getExposureTime();
    jstring jstrExposureTime = env->NewStringUTF(cppstrExposureTime.c_str());
    return jstrExposureTime;
}
JNIEXPORT jstring JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getExposureBiasValue(JNIEnv *env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return NULL;

    std::string cppstrExposureBiasValue = dataBundle->getExposureBiasValue();
    jstring jstrExposureBiasValue = env->NewStringUTF(cppstrExposureBiasValue.c_str());
    return jstrExposureBiasValue;
}

/*
 * Class:     EXIFDataBundle
 * Method:    getISOSpeed
 * Signature: ()J
 */
JNIEXPORT jlong JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getISOSpeed(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0;

    return dataBundle->getISOSpeed();
}

/*
 * Class:     EXIFDataBundle
 * Method:    getWhiteBalance
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getWhiteBalance(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0;

    return dataBundle->getWhiteBalance();
}

/*
 * Class:     EXIFDataBundle
 * Method:    getXDimension
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getXDimension(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0;

    return dataBundle->getXDimension();
}

/*
 * Class:     EXIFDataBundle
 * Method:    getYDimension
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getYDimension(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0;

    return dataBundle->getYDimension();
}

/*
 * Class:     EXIFDataBundle
 * Method:    getXResolution
 * Signature: ()F
 */
JNIEXPORT jfloat JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getXResolution(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0.f;

    return dataBundle->getXResolution();
}

/*
 * Class:     EXIFDataBundle
 * Method:    getYResolution
 * Signature: ()F
 */
JNIEXPORT jfloat JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getYResolution(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0.f;

    return dataBundle->getYResolution();
}

/*
 * Class:     EXIFDataBundle
 * Method:    getLongitude
 * Signature: ()F
 */
JNIEXPORT jfloat JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getLongitude(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0.f;
    float longitude = dataBundle->getLongitude();
    std::string ref = dataBundle->getLongitudeRef();
    if (ref == "w" || ref == "W"){
        if (longitude > 0) longitude = -longitude;
    }

    return longitude;
}

/*
 * Class:     EXIFDataBundle
 * Method:    getLatitude
 * Signature: ()F
 */
JNIEXPORT jfloat JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getLatitude(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0.f;
    float latitude = dataBundle->getLatitude();
    std::string ref = dataBundle->getLatitudeRef();
    if (ref == "s" || ref == "S"){
        if (latitude > 0) latitude = -latitude;
    }

    return latitude;
}


/*
 * Class:     EXIFDataBundle
 * Method:    getAltitude
 * Signature: ()F
 */
JNIEXPORT jfloat JNICALL Java_com_madv360_exiv2_EXIFDataBundle_getAltitude(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return 0.f;

    return dataBundle->getAltitude();
}

/*
 * Class:     EXIFDataBundle
 * Method:    isStitchedPicture
 * Signature: ()Z
 */
JNIEXPORT jboolean JNICALL Java_com_madv360_exiv2_EXIFDataBundle_isStitchedPicture(JNIEnv* env, jobject self) {
    EXIFDataBundle* dataBundle = getCppEXIFDataBundleFromJava(env, self);
    if (!dataBundle) return true;

    return dataBundle->isStitchedPicture();
}

/*
 * Class:     EXIFDataBundle
 * Method:    createNative
 * Signature: (Ljava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_com_madv360_exiv2_EXIFDataBundle_createNative(JNIEnv* env, jobject self, jstring jpegPath) {
    jboolean isCopied = false;
    const char* cstrJpegPath = env->GetStringUTFChars(jpegPath, &isCopied);

    EXIFDataBundle* dataBundle = new EXIFDataBundle(cstrJpegPath);
//    setCppEXIFDataBundleFromJava(env, self, dataBundle);

    if (isCopied)
    {
        env->ReleaseStringUTFChars(jpegPath, cstrJpegPath);
    }

    return (jlong) dataBundle;
}

/*
 * Class:     EXIFDataBundle
 * Method:    releaseNative
 * Signature: (J)V
 */
JNIEXPORT void JNICALL Java_com_madv360_exiv2_EXIFDataBundle_releaseNative(JNIEnv* env, jobject self, jlong nativePointer) {
    EXIFDataBundle* dataBundle = (EXIFDataBundle*) nativePointer;
    delete dataBundle;
}