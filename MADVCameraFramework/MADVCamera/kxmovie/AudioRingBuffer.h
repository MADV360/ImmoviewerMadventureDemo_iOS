#pragma once

#define RING_BUFFER_OK 0;
#define RING_BUFFER_EMPTY 1;
#define RING_BUFFER_FULL 2;
#define RING_BUFFER_NOTAVAILABLE 3;

#include <string.h>     //memset, memcpy

/**
 * This buffer can be used by one read and one write thread at any one time
 * without the risk of data corruption.
 * If you intend to call the Reset() method, please use Locks.
 * All other operations are thread-safe.
 */
class AudioRingBuffer
{

public:
    AudioRingBuffer() :
        m_iReadPos(0),
        m_iWritePos(0),
        m_iRead(0),
        m_iWritten(0),
        m_iSize(0),
        m_Buffer(NULL)
    {
    }

    AudioRingBuffer(unsigned int size) :
        m_iReadPos(0),
        m_iWritePos(0),
        m_iRead(0),
        m_iWritten(0),
        m_iSize(0),
        m_Buffer(NULL)
    {
        Create(size);
    }

    ~AudioRingBuffer()
    {
        if (m_Buffer)
            free(m_Buffer);
        m_Buffer = NULL;
    }

    /**
     * Allocates space for buffer, and sets it's contents to 0.
     *
     * @return true on success, false otherwise
     */
    bool Create(int size)
    {
        m_Buffer = (unsigned char*)malloc(size);
        if (m_Buffer)
        {
            m_iSize = size;
            memset(m_Buffer, 0, m_iSize);
            return true;
        }
        return false;
    }

    /**
     * Fills the buffer with zeros and resets the pointers.
     * This method is not thread-safe, so before using this method
     * please acquire a Lock()
     */
    void Reset()
    {
        m_iWritten = 0;
        m_iRead = 0;
        m_iReadPos = 0;
        m_iWritePos = 0;
    }

    /**
     * Writes data to buffer.
     * Attempt to write more bytes than available results in RING_BUFFER_FULL.
     *
     * @return RING_BUFFER_OK on success, otherwise an error code
     */
    int Write(unsigned char* src, unsigned int size)
    {
        unsigned int space = GetWriteSize();

        //do we have enough space for all the data?
        if (size > space)
        {
            return RING_BUFFER_FULL;
        }
        
        unsigned int prevWritePos = m_iWritePos;

        //no wrapping?
        if (m_iSize > size + m_iWritePos)
        {
            memcpy(&(m_Buffer[m_iWritePos]), src, size);
            m_iWritePos += size;
        }
        //need to wrap
        else
        {
            unsigned int first = m_iSize - m_iWritePos;
            unsigned int second = size - first;
            memcpy(&(m_Buffer[m_iWritePos]), src, first);
            memcpy(&(m_Buffer[0]), &src[first], second);
            m_iWritePos = second;
        }
        
        //NSLog(@"Write %d to %d - %d  total:%d", size, prevWritePos, m_iWritePos, m_iWritten);
        
        //we can increase the write count now
        m_iWritten += size;
        return RING_BUFFER_OK;
    }

    /**
     * Reads data from buffer.
     * Attempt to read more bytes than available results in RING_BUFFER_NOTAVAILABLE.
     * Reading from empty buffer returns RING_BUFFER_EMPTY
     *
     * @return RING_BUFFER_OK on success, otherwise an error code
     */
    int Read(unsigned char* dest, unsigned int size)
    {
        unsigned int space = GetReadSize();
        

        //want to read more than we have written?
        if (space <= 0)
        {
            return RING_BUFFER_EMPTY;
        }

        //want to read more than we have available
        if (size > space)
        {
            return RING_BUFFER_NOTAVAILABLE;
        }

        unsigned int prevReadPos = m_iReadPos;
        //no wrapping?
        if (size + m_iReadPos < m_iSize)
        {
            memcpy(dest, &(m_Buffer[m_iReadPos]), size);
            m_iReadPos += size;
        }
        //need to wrap
        else
        {
            unsigned int first = m_iSize - m_iReadPos;
            unsigned int second = size - first;
            memcpy(dest, &(m_Buffer[m_iReadPos]), first);
            memcpy(&dest[first], &(m_Buffer[0]), second);
            m_iReadPos = second;
        }
        //we can increase the read count now
        m_iRead += size;
        
        //NSLog(@"Read %d to %d - %d total: %d", size, prevReadPos, m_iReadPos, m_iRead);

       /* for (int i = 0; i < size/16; i++)
           NSLog(@" %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x", dest[i*16], dest[i*16 + 1], dest[i*16 + 2], dest[i*16 + 3], dest[i*16 + 4], dest[i*16 + 5], dest[i*16 + 6], dest[i*16 + 7]
                 , dest[i*16 + 8], dest[i*16 + 9], dest[i*16 + 10], dest[i*16 + 11], dest[i*16 + 12], dest[i*16 + 13], dest[i*16 + 14], dest[i*16 + 15]);
         */
        return RING_BUFFER_OK;
    }

    /**
     * Dumps the buffer.
     */
    void Dump()
    {
        unsigned char* bufferContents = (unsigned char*)malloc(m_iSize + 1);
        for (unsigned int i = 0; i < m_iSize; i++)
        {
            if (i >= m_iReadPos && i < m_iWritePos)
                bufferContents[i] = m_Buffer[i];
            else
                bufferContents[i] = '_';
        }
        bufferContents[m_iSize] = '\0';
        free(bufferContents);
    }

    /**
     * Returns available space for writing to buffer.
     * Attempt to write more bytes than available results in RING_BUFFER_FULL.
     */
    unsigned int GetWriteSize()
    {
        return m_iSize - (m_iWritten - m_iRead);
    }

    /**
     * Returns available space for reading from buffer.
     * Attempt to read more bytes than available results in RING_BUFFER_EMPTY.
     */
    unsigned int GetReadSize()
    {
        return m_iWritten > m_iRead ? m_iWritten - m_iRead : 0;
    }

    /**
     * Returns the buffer size.
     */
    unsigned int GetMaxSize()
    {
        return m_iSize;
    }

private:
    unsigned int m_iReadPos;
    unsigned int m_iWritePos;
    unsigned int m_iRead;
    unsigned int m_iWritten;
    unsigned int m_iSize;
    unsigned char* m_Buffer;
};
