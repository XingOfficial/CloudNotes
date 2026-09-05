package com.notesapp.api

import com.notesapp.model.User

data class AuthResult(
    val token: String,
    val user: User
)
