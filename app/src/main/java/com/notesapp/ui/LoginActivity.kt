package com.notesapp.ui

import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.text.TextUtils
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.notesapp.MyApplication
import com.notesapp.R
import com.notesapp.api.ApiClient
import com.notesapp.api.AuthResult
import com.notesapp.util.PreferencesManager

class LoginActivity : AppCompatActivity() {
    private lateinit var etEmail: EditText
    private lateinit var etCode: EditText
    private lateinit var etNickname: EditText
    private lateinit var btnSendCode: Button
    private lateinit var btnSubmit: Button
    private lateinit var btnTabLogin: Button
    private lateinit var btnTabRegister: Button
    private lateinit var tvError: TextView
    private lateinit var tvSwitch: TextView
    private lateinit var layoutNickname: LinearLayout
    private var isLoginMode = true
    private var countDownTimer: CountDownTimer? = null
    private lateinit var apiClient: ApiClient
    private lateinit var prefs: PreferencesManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)
        apiClient = MyApplication.getApiClient(this)
        prefs = PreferencesManager(this)
        if (prefs.isLoggedIn()) {
            startActivity(Intent(this, NotesListActivity::class.java))
            finish()
            return
        }
        initViews()
        setupListeners()
    }

    private fun initViews() {
        etEmail = findViewById(R.id.etEmail)
        etCode = findViewById(R.id.etCode)
        etNickname = findViewById(R.id.etNickname)
        btnSendCode = findViewById(R.id.btnSendCode)
        btnSubmit = findViewById(R.id.btnSubmit)
        btnTabLogin = findViewById(R.id.btnTabLogin)
        btnTabRegister = findViewById(R.id.btnTabRegister)
        tvError = findViewById(R.id.tvError)
        tvSwitch = findViewById(R.id.tvSwitch)
        layoutNickname = findViewById(R.id.layoutNickname)
    }

    private fun setupListeners() {
        btnTabLogin.setOnClickListener { switchMode(true) }
        btnTabRegister.setOnClickListener { switchMode(false) }
        tvSwitch.setOnClickListener { switchMode(!isLoginMode) }
        btnSendCode.setOnClickListener { sendCode() }
        btnSubmit.setOnClickListener { doSubmit() }
    }

    private fun switchMode(login: Boolean) {
        isLoginMode = login
        if (login) {
            btnTabLogin.setBackgroundResource(R.drawable.bg_button_primary)
            btnTabLogin.setTextColor(getColor(R.color.white))
            btnTabRegister.background = null
            btnTabRegister.setTextColor(getColor(R.color.text_secondary))
            layoutNickname.visibility = View.GONE
            btnSubmit.setText(R.string.login)
            tvSwitch.setText(R.string.no_account)
        } else {
            btnTabRegister.setBackgroundResource(R.drawable.bg_button_primary)
            btnTabRegister.setTextColor(getColor(R.color.white))
            btnTabLogin.background = null
            btnTabLogin.setTextColor(getColor(R.color.text_secondary))
            layoutNickname.visibility = View.VISIBLE
            btnSubmit.setText(R.string.register)
            tvSwitch.setText(R.string.has_account)
        }
        hideError()
    }

    private fun sendCode() {
        val email = etEmail.text.toString().trim()
        if (TextUtils.isEmpty(email) || !android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            showError("请输入有效的邮箱地址")
            return
        }
        hideError()
        btnSendCode.isEnabled = false
        btnSendCode.setText(R.string.sending)
        val purpose = if (isLoginMode) "login" else "register"
        apiClient.sendCode(email, purpose, object : ApiClient.Callback<String> {
            override fun onSuccess(data: String) {
                btnSendCode.isEnabled = true
                if (data.matches(Regex("\\d{6}"))) {
                    etCode.setText(data)
                    Toast.makeText(this@LoginActivity, "测试验证码：$data", Toast.LENGTH_LONG).show()
                } else {
                    Toast.makeText(this@LoginActivity, data, Toast.LENGTH_SHORT).show()
                }
                startCountdown()
            }
            override fun onError(message: String) {
                btnSendCode.isEnabled = true
                btnSendCode.setText(R.string.send_code)
                showError(message)
            }
        })
    }

    private fun startCountdown() {
        countDownTimer?.cancel()
        btnSendCode.isEnabled = false
        countDownTimer = object : CountDownTimer(60000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                btnSendCode.text = "${millisUntilFinished / 1000}s"
            }
            override fun onFinish() {
                btnSendCode.isEnabled = true
                btnSendCode.setText(R.string.resend_code)
            }
        }.start()
    }

    private fun doSubmit() {
        val email = etEmail.text.toString().trim()
        val code = etCode.text.toString().trim()
        val nickname = etNickname.text.toString().trim()
        if (TextUtils.isEmpty(email) || !android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            showError("请输入有效的邮箱地址")
            return
        }
        if (TextUtils.isEmpty(code) || code.length < 4) {
            showError("请输入验证码")
            return
        }
        hideError()
        btnSubmit.isEnabled = false
        btnSubmit.setText(R.string.loading)
        val purpose = if (isLoginMode) "login" else "register"
        apiClient.login(email, code, purpose, nickname, object : ApiClient.Callback<AuthResult> {
            override fun onSuccess(result: AuthResult) {
                prefs.saveAuth(result.token, result.user)
                Toast.makeText(this@LoginActivity, if (isLoginMode) "登录成功" else "注册成功", Toast.LENGTH_SHORT).show()
                startActivity(Intent(this@LoginActivity, NotesListActivity::class.java))
                finish()
            }
            override fun onError(message: String) {
                btnSubmit.isEnabled = true
                btnSubmit.setText(if (isLoginMode) R.string.login else R.string.register)
                showError(message)
            }
        })
    }

    private fun showError(msg: String) {
        tvError.text = msg
        tvError.visibility = View.VISIBLE
    }

    private fun hideError() {
        tvError.visibility = View.GONE
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }
}
