package com.x10think.wave

/**
 * Conservative RFCOMM link retention policy. A new SDP connection may starve
 * an already-connected socket temporarily: a short write stall is NOT proof
 * that the original connection is broken. Packet-age/latency limits are
 * enforced independently by the per-peer writer.
 */
internal object RelayLinkPolicy {
    const val JOIN_GRACE_MS = 45_000L
    const val HEARTBEAT_IDLE_MS = 35_000L
    const val WRITE_STALL_MS = 25_000L

    fun shouldClose(nowMs: Long, lastHeardMs: Long, writingSinceMs: Long,
                    graceUntilMs: Long): Boolean {
        if (nowMs < graceUntilMs) return false
        val silentTooLong = nowMs >= lastHeardMs &&
            nowMs - lastHeardMs >= HEARTBEAT_IDLE_MS
        val writerStuck = writingSinceMs > 0L && nowMs >= writingSinceMs &&
            nowMs - writingSinceMs >= WRITE_STALL_MS
        return silentTooLong || writerStuck
    }

    /** On reconnect only the smaller unsigned stable node ID dials the other. */
    fun isReconnectOwner(localNodeId: Long, remoteNodeId: Long): Boolean =
        java.lang.Long.compareUnsigned(localNodeId, remoteNodeId) < 0
}
