package com.notesapp.api

import android.os.Handler
import android.os.Looper
import com.notesapp.model.Note
import com.notesapp.model.User
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

class ApiClient {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .dns(CustomDns())
        .retryOnConnectionFailure(true)
        .build()

    interface Callback<T> {
        fun onSuccess(data: T)
        fun onError(message: String)
    }

    fun sendCode(email: String, purpose: String, callback: Callback<String>) {
        val body = JSONObject().apply {
            put("email", email)
            put("purpose", purpose)
        }.toString()
        post("send_code.php", body, null, object : RawCallback {
            override fun onSuccess(responseJson: String) {
                val msg = parseMessage(responseJson)
                postSuccess(callback, msg)
            }
            override fun onError(message: String) = postError(callback, message)
        })
    }

    fun login(email: String, code: String, purpose: String, nickname: String, callback: Callback<AuthResult>) {
        val body = JSONObject().apply {
            put("email", email)
            put("code", code)
            put("purpose", purpose)
            if (nickname.isNotEmpty()) put("nickname", nickname)
        }.toString()
        post("verify_code.php", body, null, object : RawCallback {
            override fun onSuccess(responseJson: String) {
                val result = parseAuthResult(responseJson)
                if (result != null) {
                    postSuccess(callback, result)
                } else {
                    postError(callback, "解析响应失败")
                }
            }
            override fun onError(message: String) = postError(callback, message)
        })
    }

    fun getNotes(token: String, callback: Callback<List<Note>>) {
        get("notes_list.php", token, object : RawCallback {
            override fun onSuccess(responseJson: String) {
                postSuccess(callback, parseNotesList(responseJson))
            }
            override fun onError(message: String) = postError(callback, message)
        })
    }

    fun createNote(token: String, title: String, content: String, callback: Callback<Note>) {
        val body = JSONObject().apply {
            put("title", title)
            put("content", content)
        }.toString()
        post("notes_create.php", body, token, object : RawCallback {
            override fun onSuccess(responseJson: String) {
                postSuccess(callback, parseNote(responseJson))
            }
            override fun onError(message: String) = postError(callback, message)
        })
    }

    fun updateNote(token: String, id: String, title: String, content: String, callback: Callback<Note>) {
        val body = JSONObject().apply {
            put("id", id)
            put("title", title)
            put("content", content)
        }.toString()
        post("notes_update.php", body, token, object : RawCallback {
            override fun onSuccess(responseJson: String) {
                postSuccess(callback, parseNote(responseJson))
            }
            override fun onError(message: String) = postError(callback, message)
        })
    }

    fun deleteNote(token: String, id: String, callback: Callback<Void?>) {
        val body = JSONObject().apply { put("id", id) }.toString()
        post("notes_delete.php", body, token, object : RawCallback {
            override fun onSuccess(responseJson: String) = postSuccess(callback, null)
            override fun onError(message: String) = postError(callback, message)
        })
    }

    private interface RawCallback {
        fun onSuccess(responseJson: String)
        fun onError(message: String)
    }

    private fun get(path: String, token: String?, callback: RawCallback) {
        val builder = Request.Builder().url(BASE_URL + path).get()
        token?.let { builder.header("Authorization", "Bearer $it") }
        client.newCall(builder.build()).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: Call, e: IOException) = postError(callback, friendlyError(e))
            override fun onResponse(call: Call, response: Response) = handleResponse(response, callback)
        })
    }

    private fun post(path: String, jsonBody: String, token: String?, callback: RawCallback) {
        val body = jsonBody.toRequestBody(JSON)
        val builder = Request.Builder().url(BASE_URL + path).post(body)
        token?.let { builder.header("Authorization", "Bearer $it") }
        client.newCall(builder.build()).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: Call, e: IOException) = postError(callback, friendlyError(e))
            override fun onResponse(call: Call, response: Response) = handleResponse(response, callback)
        })
    }

    private fun handleResponse(response: Response, callback: RawCallback) {
        val responseBody = response.body?.string() ?: ""
        val success = parseSuccess(responseBody)
        val message = parseMessage(responseBody)
        if (success) {
            mainHandler.post { callback.onSuccess(responseBody) }
        } else {
            postError(callback, message.ifEmpty { "请求失败（HTTP ${response.code}）" })
        }
    }

    private fun friendlyError(e: IOException): String {
        val msg = e.message ?: return "网络连接失败，请检查网络"
        return when {
            msg.contains("Unable to resolve host") || msg.contains("No address associated") ->
                "无法解析服务器域名，请检查网络连接或切换 WiFi/移动数据后重试"
            msg.contains("Failed to connect") || msg.contains("Connection refused") ->
                "无法连接到服务器，请稍后重试"
            msg.contains("timeout") || msg.contains("timed out") ->
                "连接超时，请检查网络后重试"
            msg.contains("SSL") || msg.contains("certificate") ->
                "安全连接失败，请检查系统时间是否正确"
            else -> "网络连接失败：$msg"
        }
    }

    private fun <T> postSuccess(callback: Callback<T>, data: T) { mainHandler.post { callback.onSuccess(data) } }
    private fun <T> postError(callback: Callback<T>, message: String) { mainHandler.post { callback.onError(message) } }
    private fun postError(callback: RawCallback, message: String) { mainHandler.post { callback.onError(message) } }

    companion object {
        private const val BASE_URL = "https://xingclouddisk.share.zrok.io/notes-api/"
        private val JSON = "application/json; charset=utf-8".toMediaType()

        private fun parseSuccess(json: String): Boolean = try {
            JSONObject(json).optBoolean("success", false)
        } catch (e: Exception) { false }

        private fun parseMessage(json: String): String = try {
            JSONObject(json).optString("message", "")
        } catch (e: Exception) { "" }

        private fun parseNotesList(json: String): List<Note> {
            val result = mutableListOf<Note>()
            try {
                val obj = JSONObject(json)
                val data = obj.optJSONObject("data") ?: return result
                val notes = data.optJSONArray("notes") ?: return result
                for (i in 0 until notes.length()) {
                    val n = notes.getJSONObject(i)
                    result.add(Note(
                        id = n.optString("id", ""),
                        userId = n.optString("user_id", ""),
                        title = n.optString("title", ""),
                        content = n.optString("content", ""),
                        createdAt = n.optString("created_at", ""),
                        updatedAt = n.optString("updated_at", "")
                    ))
                }
            } catch (e: Exception) { }
            return result
        }

        private fun parseNote(json: String): Note {
            return try {
                val obj = JSONObject(json)
                val data = obj.optJSONObject("data") ?: return Note()
                val n = data.optJSONObject("note") ?: return Note()
                Note(
                    id = n.optString("id", ""),
                    userId = n.optString("user_id", ""),
                    title = n.optString("title", ""),
                    content = n.optString("content", ""),
                    createdAt = n.optString("created_at", ""),
                    updatedAt = n.optString("updated_at", "")
                )
            } catch (e: Exception) { Note() }
        }

        private fun parseAuthResult(json: String): AuthResult? {
            return try {
                val obj = JSONObject(json)
                val data = obj.optJSONObject("data") ?: return null
                val userObj = data.optJSONObject("user") ?: return null
                val user = User(
                    id = userObj.optString("id", ""),
                    email = userObj.optString("email", ""),
                    nickname = userObj.optString("nickname", "")
                )
                AuthResult(token = data.optString("token", ""), user = user)
            } catch (e: Exception) { null }
        }
    }
}
