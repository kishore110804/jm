package com.jamphone.socialmedia;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class StepCounterPlugin implements FlutterPlugin, MethodCallHandler, SensorEventListener {
    private static final String TAG = "StepCounterPlugin";
    private static final String CHANNEL = "com.jamphone.socialmedia/step_counter";

    private MethodChannel channel;
    private Context context;
    private SensorManager sensorManager;
    private Sensor stepCounterSensor;
    private Sensor stepDetectorSensor;
    private int stepCount = 0;
    private int initialStepCount = -1;
    private boolean isTracking = false;

    public static void registerWith(FlutterEngine flutterEngine, Context context) {
        StepCounterPlugin instance = new StepCounterPlugin();
        instance.context = context;
        instance.setupChannel(flutterEngine);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    private void setupChannel(FlutterEngine flutterEngine) {
        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "startTracking":
                startStepTracking();
                result.success(null);
                break;
            case "stopTracking":
                stopStepTracking();
                result.success(null);
                break;
            case "getStepCount":
                result.success(stepCount);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void startStepTracking() {
        if (isTracking) {
            return;
        }

        sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        if (sensorManager == null) {
            Log.e(TAG, "SensorManager is null");
            return;
        }

        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER);
        if (stepCounterSensor != null) {
            sensorManager.registerListener(this, stepCounterSensor, SensorManager.SENSOR_DELAY_NORMAL);
            Log.i(TAG, "Step counter sensor registered");
        } else {
            Log.w(TAG, "Step counter sensor not available");
        }

        stepDetectorSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR);
        if (stepDetectorSensor != null) {
            sensorManager.registerListener(this, stepDetectorSensor, SensorManager.SENSOR_DELAY_NORMAL);
            Log.i(TAG, "Step detector sensor registered");
        } else {
            Log.w(TAG, "Step detector sensor not available");
        }

        isTracking = true;
    }

    private void stopStepTracking() {
        if (!isTracking) {
            return;
        }

        if (sensorManager != null) {
            sensorManager.unregisterListener(this);
            isTracking = false;
            Log.i(TAG, "Step tracking stopped");
        }
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_STEP_COUNTER) {
            int steps = (int) event.values[0];
            
            if (initialStepCount < 0) {
                initialStepCount = steps;
                stepCount = 0;
            } else {
                stepCount = steps - initialStepCount;
            }
            
            if (channel != null) {
                channel.invokeMethod("onStepUpdate", stepCount);
            }
            
            Log.d(TAG, "Step count: " + stepCount);
        } else if (event.sensor.getType() == Sensor.TYPE_STEP_DETECTOR) {
            // This sensor only triggers when a step is detected
            stepCount++;
            
            if (channel != null) {
                channel.invokeMethod("onStepUpdate", stepCount);
            }
            
            Log.d(TAG, "Step detected, count: " + stepCount);
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // Not needed
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        stopStepTracking();
        channel.setMethodCallHandler(null);
        channel = null;
    }
}
