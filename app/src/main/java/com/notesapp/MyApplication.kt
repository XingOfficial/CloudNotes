package com.notesapp

import android.app.Application
import com.notesapp.api.ApiClient

class MyApplication : Application() {
    lateinit var apiClient: ApiClient
        private set

    override fun onCreate() {
        super.onCreate()
        apiClient = ApiClient()
    }

    companion object {
        fun getApiClient(context: android.content.Context): ApiClient {
            return (context.applicationContext as MyApplication).apiClient
        }
    }
}
