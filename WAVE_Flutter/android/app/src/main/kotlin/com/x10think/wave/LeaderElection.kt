package com.x10think.wave

/** Small, conservative *fixed-view* term election for LAN recovery.
 * Host changes to the voting view require separate consensus in a full production system.
 * No quorum => no promotion. All calls are synchronized; caller authenticates messages.
 */
internal class LeaderElection(private val self: String, initialTerm: Long = 0) {
    data class Ballot(val term: Long, val voter: String, val granted: Boolean)
    private var members: Set<String> = emptySet()
    private var revision = ""
    var term: Long = initialTerm
        private set
    var leader: String = ""
        private set
    private var votedFor: String? = null
    private val votes = HashSet<String>()
    val view: String @Synchronized get() = revision
    val voters: Set<String> @Synchronized get() = members.toSet()
    val majority: Int @Synchronized get() = members.size / 2 + 1

    @Synchronized fun installView(view: String, voters: Set<String>, leaderId: String, newTerm: Long): Boolean {
        if (newTerm < term || voters.size < 3 || leaderId !in voters) return false
        if (newTerm > term) { term = newTerm; votedFor = null; votes.clear() }
        // Non-voter listeners may track/accept a majority-elected leader,
        // but initiate() and requestVote() never grant them a ballot.
        members = voters.toSet(); revision = view
        leader = leaderId
        return true
    }
    @Synchronized fun initiate(): Long? {
        if (self !in members || members.size < 3) return null
        term += 1; leader = ""; votedFor = self
        votes.clear(); votes.add(self)
        return term
    }
    @Synchronized fun requestVote(candidate: String, requestTerm: Long, remoteView: String): Ballot {
        if (requestTerm > term) { term = requestTerm; votedFor = null; votes.clear(); leader = "" }
        val allowed = requestTerm == term && remoteView == revision && candidate in members &&
            self in members && (votedFor == null || votedFor == candidate)
        if (allowed) votedFor = candidate
        return Ballot(term, self, allowed)
    }
    @Synchronized fun countVote(voter: String, voteTerm: Long, granted: Boolean, remoteView: String): Boolean {
        if (voteTerm != term || remoteView != revision || votedFor != self || voter !in members || !granted) return false
        votes.add(voter)
        if (votes.size >= majority) { leader = self; return true }
        return false
    }
    @Synchronized fun acknowledgeLeader(id: String, announcedTerm: Long, remoteView: String): Boolean {
        if (id !in members || remoteView != revision || announcedTerm < term) return false
        if (announcedTerm > term) { term = announcedTerm; votedFor = null; votes.clear() }
        leader = id
        return true
    }
}
