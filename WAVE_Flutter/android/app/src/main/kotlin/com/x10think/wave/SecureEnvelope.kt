package com.x10think.wave

import java.security.SecureRandom
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.util.Base64
import java.io.IOException

/** Group-PSK authenticated encryption. V6 supports both the legacy 256-bit
 * WAVE4 secret and a randomly generated 128-bit W6 compact secret, expanded
 * to an AES-256 key via SHA-256 with room/domain separation. A room ID alone
 * is never a secret. The W6 effective entropy is 128 bits, not 256 bits.
 * Every frame uses a fresh 96-bit AES-GCM nonce and room-bound AAD.
 * A group member can still impersonate another group member; this is not a PKI.
 */
internal class SecureEnvelope(secret: String, room: String) {
    private val rawSecret = try { Base64.getUrlDecoder().decode(secret) } catch (_: Exception) { byteArrayOf() }
    // V6 compact invite uses 128 bits of CSPRNG entropy; SHA-256 is a
    // domain-separated deterministic expansion, not a claim of 256-bit entropy.
    private val keyBytes = if (rawSecret.size == 16) {
        MessageDigest.getInstance("SHA-256").digest(
            "WAVE-COMPACT-KEY-V6|${room.trim().uppercase()}|".toByteArray(Charsets.UTF_8) + rawSecret)
    } else rawSecret
    private val key = SecretKeySpec(keyBytes, "AES")
    private val aad = "WAVE-SEC4|${room.trim().uppercase()}".toByteArray(Charsets.UTF_8)
    private val random = SecureRandom()
    private val seen = LinkedHashSet<String>()
    private val lock = Any()
    init { require(rawSecret.size == 16 || rawSecret.size == 32) { "Valid WAVE6 compact or WAVE4 secure invitation required" } }

    fun seal(data: ByteArray): ByteArray {
        require(data.size <= 8192) { "Packet too large" }
        val nonce = ByteArray(12).also(random::nextBytes)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(128, nonce))
        cipher.updateAAD(aad)
        return MAGIC + nonce + cipher.doFinal(data)
    }

    @Throws(IOException::class)
    fun open(encoded: ByteArray): ByteArray {
        if (encoded.size !in 33..8240 || !encoded.copyOfRange(0, 4).contentEquals(MAGIC))
            throw IOException("Incompatible or unencrypted WAVE4 frame")
        val nonce = encoded.copyOfRange(4, 16)
        val nonceId = Base64.getEncoder().encodeToString(nonce)
        synchronized(lock) { if (nonceId in seen) throw IOException("Replay packet") }
        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, nonce))
            cipher.updateAAD(aad)
            val plain = cipher.doFinal(encoded, 16, encoded.size - 16)
            synchronized(lock) {
                if (!seen.add(nonceId)) throw IOException("Replay packet")
                if (seen.size > 8192) seen.remove(seen.first())
            }
            return plain
        } catch (e: IOException) { throw e }
        catch (_: Exception) { throw IOException("Authentication failed (wrong invite or modified packet)") }
    }
    companion object {
        private val MAGIC = "WV4!".toByteArray(Charsets.US_ASCII)
        fun generateCompactInvite(): String = ByteArray(16).also(SecureRandom()::nextBytes)
            .let { Base64.getUrlEncoder().withoutPadding().encodeToString(it) }
        fun generateInvite(): String = ByteArray(32).also(SecureRandom()::nextBytes)
            .let { Base64.getUrlEncoder().withoutPadding().encodeToString(it) }
    }
}
