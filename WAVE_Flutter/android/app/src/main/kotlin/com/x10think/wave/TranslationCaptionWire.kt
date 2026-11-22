package com.x10think.wave

import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets
import java.util.Base64

/** Bounded, binary-safe caption fragmentation. The WAVE room transport supplies
 * authenticated encryption and checks the verified Host link before accepting
 * chunks. This class does NOT authenticate the sender itself. */
internal object TranslationCaptionWire {
    const val MAX_BYTES = 1200
    private const val PART_BYTES = 90
    private const val MAX_PARTS = 14

    data class Piece(val index: Int, val total: Int, val value: String)
    data class Caption(val sequence: Long, val language: String, val text: String)

    fun split(text: String): List<Piece> {
        val bytes = text.toByteArray(StandardCharsets.UTF_8)
        require(bytes.isNotEmpty() && bytes.size <= MAX_BYTES) { "Caption must be 1..1200 UTF-8 bytes" }
        val parts = bytes.toList().chunked(PART_BYTES)
        require(parts.size in 1..MAX_PARTS)
        return parts.mapIndexed { index, chunk ->
            Piece(index, parts.size, Base64.getEncoder().encodeToString(chunk.toByteArray()))
        }
    }

    /** One assembly per sequence, rejecting stale/replayed captions and duplicates.
     * A bounded cache prevents a hostile authenticated room participant exhausting memory. */
    class Inbox {
        private data class Pending(val language: String, val total: Int,
                                   val received: MutableMap<Int, ByteArray> = HashMap())
        private val pending = LinkedHashMap<Long, Pending>()
        private var lastDelivered = 0L
        @Synchronized fun clear() { pending.clear(); lastDelivered = 0L }
        @Synchronized fun accept(sequence: Long, language: String, total: Int,
                                 index: Int, encoded: String): Caption? {
            if (sequence <= lastDelivered || sequence < 1L ||
                language !in setOf("ta", "en") ||
                total !in 1..MAX_PARTS || index !in 0 until total ||
                encoded.length !in 4..128) return null
            val bytes = try { Base64.getDecoder().decode(encoded) } catch (_: IllegalArgumentException) { return null }
            if (bytes.isEmpty() || bytes.size > PART_BYTES) return null
            val assembly = pending.getOrPut(sequence) { Pending(language, total) }
            if (assembly.language != language || assembly.total != total) {
                pending.remove(sequence); return null
            }
            if (assembly.received.putIfAbsent(index, bytes) != null) return null
            while (pending.size > 4) pending.remove(pending.keys.first())
            if (assembly.received.size != total) return null
            val output = ByteArrayOutputStream()
            for (part in 0 until total) output.write(assembly.received[part] ?: return null)
            pending.remove(sequence)
            if (output.size() !in 1..MAX_BYTES) return null
            val value = try {
                StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(output.toByteArray())).toString()
            } catch (_: Exception) { return null }
            if (value.isBlank()) return null
            lastDelivered = sequence
            pending.keys.removeAll { it <= sequence }
            return Caption(sequence, language, value)
        }
    }
}
