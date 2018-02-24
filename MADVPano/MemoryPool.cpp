//
//  MemoryPool.cpp
//  TestCyTrackableStateNode
//
//  Created by FutureBoy on 8/22/15.
//  Copyright (c) 2015 Cyllenge. All rights reserved.
//

#include "MemoryPool.h"
#include "Thread.h"

using namespace std;

MemoryBlockStruct::MemoryBlockStruct(int16_t sUnitSize, int16_t sCapacity)
: unitSize(sUnitSize)
, capacity(sCapacity)
, freeUnits(sCapacity - 1)
, freeUnitsHeadIndex(1)
//, pPrevBlock(NULL)
, pNextBlock(NULL) {
    int8_t* pData = dataBaseAddr;
    for (int i = 1; i < capacity; i++)
    {
        *reinterpret_cast<int16_t*>(pData) = i;
        pData += unitSize;
    }
}

MemoryPool::~MemoryPool() {
    MemoryBlock* pMyBlock = _pFirstBlock;
    while( pMyBlock != NULL)
    {
        pMyBlock = pMyBlock->pNextBlock;
        delete pMyBlock;
    }
}

MemoryPool::MemoryPool(int16_t unitSize, int16_t initSize, int16_t growSize)
: _pFirstBlock(NULL)
, _initSize(initSize)
, _growSize(growSize)
{
    if (unitSize > 4)
        _unitSize = (unitSize + (MEMPOOL_ALIGNMENT-1)) & ~(MEMPOOL_ALIGNMENT-1);
    else if (unitSize <= 2)
        _unitSize = 2;
    else
        _unitSize = 4;
}

void* MemoryPool::alloc()
{
#ifdef NOT_USE_POOL
    return malloc(_unitSize);
#else
    if (!_pFirstBlock)
    {
        _pFirstBlock = (MemoryBlock*) new(_unitSize, _initSize) MemoryBlock(_unitSize, _initSize);
        return (void*) _pFirstBlock->dataBaseAddr;
    }
    
    MemoryBlock* pMyBlock = _pFirstBlock;
    while (pMyBlock && 0 == pMyBlock->freeUnits)
        pMyBlock = pMyBlock->pNextBlock;
    
    if (pMyBlock)
    {
        int8_t* pFree = pMyBlock->dataBaseAddr + (pMyBlock->freeUnitsHeadIndex * _unitSize);
        pMyBlock->freeUnitsHeadIndex = *((int16_t*) pFree);
        pMyBlock->freeUnits--;
        return (void*)pFree;
    }
    else
    {
        if (0 == _growSize)
            return NULL;
        
        pMyBlock = (MemoryBlock*) new(_unitSize, _growSize) MemoryBlock(_unitSize, _growSize);
        if (NULL == pMyBlock)
            return NULL;
        
        pMyBlock->pNextBlock = _pFirstBlock;
//        _pFirstBlock->pPrevBlock = pMyBlock;
        _pFirstBlock = pMyBlock;
        
        return (void*) pMyBlock->dataBaseAddr;
    }
#endif
}

void MemoryPool::dealloc(void* pFree)
{
#ifdef NOT_USE_POOL
    free(pFree);
#else
    MemoryBlock* pMyBlock = _pFirstBlock;
    MemoryBlock* pPrevBlock = NULL;
    
    while (pMyBlock &&
           (pMyBlock->dataBaseAddr > pFree || pFree >= (pMyBlock->dataBaseAddr + pMyBlock->capacity * pMyBlock->unitSize)))
    {
        pPrevBlock = pMyBlock;
        pMyBlock = pMyBlock->pNextBlock;
    }
    
    if (NULL == pMyBlock)
    {
        return;
    }
    
    pMyBlock->freeUnits++;
    *((int16_t*) pFree) = pMyBlock->freeUnitsHeadIndex;
    pMyBlock->freeUnitsHeadIndex = (int16_t) (((long)pFree - (long)pMyBlock->dataBaseAddr) / _unitSize);
    
//    printf("\nfreeUnits = %d\n", pMyBlock->freeUnits);///!!!For Debug
    if (pMyBlock->freeUnits == pMyBlock->capacity)
    {
//        _pFirstBlock = pPrevBlock;
//        if (NULL != pPrevBlock)
//        {
//            pPrevBlock->pNextBlock = pMyBlock->pNextBlock;
//        }
//        delete pMyBlock;
    }
    else if (_pFirstBlock != pMyBlock)
    {
        pPrevBlock->pNextBlock = pMyBlock->pNextBlock;
        pMyBlock->pNextBlock = _pFirstBlock;
        _pFirstBlock = pMyBlock;
    }
#endif
}

MemoryPool* MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(int16_t unitSize, int16_t initSize, int16_t growSize) {
    map<int16_t, map<long, MemoryPool*>* >::iterator found = threadLocalMemoryPoolsOfUnitSizes().find(unitSize);
    map<long, MemoryPool*>* poolsOfTID = NULL; 
    if (threadLocalMemoryPoolsOfUnitSizes().end() == found)
    {
        poolsOfTID = new map<long, MemoryPool*>;
        threadLocalMemoryPoolsOfUnitSizes().insert(make_pair(unitSize, poolsOfTID));
    }
	else
	{
		poolsOfTID = found->second;
	}
    
    long tid = getCurrentThreadID();
	map<long, MemoryPool*>::iterator iterPool = poolsOfTID->find(tid);
    MemoryPool* pool = NULL;
    if (iterPool == poolsOfTID->end())
    {
        pool = new MemoryPool(unitSize, initSize, growSize);
        poolsOfTID->insert(make_pair(tid, pool));
    }
    else
	{
		pool = iterPool->second;
	}
    return pool;
}

MemoryPool* MemoryPool::threadLocalMemoryPool(int16_t unitSize) {
    MemoryPool* pool = NULL;
    
    map<int16_t, map<long, MemoryPool*>* >::iterator found = threadLocalMemoryPoolsOfUnitSizes().find(unitSize);
    map<long, MemoryPool*>* poolsOfTID = NULL; 
    if (threadLocalMemoryPoolsOfUnitSizes().end() == found)
    {
        poolsOfTID = new map<long, MemoryPool*>;
        threadLocalMemoryPoolsOfUnitSizes().insert(make_pair(unitSize, poolsOfTID));
    }
	else
	{
		poolsOfTID = found->second;
	}
    
    if (NULL != poolsOfTID)
    {
        long tid = getCurrentThreadID();
		map<long, MemoryPool*>::iterator iterPool = poolsOfTID->find(tid);
		if (iterPool != poolsOfTID->end())
		{
			pool = iterPool->second;
		}
    }
    
    return pool;
}

//map<int16_t, map<long, MemoryPool*>* > MemoryPool::s_threadLocalMemoryPoolsOfUnitSizes = map<int16_t, map<long, MemoryPool*>* >();

//void* operator new(size_t size) {
//    MemoryPool* memPool = MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(size);
//    if (NULL != memPool)
//    {
//        return memPool->alloc();
//    }
//    else
//    {
//        return ::operator new(size);
//    }
//}
//
//void operator delete(void* ptr, size_t size) {
//    MemoryPool* memPool = MemoryPool::obtainThreadLocalMemoryPoolsOfUnitSize(size);
//    if (NULL != memPool)
//    {
//        memPool->free(ptr);
//    }
//    else
//    {
//        ::operator delete(ptr, size);
//    }
//}
