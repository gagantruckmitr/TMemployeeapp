package com.example.tmemployeeapp

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Allow screenshots - Remove FLAG_SECURE if it was set
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
