//
// Created by xieht on 2023/6/5.
//

#include <stdio.h>
#include "library.h"

//用#将当前的内容转换成字符串
#define DPRINT(expr) printf("<main>%s = %d\n", #expr, expr);


//用##，在编译预处理阶段实现字符串的连接；此处将test字符串和x字符串的连接
#define test(x) test##x


void test1(int a)
{
    printf("test1 a = %d\n",a);
}

int main(void)
{
        int x=3;
        int y=5;
    DPRINT(x/y);
    DPRINT(x+y);
    DPRINT(x*y);

    test(1)(100);

    return 0;
}