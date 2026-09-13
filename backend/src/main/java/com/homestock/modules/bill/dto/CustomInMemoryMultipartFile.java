package com.homestock.modules.bill.dto;

import org.springframework.web.multipart.MultipartFile;

import java.io.*;

public class CustomInMemoryMultipartFile implements MultipartFile {

    private final String name;
    private final String originalFilename;
    private final String contentType;
    private final byte[] bytes;

    public CustomInMemoryMultipartFile(String name, String originalFilename, String contentType, byte[] bytes) {
        this.name = name != null ? name : "file";
        this.originalFilename = originalFilename != null ? originalFilename : "receipt.jpg";
        this.contentType = contentType != null ? contentType : "image/jpeg";
        this.bytes = bytes != null ? bytes : new byte[0];
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public String getOriginalFilename() {
        return originalFilename;
    }

    @Override
    public String getContentType() {
        return contentType;
    }

    @Override
    public boolean isEmpty() {
        return bytes.length == 0;
    }

    @Override
    public long getSize() {
        return bytes.length;
    }

    @Override
    public byte[] getBytes() {
        return bytes;
    }

    @Override
    public InputStream getInputStream() {
        return new ByteArrayInputStream(bytes);
    }

    @Override
    public void transferTo(File dest) throws IOException, IllegalStateException {
        try (FileOutputStream fos = new FileOutputStream(dest)) {
            fos.write(bytes);
        }
    }
}
