package com.notesapp.util

import android.content.Context
import android.content.SharedPreferences
import com.notesapp.model.User
import org.json.JSONObject

class PreferencesManager(context: Context) {
    private val prefs: SharedPreferences = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun saveAuth(token: String, user: User?) {
        prefs.edit().apply {
            putString(KEY_TOKEN, token)
            user?.let { putString(KEY_USER, it.toJson().toString()) }
            apply()
        }
    }

    fun getToken(): String? = prefs.getString(KEY_TOKEN, null)

    fun getUser(): User? {
        val userStr = prefs.getString(KEY_USER, null) ?: return null
        return try {
            User.fromJson(JSONObject(userStr))
        } catch (e: Exception) {
            null
        }
    }

    fun clearAuth() {
        prefs.edit().remove(KEY_TOKEN).remove(KEY_USER).apply()
    }

    fun isLoggedIn(): Boolean = getToken() != null

    companion object {
        private const val PREFS_NAME = "notes_app_prefs"
        private const val KEY_TOKEN = "token"
        private const val KEY_USER = "user"
    }
}
