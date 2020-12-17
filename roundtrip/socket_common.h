#ifndef __COMMON_H__
#define __COMMON_H__
#include <stdio.h>
#include <sys/time.h>
//#include <tsnStream.h>

typedef struct packet_rec
{
    unsigned int    sequence;    
    struct timeval timeStamp[2];
} round_trip_msg;

#endif
