#include <iostream>
#include <string>
#include "server.h"
#include "dicom_handler.h"

int main(int argc, char* argv[]) {
    std::cout << "ONIS Site Server v1.0.0" << std::endl;
    std::cout << "Starting server..." << std::endl;
    
    try {
        // Initialize server
        Server server;
        
        // Initialize DICOM handler
        DicomHandler dicomHandler;
        
        // Start server
        server.start();
        
        std::cout << "Server started successfully" << std::endl;
        std::cout << "Press Ctrl+C to stop" << std::endl;
        
        // Keep server running
        server.wait();
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
} 