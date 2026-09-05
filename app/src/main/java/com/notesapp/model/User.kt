package com.notesapp.model

import org.json.JSONObject

data class User(
    var id: String = "",
    var email: String = "",
    var nickname: String = ""
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("email", email)
        put("nickname", nickname)
    }

    companion object {
        fun fromJson(obj: JSONObject): User = User(
            id = obj.optString("id", ""),
            email = obj.optString("email", ""),
            nickname = obj.optString("nickname", "")
        )
    }
}
