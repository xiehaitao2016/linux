#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include "socket_common.h"

#define SERVER_PORT 5000
#define BUFF_LEN 1024

void handle_udp_msg(int fd)
{
    char buf[BUFF_LEN];  //接收缓冲区，1024字节
    socklen_t len;
    int count;
    struct sockaddr_in clent_addr;  //clent_addr用于记录发送方的地址信息
    struct timeval *t1;
    struct timeval *t2;
    round_trip_msg *pmsg = (round_trip_msg *)buf;
    while(1)
    {
        memset(buf, 0, BUFF_LEN);
        len = sizeof(clent_addr);
        count = recvfrom(fd, buf, sizeof(round_trip_msg), 0, (struct sockaddr*)&clent_addr, &len);  //recvfrom是拥塞函数，没有数据就一直拥塞
        if(count == -1)
        {
            printf("recieve data fail!\n");
            return;
        }
        //printf("recvfrom family : %d, port : %d, addr : 0x%x\n",clent_addr.sin_family,clent_addr.sin_port,clent_addr.sin_addr.s_addr);
        pmsg = (round_trip_msg *)buf;        
        
        t1 = (struct timeval *)&pmsg->timeStamp[0];
        gettimeofday(&pmsg->timeStamp[1], NULL);
        t2 = (struct timeval *)&pmsg->timeStamp[1];

        unsigned long send_t1 = t1->tv_sec*1000000 + t1->tv_usec;
        unsigned long recv_t2 = t2->tv_sec*1000000 + t2->tv_usec;     
        //printf("sendto family : %d, port : %d, addr : 0x%x\n",clent_addr.sin_family,clent_addr.sin_port,clent_addr.sin_addr.s_addr);      
        sendto(fd, buf, sizeof(round_trip_msg), 0, (struct sockaddr*)&clent_addr, len);  //发送信息给client，注意使用了clent_addr结构体指针
        printf("sequence: %d;   Tx TIME %llu us;  Rx TIME %llu us\n",pmsg->sequence,send_t1,recv_t2);  //打印client发过来的信息

    }
}


/*
    server:
            socket-->bind-->recvfrom-->sendto-->close
*/

int main(int argc, char* argv[])
{
    int server_fd, ret;
    struct sockaddr_in ser_addr;
    char *streamName = "";
    int use_tsn = 0;

    if(argc > 1){
		streamName = argv[1];		
		use_tsn = 1;
	}

    server_fd = socket(AF_INET, SOCK_DGRAM, 0); //AF_INET:IPV4;SOCK_DGRAM:UDP
    if(server_fd < 0)
    {
        printf("create socket fail!\n");
        return -1;
    }

    memset(&ser_addr, 0, sizeof(ser_addr));
    ser_addr.sin_family = AF_INET;
    ser_addr.sin_addr.s_addr = htonl(INADDR_ANY); //IP地址，需要进行网络序转换，INADDR_ANY：本地地址
    ser_addr.sin_port = htons(SERVER_PORT);  //端口号，需要网络序转换
    printf("setup server socket, port : %d, addr : 0x%x\n",ser_addr.sin_port,ser_addr.sin_addr.s_addr);

    ret = bind(server_fd, (struct sockaddr*)&ser_addr, sizeof(ser_addr));
    if(ret < 0)
    {
        printf("socket bind fail!\n");
        return -1;
    }

    if(use_tsn == 1){
		printf("bind this socket to tsn flow %s\n",streamName);
		#if 1
		if(setsockopt(server_fd, SOL_SOCKET, SO_X_QBV,(void *)streamName, TSN_STREAMNAMSIZ) < 0 )
		{
			(void)printf( "bind failed : %s [%d].\n",streamName, -1);
			(void)close (server_fd);
			return -1;
		}	
		#endif

		(void)printf( "bind ok : %s.\n",streamName);		
	}

    handle_udp_msg(server_fd);   //处理接收到的数据

    close(server_fd);
    return 0;
}
