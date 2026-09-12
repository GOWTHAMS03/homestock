package com.homestock.core.storage;

import com.homestock.core.exception.BusinessRuleException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Objects;
import java.util.UUID;

@Service
@ConditionalOnProperty(name = "app.storage.provider", havingValue = "local", matchIfMissing = true)
public class LocalStorageService implements StorageService {

    public static final long MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB
    private static final java.util.Set<String> ALLOWED_MIME_TYPES = java.util.Set.of(
            "image/jpeg", "image/png", "image/webp"
    );
    private static final java.util.Set<String> ALLOWED_EXTENSIONS = java.util.Set.of(
            ".jpg", ".jpeg", ".png", ".webp"
    );

    private final Path rootLocation;

    public LocalStorageService(@Value("${app.storage.local.upload-dir:./uploads}") String uploadDir) {
        this.rootLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.rootLocation);
        } catch (IOException e) {
            throw new RuntimeException("Could not initialize local storage folder: " + uploadDir, e);
        }
    }

    @Override
    public String storeFile(MultipartFile file, String subDirectory) {
        if (file == null || file.isEmpty()) {
            throw new BusinessRuleException("INVALID_FILE", "Cannot store empty file.");
        }

        if (file.getSize() > MAX_FILE_SIZE_BYTES) {
            throw new BusinessRuleException("FILE_TOO_LARGE", "File size exceeds the 5MB maximum limit.");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_MIME_TYPES.contains(contentType.toLowerCase())) {
            throw new BusinessRuleException("INVALID_FILE_TYPE", "Only JPEG, PNG, and WebP images are allowed.");
        }

        String rawFilename = file.getOriginalFilename();
        if (rawFilename == null || rawFilename.isBlank()) {
            rawFilename = "upload.png";
        }

        String originalFilename = StringUtils.cleanPath(rawFilename);
        if (originalFilename.contains("..") || originalFilename.contains("/") || originalFilename.contains("\\")) {
            throw new BusinessRuleException("MALICIOUS_PATH", "Invalid file name: path traversal detected.");
        }

        String extension = "";
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex >= 0) {
            extension = originalFilename.substring(dotIndex).toLowerCase();
        }

        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new BusinessRuleException("INVALID_FILE_EXTENSION", "File extension " + extension + " is not permitted.");
        }

        // Sanitize subDirectory
        String safeSubDir = StringUtils.cleanPath(subDirectory).replaceAll("[^a-zA-Z0-9_-]", "");
        Path targetDir = this.rootLocation.resolve(safeSubDir).normalize();
        if (!targetDir.startsWith(this.rootLocation)) {
            throw new SecurityException("Path traversal attempt detected in target directory.");
        }

        String newFilename = UUID.randomUUID().toString() + extension;
        Path destinationFile = targetDir.resolve(newFilename).normalize();
        if (!destinationFile.startsWith(this.rootLocation)) {
            throw new SecurityException("Path traversal attempt detected in target file path.");
        }

        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), destinationFile, StandardCopyOption.REPLACE_EXISTING);
            return "/uploads/" + safeSubDir + "/" + newFilename;
        } catch (IOException e) {
            throw new BusinessRuleException("STORAGE_ERROR", "Failed to store file: " + e.getMessage());
        }
    }

    @Override
    public void deleteFile(String fileUrl) {
        if (fileUrl == null || !fileUrl.startsWith("/uploads/")) {
            return;
        }
        try {
            String relativePath = fileUrl.replaceFirst("/uploads/", "");
            String safeRelativePath = StringUtils.cleanPath(relativePath);
            Path filePath = this.rootLocation.resolve(safeRelativePath).normalize();
            if (filePath.startsWith(this.rootLocation)) {
                Files.deleteIfExists(filePath);
            }
        } catch (IOException ignored) {
        }
    }
}
