package com.homestock.core.exception;

import lombok.Getter;

@Getter
public class BusinessRuleException extends RuntimeException {
    private final String code;

    public BusinessRuleException(String message) {
        super(message);
        this.code = "BUSINESS_RULE_VIOLATION";
    }

    public BusinessRuleException(String code, String message) {
        super(message);
        this.code = code;
    }
}
