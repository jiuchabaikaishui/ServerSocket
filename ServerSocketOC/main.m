//
//  main.m
//  ServerSocketOC
//
//  Created by 綦 on 17/3/15.
//  Copyright © 2017年 PowesunHolding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <arpa/inet.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        startSocket("127.0.0.1", 11332);
    }
    return 0;
}

void str_echo(int socket)
{
    char buf[1024];
    
    while (1) {
        bzero(buf, 1024);
        long byte_num = recv(socket, buf, 1024, 0);
        if (byte_num < 0) {
            return;
        }
        buf[byte_num] = '\0';
        printf("client said:%s\n", buf);
        
        char *result;
        NSString *str = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
        if ([str isEqualToString:@"1"]) {
            result = "你猜！";
        }
        else if ([str isEqualToString:@"2"])
        {
            result = "谢谢！";
        }
        else if ([str isEqualToString:@"3"])
        {
            result = "对不起！";
        }
        else if ([str isEqualToString:@"4"])
        {
            result = "好的！";
        }
        else
        {
            if (arc4random()%2 == 0) {
                result = "不知道你在说什么！";
            }
            else
            {
                result = buf;
            }
        }
        
        send(socket, result, 1024, 0);
    }
    
    //多进程的代码
//    ssize_t n;
//again:
//    while ((n = read(socket, buf, 1024)) > 0) {
//        NSString *str = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
//        NSLog(@"str:%@", str);
//        char *result;
//        if ([str isEqualToString:@"1"]) {
//            result = "你猜！";
//        }
//        else if ([str isEqualToString:@"2"])
//        {
//            result = "谢谢！";
//        }
//        else if ([str isEqualToString:@"3"])
//        {
//            result = "对不起！";
//        }
//        else if ([str isEqualToString:@"4"])
//        {
//            result = "好的！";
//        }
//        else
//        {
//            if (arc4random()%2 == 0) {
//                result = "不知道你在说什么！";
//            }
//            else
//            {
//                result = buf;
//            }
//        }
//        
//        write(socket, result, n);
//    }
//    
//    if (n < 0 && errno == EINTR) {
//        goto again;
//    }
//    else if (n < 0)
//    {
//        fprintf(stderr, "str_echo:read error! %s\n", strerror(errno));
//        
//        return;
//    }
    
//    ssize_t n;
//    char buf[1024];
//    
//again:
//    while ((n = read(socket, buf, 1024)) > 0) {
//        write(socket, buf, n);
//    }
//    
//    if (n < 0 && errno == EINTR) {
//        goto again;
//    }
//    else if (n < 0)
//    {
//        fprintf(stderr, "str_echo:read error! %s\n", strerror(errno));                \
//        exit(EXIT_FAILURE);
//    }
}

int startSocket(char *address, int port)
{
    struct sockaddr_in server_addr;
    server_addr.sin_len = sizeof(struct sockaddr_in);
    server_addr.sin_family = AF_INET;//AF_INET互联网地址簇
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(address);
    bzero(&server_addr.sin_zero, 8);
    
    //创建socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);//SOCK_STREAM 有链接
    
    if (server_socket == -1) {
        perror("socket error!");
        
        return 1;
    }
    
    //绑定socket：将创建的socket绑定到本地的IP地址和端口，此socket是半相关的，只是负责侦听客户端的连接请求，并不能用于和客户端通信
    int bind_result = bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr));
    if (bind_result == -1) {
        perror("bind error!");
        
        return 1;
    }
    
    //listen侦听 第一个参数是套接字，第二个参数为等待接受的连接的队列的大小，在connect请求过来的时候,完成三次握手后先将连接放到这个队列中，直到被accept处理。如果这个队列满>了，且有新的连接的时候，对方可能会收到出错信息。
    if (listen(server_socket, 5)) {
        perror("listen error!");
        
        return 1;
    }
    
    int client_socket;
    socklen_t address_len;
    struct sockaddr_in client_address;
    for (; ; ) {
        address_len = sizeof(client_address);
        client_socket = accept(server_socket, (struct sockaddr*)&client_address, &address_len);
        //1.使用多线程
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            str_echo(client_socket);
        });
        
        //2.使用多进程，可是会被系统kiss掉
//        pid_t childpid = fork();
//        if (childpid < 0) {
//            perror("error in fork!");
//        }
//        else if (childpid == 0)
//        {
//            close(server_socket);
//            str_echo(client_socket);
//            exit(0);
//        }
//        else
//        {
//            close(client_socket);
//        }
    }
    
    return 0;
}
