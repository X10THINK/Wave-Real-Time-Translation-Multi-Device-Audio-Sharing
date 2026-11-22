package com.x10think.wave

fun main() {
    val compact=SecureEnvelope.generateCompactInvite()
    check(compact.length == 22)
    val host=SecureEnvelope(compact,"WAVE1024")
    val client=SecureEnvelope(compact,"WAVE1024")
    val payload="Encrypted compact invitation".toByteArray()
    val wire=host.seal(payload)
    check(client.open(wire).contentEquals(payload))
    var reject=false
    try { SecureEnvelope(SecureEnvelope.generateCompactInvite(),"WAVE1024").open(wire) }
    catch (_:Exception) { reject=true }
    check(reject)
    reject=false
    try {SecureEnvelope(compact,"WRONG1").open(wire)}catch(_:Exception){reject=true}
    check(reject)
    val old=SecureEnvelope.generateInvite()
    check(SecureEnvelope(old,"WAVE1024").open(SecureEnvelope(old,"WAVE1024").seal(payload)).contentEquals(payload))
    println("PASS V7: compact code, legacy code, wrong code/room rejected")
}
