#ifndef AUTOREF_H
#define AUTOREF_H
/*
 * AutoRef.h
 *
 *  Created on: 2012-10-3
 *      Author: domqiu
 */

#include <stdlib.h>
#include <map>
#include <pthread.h>
//#include "MemoryPool.h"
#include "Log.h"

#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
#pragma comment(lib, "pthreadVC2.lib")
#endif

//#define TESTING

#ifdef TESTING

#include <stdlib.h>
#include <iostream>
using namespace std;

#define COUT_DIRECTIVE(p) { \
if (NULL == p) \
{ \
    cout << "NULL" << endl; \
    } \
    else \
    { \
        cout << hex << (long)(p); \
        cout << endl; \
    } \
    }
    //#define COUT_DIRECTIVE(p)
    
#endif
    
    template<typename T>
    void initMutexT();
    
    //namespace mystl
    //{
    template<typename T>
    class AutoRef
    {
        
    public:
        
        inline int refCount() const {return *pRefCount;}
        
        ~AutoRef(void);
        
        AutoRef();
        
        AutoRef(T* p);
        
        AutoRef(const AutoRef<T>& other);
        
        AutoRef(const T& other);
        
        AutoRef& operator = (const AutoRef& other);
        
        T* operator -> ();
        
        T& operator * ();
        
        ///!!!AutoRef<T> operator [] (int index);
        
        operator T ();
        
        operator T* ();

//        operator long ();
        
        bool operator == (const AutoRef& other);

//        bool operator == (long pointer);

        bool operator < (const AutoRef& other) const;
        
        AutoRef* operator & ();///???
        
        T* pWrappedData;
        
        int* pRefCount;
        
        static void initMutex() {
            pthread_mutex_init(&sClassMutex, NULL);
        }
        
    protected:
        
    private:
        
        void destructOne(AutoRef& ba);
        
        void Release();
        
//        void* operator new (size_t size);
        
//        void operator delete (void* p, size_t size);
        
        inline static std::map<void*, int* >& pointer2RefCountMap() {
            static std::map<void*, int* >* g_pointer2RefCountMap = new std::map<void*, int* >;
            return *g_pointer2RefCountMap;
        }
        
        inline static pthread_mutex_t& classMutex() {
            static pthread_once_t onceToken = PTHREAD_ONCE_INIT;
            pthread_once(&onceToken, initMutexT<T>);
            return sClassMutex;
        }
        
        inline void lock() {
            pthread_mutex_t& mutex = classMutex();
            pthread_mutex_lock(&mutex);
        }
        
        inline void unlock() {
            pthread_mutex_t& mutex = classMutex();
            pthread_mutex_unlock(&mutex);
        }
        
        static pthread_mutex_t sClassMutex;
//        static std::map<T*, int*> pointer2RefCountMap;
    };
    
    template<typename T>
    pthread_mutex_t AutoRef<T>::sClassMutex;
    
    template<typename T>
    void initMutexT() {
        AutoRef<T>::initMutex();
    }
    
    //////////////////////////////////
