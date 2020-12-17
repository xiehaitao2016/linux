#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/ioctl.h>

#include <netinet/in.h>
#include <string.h>
#include "socket_common.h"

#define SERVER_PORT 5000
#define BUFF_LEN 1024
#define SERVER_IP "192.168.200.198"


void udp_msg_sender(int fd, struct sockaddr* dst)
{

    socklen_t len;
    struct sockaddr_in src;
    int                 mlen;          /* length of message */
    char                message[1024]; /* Test message */
    unsigned int txSequence = 0;
    struct timeval *t1;
    struct timeval t2;
    struct timeval *t3;
    unsigned long send_t1,their_t3,back_t2,mine;
    struct sockaddr_in *new_dst = dst;
    long long roundTripCost = 0;
    int currentCost  = 0;


    round_trip_msg *pmsg = (round_trip_msg *)message;
    mlen = sizeof(round_trip_msg);
    while(1)
    {
        bzero (message, 1024);        
        pmsg->sequence = txSequence++;   
        gettimeofday(&pmsg->timeStamp[0], NULL);    
        t1 = (struct timeval *)&pmsg->timeStamp[0];
        
        len = sizeof(*dst);
        send_t1 = t1->tv_sec*1000000 + t1->tv_usec;     
        //printf("sendto family : %d, port : %d, addr : 0x%x\n",new_dst->sin_family,new_dst->sin_port,new_dst->sin_addr.s_addr);   
        sendto(fd, message, mlen, 0, dst, len);
        //send_packet(fd,dst,len,message,mlen);
        //printf("sequence: %d;   Tx TIME %llu us   ",pmsg->sequence,send_t1);  //打印自己发送的信息

        //recv_packet_and_timestamp_ns(fd, message, mlen, &src, MSG_ERRQUEUE, &tns1);
        //printf("[*] t1 = %ld.%09ld\n", (long) tns1.tv_sec, (long) tns1.tv_nsec);
        #if 1
        memset(message, 0, BUFF_LEN);
        recvfrom(fd, message, mlen, 0, (struct sockaddr*)&src, &len);  //接收来自server的信息        
        pmsg = (round_trip_msg *)message;
        t1 = (struct timeval *)&pmsg->timeStamp[0];
        t3 = (struct timeval *)&pmsg->timeStamp[1];
        gettimeofday(&t2, NULL);

        send_t1 = t1->tv_sec*1000000 + t1->tv_usec;
        their_t3 = t3->tv_sec*1000000 + t3->tv_usec;
        back_t2 = t2.tv_sec*1000000 + t2.tv_usec;
        mine = (back_t2+send_t1)/2;
        currentCost = (int)(back_t2-send_t1);        

        //printf("recvfrom family : %d, port : %d, addr : 0x%x\n",src.sin_family,src.sin_port,src.sin_addr.s_addr);
        printf("round trip cost : %llu us, round trip Jitter : %d us\n",currentCost,(roundTripCost > 0 ? (int)(currentCost - roundTripCost) : 0));

        roundTripCost = currentCost;
        #endif
        sleep(2);  //2秒发送一次消息
    }
}

/*
    client:
            socket-->sendto-->revcfrom-->close
*/

int main(int argc, char* argv[])
{
    int client_fd;
    struct sockaddr_in ser_addr;
	char *streamName = "";
	int use_tsn = 0;
	   

    client_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if(client_fd < 0)
    {
        printf("create socket fail!\n");
        return -1;
    }
	
	
	if(argc > 1){
		streamName = argv[1];		
		use_tsn = 1;
	}

    memset(&ser_addr, 0, sizeof(ser_addr));
    ser_addr.sin_family = AF_INET;
    ser_addr.sin_addr.s_addr = inet_addr(SERVER_IP);
    //ser_addr.sin_addr.s_addr = htonl(INADDR_ANY);  //注意网络序转换
    ser_addr.sin_port = htons(SERVER_PORT);  //注意网络序转换
    printf("setup client socket, port : %d, addr : 0x%x\n",ser_addr.sin_port,ser_addr.sin_addr.s_addr);


	if(use_tsn == 1){
		printf("bind this socket to tsn flow %s\n",streamName);
		#if 0
		if(setsockopt(client_fd, SOL_SOCKET, SO_X_QBV,(void *)streamName, TSN_STREAMNAMSIZ) < 0 )
		{
			(void)printf( "bind failed : %s [%d].\n",streamName, -1);
			(void)close (client_fd);
			return -1;
		}	
		#endif

		(void)printf( "bind ok : %s.\n",streamName);		
	}

    udp_msg_sender(client_fd, (struct sockaddr*)&ser_addr);

    close(client_fd);

    return 0;
}
