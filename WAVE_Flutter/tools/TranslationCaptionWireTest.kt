package com.x10think.wave

fun main() {
    val wire = TranslationCaptionWire
    val tamil = "வணக்கம்! தமிழ் மொழிபெயர்ப்பு சரியாக வரவேண்டும். ".repeat(4)
    val parts = wire.split(tamil)
    check(parts.size > 2)
    val inbox = TranslationCaptionWire.Inbox()
    var got: TranslationCaptionWire.Caption? = null
    for (p in parts.reversed()) {
        val next = inbox.accept(11L, "ta", p.total, p.index, p.value)
        if (next != null) got = next
    }
    check(got?.text == tamil)
    check(got?.language == "ta")
    check(inbox.accept(11, "ta", parts.size, 0, parts[0].value) == null) // replay
    check(inbox.accept(12, "ta", 20, 0, parts[0].value) == null) // size bound
    check(inbox.accept(12, "fr", 1, 0, parts[0].value) == null) // unsupported language
    check(inbox.accept(12, "en", 1, 0, "#not base64#") == null)
    check(runCatching { wire.split("a".repeat(1201)) }.isFailure)
    val clean = wire.split("Hello, world!")
    check(inbox.accept(12, "en", 1, 0, clean[0].value)?.text == "Hello, world!")
    println("PASS: Unicode fragmentation, ordering, bounds, replay & integrity")
}
