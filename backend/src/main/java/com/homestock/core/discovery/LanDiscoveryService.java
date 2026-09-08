package com.homestock.core.discovery;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.Enumeration;

/**
 * Lightweight Zero-Configuration LAN Discovery Service for HomeStock.
 * Listens on UDP port 8888 for mobile discovery probes ("HOMESTOCK_DISCOVER")
 * and responds with the server's active local LAN IP and HTTP port.
 * Allows mobile devices on ANY Wi-Fi network (Home, Office, Mobile Hotspot)
 * to instantly find and connect to the backend without manual IP configuration.
 */
@Service
public class LanDiscoveryService {

    private static final Logger log = LoggerFactory.getLogger(LanDiscoveryService.class);

    public static final int DISCOVERY_PORT = 8888;
    public static final String DISCOVER_REQUEST = "HOMESTOCK_DISCOVER";
    public static final String DISCOVER_RESPONSE_PREFIX = "HOMESTOCK_SERVER:";

    @Value("${server.port:8080}")
    private int serverPort;

    private DatagramSocket socket;
    private Thread listenerThread;
    private volatile boolean running = false;

    @PostConstruct
    public void start() {
        try {
            socket = new DatagramSocket(DISCOVERY_PORT, InetAddress.getByName("0.0.0.0"));
            socket.setBroadcast(true);
            running = true;

            listenerThread = new Thread(this::listenForProbes, "lan-discovery-listener");
            listenerThread.setDaemon(true);
            listenerThread.start();

            String detectedIp = getLocalIpAddress();
            log.info("[LanDiscoveryService] Active on UDP port {} (Local LAN IP: {}) — Ready for dynamic mobile auto-connect",
                    DISCOVERY_PORT, detectedIp);
        } catch (Exception e) {
            log.warn("[LanDiscoveryService] Failed to bind UDP port {} (service will continue without UDP discovery): {}",
                    DISCOVERY_PORT, e.getMessage());
        }
    }

    private void listenForProbes() {
        byte[] buffer = new byte[1024];
        while (running && socket != null && !socket.isClosed()) {
            try {
                DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
                socket.receive(packet);

                String message = new String(packet.getData(), 0, packet.getLength(), StandardCharsets.UTF_8).trim();
                if (message.contains(DISCOVER_REQUEST)) {
                    String localIp = getLocalIpAddress();
                    String responseUrl = "http://" + localIp + ":" + serverPort + "/api/v1";
                    String responsePayload = DISCOVER_RESPONSE_PREFIX + responseUrl;

                    byte[] responseBytes = responsePayload.getBytes(StandardCharsets.UTF_8);
                    DatagramPacket responsePacket = new DatagramPacket(
                            responseBytes,
                            responseBytes.length,
                            packet.getAddress(),
                            packet.getPort()
                    );
                    socket.send(responsePacket);

                    log.info("[LanDiscoveryService] Discovered by mobile client at {}:{} -> responded with {}",
                            packet.getAddress().getHostAddress(), packet.getPort(), responseUrl);
                }
            } catch (SocketException se) {
                if (!running) break;
            } catch (Exception e) {
                if (running) {
                    log.debug("[LanDiscoveryService] Error processing UDP packet: {}", e.getMessage());
                }
            }
        }
    }

    /**
     * Dynamically determines the active local IPv4 address across any network interface
     * (Home Wi-Fi, Office Wi-Fi, Mobile Hotspot, or Ethernet).
     */
    public String getLocalIpAddress() {
        try {
            // Method 1: Connected UDP socket query (inspects OS routing table for outgoing interface without sending data)
            try (DatagramSocket s = new DatagramSocket()) {
                s.connect(InetAddress.getByName("8.8.8.8"), 10002);
                String ip = s.getLocalAddress().getHostAddress();
                if (ip != null && !ip.equals("0.0.0.0") && !ip.equals("127.0.0.1")) {
                    return ip;
                }
            } catch (Exception ignored) {
                // Offline or route lookup failed, fall through to interface enumeration
            }

            // Method 2: Scan all active network interfaces for private LAN IPv4 addresses
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                NetworkInterface iface = interfaces.nextElement();
                if (iface.isLoopback() || !iface.isUp()) continue;

                Enumeration<InetAddress> addresses = iface.getInetAddresses();
                while (addresses.hasMoreElements()) {
                    InetAddress addr = addresses.nextElement();
                    if (addr instanceof Inet4Address && !addr.isLoopbackAddress()) {
                        String host = addr.getHostAddress();
                        if (host.startsWith("192.168.") || host.startsWith("172.") || host.startsWith("10.")) {
                            return host;
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("[LanDiscoveryService] Error inspecting local IP addresses: {}", e.getMessage());
        }
        return "127.0.0.1";
    }

    @PreDestroy
    public void stop() {
        running = false;
        if (socket != null && !socket.isClosed()) {
            socket.close();
        }
    }
}
