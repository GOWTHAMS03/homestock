package com.homestock.modules.deals.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Locale;

/**
 * High-performance, zero-cost geospatial grid and geohash utility.
 * Clusters GPS coordinates into ~2.2km grid cells so nearby users share the same dataset.
 */
public final class GeoGridUtils {

    private static final String BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";
    private static final double GRID_STEP = 0.02; // ~2.2 km step

    private GeoGridUtils() {}

    /**
     * Computes a shared geographic grid key for an area and radius.
     * Groups nearby coordinates (e.g., within ~2km) into the exact same key.
     */
    public static String computeGridKey(double latitude, double longitude, int radiusMeters) {
        double snappedLat = snapToGrid(latitude);
        double snappedLon = snapToGrid(longitude);
        return String.format(Locale.US, "grid_%.2f_%.2f_%d", snappedLat, snappedLon, radiusMeters);
    }

    /**
     * Computes the center latitude of the grid cell.
     */
    public static BigDecimal computeCenterLat(double latitude) {
        return BigDecimal.valueOf(snapToGrid(latitude)).setScale(7, RoundingMode.HALF_UP);
    }

    /**
     * Computes the center longitude of the grid cell.
     */
    public static BigDecimal computeCenterLon(double longitude) {
        return BigDecimal.valueOf(snapToGrid(longitude)).setScale(7, RoundingMode.HALF_UP);
    }

    private static double snapToGrid(double val) {
        return Math.round(val / GRID_STEP) * GRID_STEP;
    }

    /**
     * Encodes latitude and longitude into standard Geohash string with given precision.
     * Precision 5 = ~4.9 km x 4.9 km
     * Precision 6 = ~1.2 km x 0.6 km
     */
    public static String encodeGeohash(double latitude, double longitude, int precision) {
        double[] latInterval = {-90.0, 90.0};
        double[] lonInterval = {-180.0, 180.0};
        StringBuilder geohash = new StringBuilder();
        boolean isEven = true;
        int bit = 0;
        int ch = 0;

        while (geohash.length() < precision) {
            double mid;
            if (isEven) {
                mid = (lonInterval[0] + lonInterval[1]) / 2;
                if (longitude > mid) {
                    ch |= (1 << (4 - bit));
                    lonInterval[0] = mid;
                } else {
                    lonInterval[1] = mid;
                }
            } else {
                mid = (latInterval[0] + latInterval[1]) / 2;
                if (latitude > mid) {
                    ch |= (1 << (4 - bit));
                    latInterval[0] = mid;
                } else {
                    latInterval[1] = mid;
                }
            }

            isEven = !isEven;
            if (bit < 4) {
                bit++;
            } else {
                geohash.append(BASE32.charAt(ch));
                bit = 0;
                ch = 0;
            }
        }

        return geohash.toString();
    }
}
