package com.jamphone.socialmedia

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity(), SensorEventListener {
    private val CHANNEL = "com.jamphone.socialmedia/stepcounter"
    private val EVENT_CHANNEL = "com.jamphone.socialmedia/stepcounter/events"
    
    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private var stepCounterAvailable = false
    private var stepCount = 0
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Set up method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startStepCounter" -> {
                    val success = initSensors()
                    result.success(success)
                }
                "getCurrentSteps" -> {
                    result.success(stepCount)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Set up event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun initSensors(): Boolean {
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        
        // Try to get the step counter sensor
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        
        if (stepSensor == null) {
            // Step counter not available, try the step detector instead
            stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
            
            if (stepSensor == null) {
                // Neither sensor is available
                return false
            }
        }
        
        // Register sensor listener
        sensorManager?.registerListener(
            this,
            stepSensor,
            SensorManager.SENSOR_DELAY_NORMAL
        )
        
        stepCounterAvailable = true
        return true
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
            // Step counter returns total steps since device reboot
            stepCount = event.values[0].toInt()
            eventSink?.success(stepCount)
        } else if (event?.sensor?.type == Sensor.TYPE_STEP_DETECTOR) {
            // Step detector returns 1.0 each time a step is detected
            stepCount++
            eventSink?.success(stepCount)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used but required for SensorEventListener
    }

    override fun onPause() {
        super.onPause()
        // Unregister sensor listener when activity is paused
        if (stepCounterAvailable) {
            sensorManager?.unregisterListener(this)
        }
    }

    override fun onResume() {
        super.onResume()
        // Re-register sensor listener when activity is resumed
        if (stepCounterAvailable && stepSensor != null) {
            sensorManager?.registerListener(
                this,
                stepSensor,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }
    }
}
