package com.notesapp.model

data class Note(
    var id: String = "",
    var userId: String = "",
    var title: String = "",
    var content: String = "",
    var createdAt: String = "",
    var updatedAt: String = ""
) {
    val preview: String
        get() {
            if (content.isEmpty()) return "无内容"
            val text = content.replace(Regex("\\s+"), " ").trim()
            return if (text.length > 60) text.substring(0, 60) + "…" else text
        }

    val displayTitle: String
        get() = if (title.isEmpty()) preview else title
}
