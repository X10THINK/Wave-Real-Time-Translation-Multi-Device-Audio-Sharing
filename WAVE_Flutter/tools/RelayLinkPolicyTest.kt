package com.x10think.wave

fun main() {
    val p=RelayLinkPolicy
    check(!p.shouldClose(8000L,0L,6300L,0L)) // old 1.7s false-positive
    check(!p.shouldClose(14000L,0L,11000L,45_000L)) // D joins B
    check(!p.shouldClose(44_999L,0L,4000L,45_000L))
    check(p.shouldClose(45_001L,0L,0L,45_000L))
    check(p.shouldClose(35_000L,0L,0L,0L))
    check(p.shouldClose(28_000L,23_000L,2000L,0L)) // writer >25s
    check(!p.shouldClose(20_000L,12_000L,16_000L,0L))
    check(p.isReconnectOwner(1L,2L))
    check(!p.isReconnectOwner(2L,1L))
    check(p.isReconnectOwner(1L,-1L)) // unsigned compare
    check(!p.isReconnectOwner(-1L,1L))
    println("PASS RelayLinkPolicy: grace, active socket retention, prolonged-stall recovery, asymmetric reconnect")
}
