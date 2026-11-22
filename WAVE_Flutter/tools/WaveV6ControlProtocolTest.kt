package com.x10think.wave

import java.io.IOException

fun main() {
    val direct=MeshProtocol.control(42L,700L,9,1,100)
    check(direct.kind==MeshProtocol.REMOTE_CONTROL)
    val play=MeshProtocol.parseControl(direct.data)
    check(play.origin==42L && play.target==700L && play.seq==9)
    check(play.action==1 && play.gainPercent==100)
    val pause=MeshProtocol.parseControl(MeshProtocol.control(42L,700L,10,2,100).data)
    check(pause.action==2 && pause.seq==10)
    check(MeshProtocol.parseControl(MeshProtocol.control(42L,0L,12,5,100).data).action==5)
    check(MeshProtocol.parseControl(MeshProtocol.control(42L,0L,13,6,100).data).action==6)
    val volume=MeshProtocol.parseControl(MeshProtocol.control(42L,700L,11,3,35).data)
    check(volume.action==3 && volume.gainPercent==35)
    val assignment=MeshProtocol.parseControl(MeshProtocol.control(42L,700L,12,4,5).data)
    check(assignment.action==4 && assignment.gainPercent==5)
    var rejected=false
    try { MeshProtocol.control(42L,700L,13,4,100).let{MeshProtocol.parseControl(it.data)} }
    catch (_:IOException){rejected=true}
    check(rejected)
    rejected=false
    try { MeshProtocol.parseControl(byteArrayOf(0,1,2)) }
    catch (_:IOException){rejected=true}
    check(rejected)
    println("PASS V6: receiver play/pause/volume and speaker-role control framing, invalid role/length rejected")
}
