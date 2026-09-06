package com.homestock.core.storage;

import org.springframework.web.multipart.MultipartFile;

public interface StorageService {
    String storeFile(MultipartFile file, String subDirectory);
    void deleteFile(String fileUrl);
}
