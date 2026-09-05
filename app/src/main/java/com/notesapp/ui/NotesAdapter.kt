package com.notesapp.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.notesapp.R
import com.notesapp.model.Note

class NotesAdapter : RecyclerView.Adapter<NotesAdapter.ViewHolder>() {
    private var allNotes: List<Note> = emptyList()
    private var filteredNotes: List<Note> = emptyList()
    private var searchQuery: String = ""
    private var clickListener: ((Note) -> Unit)? = null
    private var longClickListener: ((Note, View) -> Unit)? = null

    fun setOnNoteClickListener(listener: (Note) -> Unit) { clickListener = listener }
    fun setOnNoteLongClickListener(listener: (Note, View) -> Unit) { longClickListener = listener }

    fun setNotes(notes: List<Note>?) {
        allNotes = notes ?: emptyList()
        applyFilter()
    }

    fun setSearchQuery(query: String) {
        searchQuery = query.trim()
        applyFilter()
    }

    private fun applyFilter() {
        filteredNotes = if (searchQuery.isEmpty()) {
            allNotes
        } else {
            allNotes.filter { note ->
                note.title.contains(searchQuery, ignoreCase = true) ||
                note.content.contains(searchQuery, ignoreCase = true)
            }
        }
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_note, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val note = filteredNotes[position]
        holder.tvTitle.text = note.displayTitle
        holder.tvPreview.text = note.preview
        holder.tvDate.text = note.updatedAt
        holder.itemView.setOnClickListener { clickListener?.invoke(note) }
        holder.itemView.setOnLongClickListener { v ->
            longClickListener?.invoke(note, v)
            true
        }
    }

    override fun getItemCount(): Int = filteredNotes.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvTitle: TextView = itemView.findViewById(R.id.tvTitle)
        val tvPreview: TextView = itemView.findViewById(R.id.tvPreview)
        val tvDate: TextView = itemView.findViewById(R.id.tvDate)
    }
}
