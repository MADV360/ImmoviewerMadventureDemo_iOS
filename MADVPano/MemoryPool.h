//
//  MemoryPool.h
//  TestCyTrackableStateNode
//
//  Created by FutureBoy on 8/22/15.
//  Copyright (c) 2015 Cyllenge. All rights reserved.
//

#ifndef __TestCyTrackableStateNode__MemoryPool__
#define __TestCyTrackableStateNode__MemoryPool__

//#define NOT_USE_POOL

#define MEMPOOL_ALIGNMENT   4

#include <sys/types.h>
#include <stdlib.h>
#include <stdint.h>
#include <map>

typedef struct MemoryBlockStruct
{
    int16_t             unitSize;
    int16_t             capacity;
    
    int16_t             freeUnits;
    int16_t             freeUnitsHeadIndex;
    
//    MemoryBlockStruct*  pPrevBlock;
    MemoryBlockStruct*  pNextBlock;
    
    int16_t             dummyAlignBytes;
    
    int8_t              dataBaseAddr[1];
    
    static void* operator new(size_t, int16_t sUnitSize, int16_t sCapacity)
    {
//        return ::operator new(sizeof(MemoryBlockStruct) + sUnitSize * sCapacity);
        return malloc(sizeof(MemoryBlockStruct) + sUnitSize * sCapacity);
    }
    
    static void  operator delete(void *p, size_t)
    {
//        ::operator delete (p);
        free(p);
    }
    
    MemoryBlockStruct(int16_t sUnitSize = sizeof(void*), int16_t sCapacity = 1024);
    
    ~MemoryBlockStruct() {}
    
} MemoryBlock;

//void* operator new(size_t size);
//
//void operator delete(void* p, size_t size);

class MemoryPool
{
public:
    
    ~MemoryPool();
    MemoryPool(int16_t unitSize, int16_t initSize = 1024, int16_t growSize = 256);
    
    void*   alloc();
    void    dealloc(void* p);

    static MemoryPool* obtainThreadLocalMemoryPoolsOfUnitSize(int16_t unitSize, int16_t initSize = 1024, int16_t growSize = 256);
    
    static MemoryPool* threadLocalMemoryPool(int16_t unitSize);
    
private:
    
    MemoryBlock*    _pFirstBlock;
    
    int16_t         _unitSize;
    int16_t         _initSize;
    int16_t         _growSize;
    
    inline static std::map<int16_t, std::map<long, MemoryPool*>* >& threadLocalMemoryPoolsOfUnitSizes() {
        static std::map<int16_t, std::map<long, MemoryPool*>* > s_threadLocalMemoryPoolsOfUnitSizes;
        return s_threadLocalMemoryPoolsOfUnitSizes;
    }
};

#endif /* defined(__TestCyTrackableStateNode__MemoryPool__) */
