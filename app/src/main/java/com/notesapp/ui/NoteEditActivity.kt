package com.notesapp.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextUtils
import android.text.TextWatcher
import android.widget.EditText
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.notesapp.MyApplication
import com.notesapp.R
import com.notesapp.api.ApiClient
import com.notesapp.model.Note
import com.notesapp.util.PreferencesManager

class NoteEditActivity : AppCompatActivity() {
    private lateinit var etTitle: EditText
    private lateinit var etContent: EditText
    private lateinit var btnSave: TextView
    private lateinit var btnExport: TextView
    private lateinit var tvUpdated: TextView
    private lateinit var tvWordCount: TextView
    private lateinit var btnBack: ImageView
    private lateinit var apiClient: ApiClient
    private lateinit var prefs: PreferencesManager
    private var token: String? = null
    private var noteId: String? = null
    private var isEditing = false
    private var isSaving = false
    private val autoSaveHandler = Handler(Looper.getMainLooper())
    private val autoSaveRunnable = Runnable { autoSave() }
    private var contentChanged = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_note_edit)
        apiClient = MyApplication.getApiClient(this)
        prefs = PreferencesManager(this)
        token = prefs.getToken()
        initViews()
        setupListeners()
        noteId = intent.getStringExtra("note_id")
        if (!noteId.isNullOrEmpty()) {
            isEditing = true
            etTitle.setText(intent.getStringExtra("note_title"))
            etContent.setText(intent.getStringExtra("note_content"))
        }
        updateWordCount()
    }

    private fun initViews() {
        etTitle = findViewById(R.id.etTitle)
        etContent = findViewById(R.id.etContent)
        btnSave = findViewById(R.id.btnSave)
        btnExport = findViewById(R.id.btnExport)
        btnBack = findViewById(R.id.btnBack)
        tvUpdated = findViewById(R.id.tvUpdated)
        tvWordCount = findViewById(R.id.tvWordCount)
    }

    private fun setupListeners() {
        btnBack.setOnClickListener { finish() }
        btnSave.setOnClickListener { saveNote() }
        btnExport.setOnClickListener { exportNote() }
        val textWatcher = object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                contentChanged = true
                updateWordCount()
                scheduleAutoSave()
            }
            override fun afterTextChanged(s: Editable?) {}
        }
        etTitle.addTextChangedListener(textWatcher)
        etContent.addTextChangedListener(textWatcher)
    }

    private fun scheduleAutoSave() {
        autoSaveHandler.removeCallbacks(autoSaveRunnable)
        if (isEditing && !isSaving) {
            autoSaveHandler.postDelayed(autoSaveRunnable, 2000)
        }
    }

    private fun autoSave() {
        if (!contentChanged || isSaving || !isEditing) return
        val title = etTitle.text.toString().trim()
        val content = etContent.text.toString()
        if (TextUtils.isEmpty(title) && TextUtils.isEmpty(content.trim())) return
        isSaving = true
        apiClient.updateNote(token!!, noteId!!, title, content, object : ApiClient.Callback<Note> {
            override fun onSuccess(note: Note) {
                isSaving = false
                contentChanged = false
                tvUpdated.text = "已自动保存：${note.updatedAt}"
            }
            override fun onError(message: String) {
                isSaving = false
                handleAuthError(message)
            }
        })
    }

    private fun updateWordCount() {
        val titleLen = etTitle.text?.length ?: 0
        val contentLen = etContent.text?.length ?: 0
        tvWordCount.text = "${titleLen + contentLen} 字"
    }

    private fun exportNote() {
        val title = etTitle.text.toString().trim()
        val content = etContent.text.toString()
        if (TextUtils.isEmpty(title) && TextUtils.isEmpty(content.trim())) {
            Toast.makeText(this, "笔记内容为空，无法导出", Toast.LENGTH_SHORT).show()
            return
        }
        val fileName = if (title.isNotEmpty()) title else "笔记"
        val exportContent = buildString {
            if (title.isNotEmpty()) append("# ").append(title).append("\n\n")
            append(content)
        }
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, "$fileName.md")
            putExtra(Intent.EXTRA_TEXT, exportContent)
        }
        startActivity(Intent.createChooser(shareIntent, "导出笔记"))
    }

    private fun saveNote() {
        val title = etTitle.text.toString().trim()
        val content = etContent.text.toString()
        if (TextUtils.isEmpty(title) && TextUtils.isEmpty(content.trim())) {
            Toast.makeText(this, "标题和内容不能同时为空", Toast.LENGTH_SHORT).show()
            return
        }
        if (isSaving) {
            Toast.makeText(this, "正在保存中...", Toast.LENGTH_SHORT).show()
            return
        }
        isSaving = true
        btnSave.isEnabled = false
        btnSave.setText(R.string.saving)
        val callback = object : ApiClient.Callback<Note> {
            override fun onSuccess(note: Note) {
                isSaving = false
                contentChanged = false
                autoSaveHandler.removeCallbacks(autoSaveRunnable)
                Toast.makeText(this@NoteEditActivity, if (isEditing) "保存成功" else "创建成功", Toast.LENGTH_SHORT).show()
                if (!isEditing) {
                    isEditing = true
                    noteId = note.id
                    tvUpdated.text = "创建于：${note.createdAt}"
                } else {
                    tvUpdated.text = "最后更新：${note.updatedAt}"
                }
                btnSave.isEnabled = true
                btnSave.setText(R.string.save)
            }
            override fun onError(message: String) {
                isSaving = false
                btnSave.isEnabled = true
                btnSave.setText(R.string.save)
                Toast.makeText(this@NoteEditActivity, message, Toast.LENGTH_SHORT).show()
                handleAuthError(message)
            }
        }
        if (isEditing) {
            apiClient.updateNote(token!!, noteId!!, title, content, callback)
        } else {
            apiClient.createNote(token!!, title, content, callback)
        }
    }

    private fun handleAuthError(message: String) {
        if (message.contains("未登录") || message.contains("token") || message.contains("过期")) {
            prefs.clearAuth()
            finish()
        }
    }

    override fun onPause() {
        super.onPause()
        autoSaveHandler.removeCallbacks(autoSaveRunnable)
        if (contentChanged && isEditing && !isSaving) {
            autoSave()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        autoSaveHandler.removeCallbacks(autoSaveRunnable)
    }
}
