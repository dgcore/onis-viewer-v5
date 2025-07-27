#ifndef ONIS_DICOM_HANDLER_H
#define ONIS_DICOM_HANDLER_H

#include <string>
#include <vector>

class DicomHandler {
public:
    DicomHandler();
    ~DicomHandler();
    
    bool loadFile(const std::string& filePath);
    bool saveFile(const std::string& filePath);
    
    std::string getPatientName() const;
    std::string getStudyDescription() const;
    
    bool isValid() const;
    
private:
    class Impl;
    std::unique_ptr<Impl> pImpl;
};

#endif // ONIS_DICOM_HANDLER_H 