#include <iostream>
#include <cstdlib>
#include <ctime>
#include <cstring>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#define PORT 8080

void generate_random_key(uint8_t* key, size_t key_len) {
    srand(time(nullptr));
    for (size_t i = 0; i < key_len; ++i) {
        key[i] = rand() % 256;
    }
}

int main() {
    int server_fd, new_socket;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt))) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, 3) < 0) {
        perror("listen");
        exit(EXIT_FAILURE);
    }
    	
	//uint8_t key[32];
	uint8_t key[32];
        generate_random_key(key, 32);
    while (true) {
        if ((new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) < 0) {
            perror("accept");
            exit(EXIT_FAILURE);
        }
	
        //uint8_t key[32];
        //generate_random_key(key, 32);
	
        send(new_socket, key, sizeof(key), 0);
        std::cout << "Key sent successfully" << std::endl;
        std::cout << "Sent Key: ";
    	for (int i = 0; i < sizeof(key); ++i) {
        printf("%02x", (unsigned char)key[i]);
    	}
    	std::cout << std::endl;

        close(new_socket);
    }

    close(server_fd);

    return 0;
}

