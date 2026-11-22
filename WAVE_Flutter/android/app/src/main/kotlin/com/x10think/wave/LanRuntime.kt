package com.x10think.wave
import android.content.Context
import java.util.concurrent.CopyOnWriteArraySet

internal object LanRuntime {
    private val observers=CopyOnWriteArraySet<(Map<String,Any?>)->Unit>()
    private var singleton:LanEngine?=null
    @Volatile private var latest:Map<String,Any?> = emptyMap()
    @Synchronized fun get(context:Context):LanEngine {
        if(singleton==null)singleton=LanEngine(context.applicationContext){state->
            latest=state;observers.forEach { try { it(state) } catch (_:Exception) {} }
        }
        return singleton!!
    }
    fun observe(observer:(Map<String,Any?>)->Unit){observers.add(observer);if(latest.isNotEmpty())observer(latest)}
    fun unobserve(observer:(Map<String,Any?>)->Unit){observers.remove(observer)}
}
