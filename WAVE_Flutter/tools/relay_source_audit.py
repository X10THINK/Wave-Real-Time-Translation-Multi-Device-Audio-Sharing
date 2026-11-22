from pathlib import Path
r=Path(__file__).resolve().parents[1]
m=(r/'android/app/src/main/kotlin/com/x10think/wave/MeshEngine.kt').read_text()
p=(r/'android/app/src/main/kotlin/com/x10think/wave/RelayLinkPolicy.kt').read_text()
checks={
 '3 independent listener slots': 'private val SLOTS = (1..3)' in m,
 'incoming peer join does not close an existing peer': 'protectExistingLinksDuringJoin()' in m and 'server.accept()' in m,
 'no 1.7s forced disconnect': 'writingSinceMs>1700L' not in m and 'p.lastHeardMs > 6500L' not in m,
 'join grace applied on both directions': m.count('protectExistingLinksDuringJoin()') >= 4,
 'one-sided deterministic redial': 'RelayLinkPolicy.isReconnectOwner(nodeId, remoteNodeId)' in m,
 'send to all verified peers except incoming': 'p !== from && p.verified.get()' in m,
 'diagnostics for disconnect reason': 'lastDisconnectReason' in m,
 'separate network sockets per peer': 'ConcurrentHashMap<String, Peer>()' in m,
 'timeout values intentionally conservative': 'HEARTBEAT_IDLE_MS = 35_000L' in p and 'WRITE_STALL_MS = 25_000L' in p,
}
for key, value in checks.items():print(('PASS' if value else 'FAIL')+' '+key)
assert all(checks.values())
