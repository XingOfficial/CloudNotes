package com.notesapp.ui

import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.notesapp.MyApplication
import com.notesapp.R
import com.notesapp.api.ApiClient
import com.notesapp.model.Note
import com.notesapp.util.PreferencesManager

class NotesListActivity : AppCompatActivity() {
    private lateinit var recyclerView: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var fabAdd: Button
    private lateinit var tvUser: TextView
    private lateinit var btnLogout: TextView
    private lateinit var etSearch: EditText
    private lateinit var btnSort: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var emptyLayout: View
    private lateinit var adapter: NotesAdapter
    private lateinit var apiClient: ApiClient
    private lateinit var prefs: PreferencesManager
    private var token: String? = null
    private var currentNotes: List<Note> = emptyList()
    private var sortMode = SortMode.UPDATED_DESC

    enum class SortMode(val label: String) {
        UPDATED_DESC("按更新时间（新→旧）"),
        UPDATED_ASC("按更新时间（旧→新）"),
        CREATED_DESC("按创建时间（新→旧）"),
        TITLE_ASC("按标题（A→Z）")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_notes_list)
        apiClient = MyApplication.getApiClient(this)
        prefs = PreferencesManager(this)
        token = prefs.getToken()
        if (token == null) {
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
            return
        }
        initViews()
        setupRecyclerView()
        setupListeners()
        loadNotes()
    }

    private fun initViews() {
        recyclerView = findViewById(R.id.recyclerView)
        swipeRefresh = findViewById(R.id.swipeRefresh)
        fabAdd = findViewById(R.id.fabAdd)
        tvUser = findViewById(R.id.tvUser)
        btnLogout = findViewById(R.id.btnLogout)
        etSearch = findViewById(R.id.etSearch)
        btnSort = findViewById(R.id.btnSort)
        progressBar = findViewById(R.id.progressBar)
        emptyLayout = findViewById(R.id.emptyView)
        prefs.getUser()?.let { user ->
            tvUser.text = if (user.nickname.isNotEmpty()) user.nickname else user.email
        }
    }

    private fun setupRecyclerView() {
        adapter = NotesAdapter()
        recyclerView.layoutManager = LinearLayoutManager(this)
        recyclerView.adapter = adapter
        adapter.setOnNoteClickListener { note ->
            val intent = Intent(this, NoteEditActivity::class.java).apply {
                putExtra("note_id", note.id)
                putExtra("note_title", note.title)
                putExtra("note_content", note.content)
            }
            startActivity(intent)
        }
        adapter.setOnNoteLongClickListener { note, _ -> showNoteMenu(note) }
    }

    private fun setupListeners() {
        swipeRefresh.setOnRefreshListener { loadNotes() }
        fabAdd.setOnClickListener { startActivity(Intent(this, NoteEditActivity::class.java)) }
        btnLogout.setOnClickListener { showLogoutDialog() }
        btnSort.setOnClickListener { showSortDialog() }
        etSearch.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                adapter.setSearchQuery(s?.toString() ?: "")
                updateEmptyView()
            }
            override fun afterTextChanged(s: Editable?) {}
        })
    }

    private fun showSortDialog() {
        val modes = SortMode.values()
        val labels = modes.map { it.label }.toTypedArray()
        val currentIndex = modes.indexOf(sortMode)
        AlertDialog.Builder(this)
            .setTitle("排序方式")
            .setSingleChoiceItems(labels, currentIndex) { dialog, which ->
                sortMode = modes[which]
                applySortAndFilter()
                dialog.dismiss()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun applySortAndFilter() {
        val sorted = when (sortMode) {
            SortMode.UPDATED_DESC -> currentNotes.sortedByDescending { it.updatedAt }
            SortMode.UPDATED_ASC -> currentNotes.sortedBy { it.updatedAt }
            SortMode.CREATED_DESC -> currentNotes.sortedByDescending { it.createdAt }
            SortMode.TITLE_ASC -> currentNotes.sortedBy { it.title.lowercase() }
        }
        adapter.setNotes(sorted)
        adapter.setSearchQuery(etSearch.text?.toString() ?: "")
    }

    private fun showNoteMenu(note: Note) {
        val items = arrayOf("分享", "导出", "删除")
        AlertDialog.Builder(this)
            .setTitle(note.displayTitle)
            .setItems(items) { _, which ->
                when (which) {
                    0 -> shareNote(note)
                    1 -> exportNote(note)
                    2 -> confirmDelete(note)
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun shareNote(note: Note) {
        if (note.title.isEmpty() && note.content.isEmpty()) {
            Toast.makeText(this, "笔记内容为空，无法分享", Toast.LENGTH_SHORT).show()
            return
        }
        val text = buildString {
            if (note.title.isNotEmpty()) append(note.title).append("\n\n")
            append(note.content)
        }
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, if (note.title.isNotEmpty()) note.title else "笔记分享")
            putExtra(Intent.EXTRA_TEXT, text)
        }
        startActivity(Intent.createChooser(shareIntent, "分享笔记"))
    }

    private fun exportNote(note: Note) {
        val fileName = if (note.title.isNotEmpty()) note.title else "笔记"
        val content = buildString {
            if (note.title.isNotEmpty()) append("# ").append(note.title).append("\n\n")
            append(note.content)
            append("\n\n---\n创建于：").append(note.createdAt)
            append("\n更新于：").append(note.updatedAt)
        }
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, "$fileName.md")
            putExtra(Intent.EXTRA_TEXT, content)
        }
        startActivity(Intent.createChooser(shareIntent, "导出笔记"))
    }

    private fun confirmDelete(note: Note) {
        AlertDialog.Builder(this)
            .setTitle("删除笔记")
            .setMessage(R.string.confirm_delete)
            .setPositiveButton(R.string.delete) { _, _ -> deleteNote(note) }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun deleteNote(note: Note) {
        apiClient.deleteNote(token!!, note.id, object : ApiClient.Callback<Void?> {
            override fun onSuccess(data: Void?) {
                Toast.makeText(this@NotesListActivity, "删除成功", Toast.LENGTH_SHORT).show()
                loadNotes()
            }
            override fun onError(message: String) {
                Toast.makeText(this@NotesListActivity, message, Toast.LENGTH_SHORT).show()
                handleAuthError(message)
            }
        })
    }

    private fun loadNotes() {
        if (!swipeRefresh.isRefreshing) progressBar.visibility = View.VISIBLE
        emptyLayout.visibility = View.GONE
        apiClient.getNotes(token!!, object : ApiClient.Callback<List<Note>> {
            override fun onSuccess(notes: List<Note>) {
                progressBar.visibility = View.GONE
                swipeRefresh.isRefreshing = false
                currentNotes = notes
                applySortAndFilter()
                updateEmptyView()
            }
            override fun onError(message: String) {
                progressBar.visibility = View.GONE
                swipeRefresh.isRefreshing = false
                Toast.makeText(this@NotesListActivity, message, Toast.LENGTH_SHORT).show()
                handleAuthError(message)
            }
        })
    }

    private fun updateEmptyView() {
        val query = etSearch.text?.toString()?.trim() ?: ""
        val isEmpty = if (query.isEmpty()) {
            currentNotes.isEmpty()
        } else {
            adapter.itemCount == 0
        }
        emptyLayout.visibility = if (isEmpty) View.VISIBLE else View.GONE
        val emptyText = emptyLayout.findViewById<TextView>(R.id.emptyText)
        if (query.isNotEmpty() && adapter.itemCount == 0) {
            emptyText?.text = "没有找到包含「$query」的笔记"
        } else {
            emptyText?.setText(R.string.empty_notes)
        }
    }

    private fun handleAuthError(message: String) {
        if (message.contains("未登录") || message.contains("token") || message.contains("过期")) {
            prefs.clearAuth()
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
        }
    }

    private fun showLogoutDialog() {
        AlertDialog.Builder(this)
            .setTitle("退出登录")
            .setMessage("确定要退出登录吗？")
            .setPositiveButton("确定") { _, _ ->
                prefs.clearAuth()
                startActivity(Intent(this, LoginActivity::class.java))
                finish()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    override fun onResume() {
        super.onResume()
        if (token != null) loadNotes()
    }
}
