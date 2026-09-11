package com.homestock.modules.notification.ml.model;

import com.homestock.modules.notification.dto.MLFeatureVectorDto;

/**
 * PredictionModel:
 * Pluggable contract for stock depletion prediction models.
 * Allows replacing statistical / regression models with neural / ONNX / Tribuo
 * models in the future without modifying business logic.
 */
public interface PredictionModel {

    String getModelName();

    boolean canHandle(MLFeatureVectorDto features);

    StockPredictionResult predict(MLFeatureVectorDto features);
}
