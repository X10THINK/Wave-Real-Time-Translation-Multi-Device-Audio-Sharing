package com.x10think.wave

import android.content.Context
import java.util.concurrent.CopyOnWriteArraySet

/** Process-scoped engine lives independently of the FlutterActivity. Foreground service owns lifetime. */
internal object MeshRuntime {
    private val observers = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()
    private var engine: MeshEngine? = null
    @Volatile private var latest: Map<String, Any?> = emptyMap()

    @Synchronized fun get(context: Context): MeshEngine {
        if (engine == null) engine = MeshEngine(context.applicationContext) { snapshot ->
            latest = snapshot
            for (observer in observers) try { observer(snapshot) } catch (_: Exception) {}
        }
        return engine!!
    }

    fun observe(observer: (Map<String, Any?>) -> Unit) {
        observers.add(observer)
        if (latest.isNotEmpty()) observer(latest)
    }
    fun unobserve(observer: (Map<String, Any?>) -> Unit) { observers.remove(observer) }
}
