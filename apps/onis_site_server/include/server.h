#ifndef ONIS_SITE_SERVER_H
#define ONIS_SITE_SERVER_H

#include <string>
#include <memory>

class Server {
public:
    Server();
    ~Server();
    
    void start();
    void stop();
    void wait();
    
    bool isRunning() const;
    
private:
    class Impl;
    std::unique_ptr<Impl> pImpl;
};

#endif // ONIS_SITE_SERVER_H 