//    template<typename T>
//    std::map<T*, int*> AutoRef<T>::pointer2RefCountMap;
    
    template<typename T>
    AutoRef<T>::AutoRef()
    {
#ifdef TESTING
        cout << "Construct AutoRef(void)" << endl;
#endif
        
        this->pWrappedData = NULL; // (TWrapped*)malloc(sizeof(TWrapped));
        
        this->pRefCount = new int;//(int*) MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(sizeof(int))->alloc();
        *this->pRefCount = 1;
    }
    
    template<typename T>
    AutoRef<T>::AutoRef(T* p)
    {
        lock();
        
        this->pWrappedData = p; // (TWrapped*)malloc(sizeof(TWrapped));
		typename std::map<void*, int* >::iterator found = pointer2RefCountMap().find(p);
        if (found == pointer2RefCountMap().end())
        {
            this->pRefCount = new int;//(int*) MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(sizeof(int))->alloc();
            *this->pRefCount = 1;
			//ALOGE("\n#Crash# AutoRef ctor()  pWrappedData=0x%lx, new *pRefCount(0x%lx)=%d; @0x%lx\n", (long)pWrappedData, (long)pRefCount, *pRefCount, (long)this);
            pointer2RefCountMap().insert(std::make_pair(p, this->pRefCount));
        }
        else
        {
            this->pRefCount = found->second;
            (*this->pRefCount)++;
			//ALOGE("\n#Crash# AutoRef ctor()  pWrappedData=0x%lx, found *pRefCount(0x%lx)=%d; @0x%lx\n", (long)pWrappedData, (long)pRefCount, *pRefCount, (long)this);
        }
#ifdef TESTING
        cout << "Construct AutoRef(T*) : refCount = " << (*this->pRefCount) << ", ";
        COUT_DIRECTIVE(p);
#endif
        unlock();
    }
    
    template<typename T>
    AutoRef<T>::AutoRef(const AutoRef<T>& other)
    {
        lock();
        
        this->pWrappedData = other.pWrappedData;
		this->pRefCount = other.pRefCount;
        (*this->pRefCount)++;
		//ALOGE("\n#Crash# AutoRef copy ctor()  pWrappedData=0x%lx, *pRefCount(0x%lx)=%d; @0x%lx\n", (long)pWrappedData, (long)pRefCount, *pRefCount, (long)this);
#ifdef TESTING
        cout << "Construct AutoRef(const AutoRef<T>& other) : refCount = " << (*other.pRefCount) << ", ";
        COUT_DIRECTIVE(other.pWrappedData);
#endif
        
        unlock();
    }
    /*
     template<typename T>
     AutoRef<T>::AutoRef(const T& other)
     {
     this->pWrappedData = new T(other);
     
     this->pRefCount = other.pRefCount;
     (*this->pRefCount)++;
     
     #ifdef TESTING
     cout << "Construct AutoRef(const AutoRef&) {" << NULLABLE_CHARS((char*)other.array) << "}, RefCount = " << *this->pRefCount << endl;
     #endif
     
     }
     //*/
    template<typename T>
    void AutoRef<T>::destructOne(AutoRef& ba)
    {
        //#ifdef TESTING
        //        cout << "destructOne(.) : ";
        //        COUT_DIRECTIVE(ba.pWrappedData);
        //#endif
        lock();
        
        if (NULL == ba.pRefCount)
        {
            unlock();
            return;
        }
        
        //#ifdef TESTING
        //        cout << "destructOne(.) : #1";
        //        cout << endl;
        //#endif
        int refCountBeforeDecrease = (*ba.pRefCount)--;
        if (0 == refCountBeforeDecrease - 1)
        {
#ifdef TESTING
            cout << "destructOne : Actually delete wrapped data : ";
            COUT_DIRECTIVE(ba.pWrappedData);
#endif
            std::map<void*, int* >::iterator found = pointer2RefCountMap().find(ba.pWrappedData);
            if (found != pointer2RefCountMap().end())
            {
                pointer2RefCountMap().erase(found);///!!!Why???
            }
			//ALOGE("\n#Crash# AutoRef delete#0 pWrappedData(0x%lx), *pRefCount(0x%lx)=%d; @0x%lx\n", (long)ba.pWrappedData, (long)ba.pRefCount, (int)*ba.pRefCount, (long)&ba);
            if (NULL != ba.pWrappedData)
            {
				delete ba.pWrappedData;
                ba.pWrappedData = NULL;
            }
			//ALOGE("\n#Crash# AutoRef delete#1 *pRefCount(0x%lx)=%d; @0x%lx\n", (long)ba.pRefCount, (int)*ba.pRefCount, (long)&ba);
            delete ba.pRefCount;//MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(sizeof(int))->dealloc(ba.pRefCount);//
            ba.pRefCount = NULL;
			//ALOGE("\n#Crash# AutoRef delete#2 @0x%lx\n", (long)&ba);
        }
#ifdef TESTING
        else
        {
            cout << "destructOne : Reference count left : " << (*ba.pRefCount) << ", ";
            COUT_DIRECTIVE(ba.pWrappedData);
        }
#endif
        
        unlock();
    }
    
    template<typename T>
    AutoRef<T>::~AutoRef(void)
    {
#ifdef TESTING
        cout << "~AutoRef : ";
        COUT_DIRECTIVE(pWrappedData);
#endif
        
        AutoRef::destructOne(*this);
    }
    
    template<typename T>
    void AutoRef<T>::Release()
    {
#ifdef TESTING
        cout << "Release" << endl;
#endif
        AutoRef::destructOne(*this);
    }
    
    template<typename T>
    AutoRef<T>& AutoRef<T>::operator = (const AutoRef& other)
    {
#ifdef TESTING
        cout << "operator = : refCount = " << (*other.pRefCount + 1) << ", ";
        COUT_DIRECTIVE(other.pWrappedData);
#endif
        
        (*other.pRefCount)++;
        AutoRef::destructOne(*this);
        this->pWrappedData = other.pWrappedData;
		this->pRefCount = other.pRefCount;
		//ALOGE("\n#Crash# AutoRef =()  pWrappedData=0x%lx, *pRefCount(0x%lx)=%d, @0x%lx\n", (long)pWrappedData, (long)pRefCount, *pRefCount, (long)this);
		return *this;
    }
    
    template<typename T>
    T* AutoRef<T>::operator -> ()
    {
        return pWrappedData;
    }
    
    template<typename T>
    T& AutoRef<T>::operator * ()
    {
        return *pWrappedData;
    }
    /*
     template<typename T>
     AutoRef<T> AutoRef<T>::operator [] (int index)
     {
     return AutoRef<T>(pWrappedData + index);
     }
     //*/
    template<typename T>
    AutoRef<T>::operator T ()
    {
        return *pWrappedData;
    }
    
    template<typename T>
    AutoRef<T>::operator T* ()
    {
        return pWrappedData;
    }

//template<typename T>
//AutoRef<T>::operator long ()
//{
//    return (long)pWrappedData;
//}

//    template<typename T>
//    void* AutoRef<T>::operator new (size_t size)
//    {
////        AutoRef* p = (AutoRef*)malloc(size);
////        return p;
//        MemoryPool* memPool = MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(size);
//        return memPool->alloc();
//    }
//
//    template<typename T>
//    void AutoRef<T>::operator delete (void* p, size_t size)
//    {
////        free(p);
//        MemoryPool* memPool = MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(size);
//        memPool->dealloc(p);
//    }
    
    template<typename T>
    AutoRef<T>* AutoRef<T>::operator & ()
    {
        return this;
    }
    
    template<typename T>
    bool AutoRef<T>::operator == (const AutoRef<T>& other)
    {
        if (this->pWrappedData == other.pWrappedData)
            return true;
        else
            return false;
    }

//template<typename T>
//bool AutoRef<T>::operator == (long pointer)
//{
//    if ((long)this->pWrappedData == pointer)
//        return true;
//    else
//        return false;
//}
    
    template<typename T>
    bool AutoRef<T>::operator < (const AutoRef& other) const
    {
        if (this->pWrappedData < other.pWrappedData)
            return true;
        else
            return false;
    }
    
    //} /* namespace mystl */
    
#endif //#ifndef AUTOREF_H
