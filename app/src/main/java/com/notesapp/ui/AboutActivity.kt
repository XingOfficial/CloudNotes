package com.notesapp.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.notesapp.MyApplication
import com.notesapp.R
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class AboutActivity : AppCompatActivity() {
    private lateinit var btnBack: ImageView
    private lateinit var btnStar: Button
    private lateinit var btnCheckUpdate: Button
    private lateinit var tvVersion: TextView
    private lateinit var tvUpdateStatus: TextView
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    companion object {
        private const val REPO_URL = "https://github.com/XingOfficial/CloudNotes"
        private const val RELEASE_API = "https://api.github.com/repos/XingOfficial/CloudNotes/releases/latest"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_about)
        initViews()
        setupListeners()
        tvVersion.text = "版本 ${getCurrentVersion()}"
    }

    private fun initViews() {
        btnBack = findViewById(R.id.btnBack)
        btnStar = findViewById(R.id.btnStar)
        btnCheckUpdate = findViewById(R.id.btnCheckUpdate)
        tvVersion = findViewById(R.id.tvVersion)
        tvUpdateStatus = findViewById(R.id.tvUpdateStatus)
    }

    private fun setupListeners() {
        btnBack.setOnClickListener { finish() }
        btnStar.setOnClickListener { openRepo() }
        btnCheckUpdate.setOnClickListener { checkUpdate() }
    }

    private fun openRepo() {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(REPO_URL))
            startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "无法打开浏览器", Toast.LENGTH_SHORT).show()
        }
    }

    private fun getCurrentVersion(): String {
        return try {
            packageManager.getPackageInfo(packageName, 0).versionName ?: "1.0.1"
        } catch (e: Exception) {
            "1.0.1"
        }
    }

    private fun checkUpdate() {
        btnCheckUpdate.isEnabled = false
        btnCheckUpdate.text = "检查中..."
        tvUpdateStatus.text = "正在检查更新..."

        Thread {
            try {
                val request = Request.Builder()
                    .url(RELEASE_API)
                    .header("Accept", "application/vnd.github.v3+json")
                    .build()
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        runOnUiThread {
                            btnCheckUpdate.isEnabled = true
                            btnCheckUpdate.text = "检查更新"
                            tvUpdateStatus.text = "检查失败，请稍后重试"
                        }
                        return@use
                    }
                    val body = response.body?.string() ?: ""
                    val json = JSONObject(body)
                    val tagName = json.optString("tag_name", "")
                    val releaseName = json.optString("name", tagName)
                    val releaseNotes = json.optString("body", "")
                    val htmlUrl = json.optString("html_url", REPO_URL)
                    val latestVersion = tagName.removePrefix("v")
                    val currentVersion = getCurrentVersion()

                    runOnUiThread {
                        btnCheckUpdate.isEnabled = true
                        btnCheckUpdate.text = "检查更新"
                        if (isNewerVersion(latestVersion, currentVersion)) {
                            tvUpdateStatus.text = "发现新版本：$latestVersion"
                            showUpdateDialog(releaseName, releaseNotes, htmlUrl)
                        } else {
                            tvUpdateStatus.text = "已是最新版本"
                            Toast.makeText(this, "当前已是最新版本", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            } catch (e: Exception) {
                runOnUiThread {
                    btnCheckUpdate.isEnabled = true
                    btnCheckUpdate.text = "检查更新"
                    tvUpdateStatus.text = "检查失败：${e.message}"
                }
            }
        }.start()
    }

    private fun isNewerVersion(latest: String, current: String): Boolean {
        return try {
            val latestParts = latest.split(".").map { it.toInt() }
            val currentParts = current.split(".").map { it.toInt() }
            val maxLen = maxOf(latestParts.size, currentParts.size)
            for (i in 0 until maxLen) {
                val l = latestParts.getOrElse(i) { 0 }
                val c = currentParts.getOrElse(i) { 0 }
                if (l > c) return true
                if (l < c) return false
            }
            false
        } catch (e: Exception) {
            latest != current
        }
    }

    private fun showUpdateDialog(versionName: String, notes: String, url: String) {
        val message = buildString {
            append("最新版本：$versionName\n\n")
            if (notes.isNotEmpty()) {
                append("更新说明：\n$notes")
            }
        }
        AlertDialog.Builder(this)
            .setTitle("发现新版本")
            .setMessage(message)
            .setPositiveButton("去下载") { _, _ ->
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                } catch (e: Exception) {
                    Toast.makeText(this, "无法打开浏览器", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("稍后再说", null)
            .show()
    }
}
