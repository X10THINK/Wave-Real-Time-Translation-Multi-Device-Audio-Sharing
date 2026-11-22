package com.x10think.wave

import java.io.IOException

private inline fun expectReject(block:()->Unit) {
    var rejected=false
    try{block()}catch(_:Exception){rejected=true}
    check(rejected){"Expected packet/security rejection"}
}
fun main() {
    val secret=SecureEnvelope.generateInvite()
    val a=SecureEnvelope(secret,"WAVE1234")
    val b=SecureEnvelope(secret,"WAVE1234")
    val body=MeshProtocol.audio(123L,7,2,900_000L,280,ByteArray(640){(it%127).toByte()})
    val bytes=java.io.ByteArrayOutputStream().also {
        MeshProtocol.write(java.io.DataOutputStream(it),body)
    }.toByteArray()
    val sealed=a.seal(bytes)
    check(!sealed.contentEquals(bytes))
    val decoded=MeshProtocol.read(java.io.DataInputStream(b.open(sealed).inputStream()))
    check(MeshProtocol.parseAudio(decoded.data).sequence==7)
    expectReject { b.open(sealed) } // replay cannot play twice
    val modified=sealed.copyOf().also{it[it.lastIndex] = (it.last().toInt() xor 1).toByte()}
    expectReject { SecureEnvelope(secret,"WAVE1234").open(modified) }
    expectReject { SecureEnvelope(secret,"OTHER").open(sealed) }
    expectReject { SecureEnvelope(SecureEnvelope.generateInvite(),"WAVE1234").open(sealed) }
    expectReject { SecureEnvelope("ROOM1234","WAVE1234") }
    val opus=MeshProtocol.audio(123,8,1,910_000,280,ByteArray(55){2},1)
    check(MeshProtocol.parseAudio(opus.data).codec==1)
    check(MeshProtocol.parseAudio(opus.data).pcm.size==55)
    expectReject { MeshProtocol.audio(123,9,1,910_000,280,ByteArray(5),0) }

    val ids=setOf("A","B","C")
    val aElection=LeaderElection("A")
    val bElection=LeaderElection("B")
    val cElection=LeaderElection("C")
    listOf(aElection,bElection,cElection).forEach{check(it.installView("view1",ids,"A",0))}
    val term=bElection.initiate()!!
    check(term==1L)
    // A unreachable; C grants vote. B wins 2/3, no vote from A needed.
    val vote=cElection.requestVote("B",term,"view1")
    check(vote.granted)
    check(bElection.countVote(vote.voter,vote.term,vote.granted,"view1"))
    check(bElection.leader=="B")
    // C cannot approve a competing candidate within the same term.
    check(!cElection.requestVote("A",term,"view1").granted)
    check(!bElection.countVote("A",term,true,"badView"))
    check(cElection.acknowledgeLeader("B",term,"view1"))
    val spectator=LeaderElection("listener-not-voter")
    check(spectator.installView("view1",ids,"A",0))
    check(spectator.initiate()==null) // listener cannot trigger elections
    check(!spectator.requestVote("B",term,"view1").granted)
    check(spectator.acknowledgeLeader("B",term,"view1")) // but follows winning host
    val alone=LeaderElection("D")
    check(!alone.installView("bad",setOf("D","E"),"D",0L))
    check(alone.initiate()==null)
    println("PASS WAVE4: secure AES-GCM, replay/tamper/wrong-key/room, PCM+Opus framing, election majority and split vote")
}
