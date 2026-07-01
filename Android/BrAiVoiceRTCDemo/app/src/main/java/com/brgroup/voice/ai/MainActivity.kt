package com.brgroup.voice.ai

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.brgroup.voice.ai.event.ChatEvent
import com.brgroup.voice.ai.model.ChannelMessage
import com.brgroup.voice.ai.model.ErrorMessage
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout

class MainActivity : AppCompatActivity() {

    companion object {
        private const val PERMISSION_REQ_ID = 100
        private const val TAG = "MainActivity"


        // todo：替换为实际的ROBOT KEY和TOKEN
        private const val DEFAULT_ROBOT_KEY = <ROBOT_KEY>
        private const val DEFAULT_ROBOT_TOKEN = <ROBOT_TOKEN>
        private const val DEFAULT_USER_NAME = "android_demo_test_user"
    }

    private var chatClient: ChatClient? = null

    private lateinit var tilRobotKey: TextInputLayout
    private lateinit var tilRobotToken: TextInputLayout
    private lateinit var tilUserName: TextInputLayout
    private lateinit var etRobotKey: TextInputEditText
    private lateinit var etRobotToken: TextInputEditText
    private lateinit var etUserName: TextInputEditText

    private lateinit var tvStatus: TextView
    private lateinit var tvMessages: TextView
    private lateinit var scrollView: ScrollView
    private lateinit var btnStart: Button
    private lateinit var btnStop: Button
    private lateinit var btnInterrupt: Button
    private lateinit var btnMute: Button
    private lateinit var tvVersion: TextView

    private var isMuted = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        initViews()
        etRobotKey.setText(DEFAULT_ROBOT_KEY)
        etRobotToken.setText(DEFAULT_ROBOT_TOKEN)
        etUserName.setText(DEFAULT_USER_NAME)
    }

    private fun initViews() {
        tilRobotKey = findViewById(R.id.tilRobotKey)
        tilRobotToken = findViewById(R.id.tilRobotToken)
        tilUserName = findViewById(R.id.tilUserName)
        etRobotKey = findViewById(R.id.etRobotKey)
        etRobotToken = findViewById(R.id.etRobotToken)
        etUserName = findViewById(R.id.etUserName)

        tvStatus = findViewById(R.id.tvStatus)
        tvMessages = findViewById(R.id.tvMessages)
        scrollView = findViewById(R.id.scrollView)
        btnStart = findViewById(R.id.btnStart)
        btnStop = findViewById(R.id.btnStop)
        btnInterrupt = findViewById(R.id.btnInterrupt)
        btnMute = findViewById(R.id.btnMute)
        tvVersion = findViewById(R.id.tvVersion)

        btnStart.setOnClickListener { startChat() }
        btnStop.setOnClickListener { stopChat() }
        btnInterrupt.setOnClickListener { chatClient?.interrupt() }
        btnMute.setOnClickListener { toggleMute() }
    }

    private fun initChatClient(robotKey: String, robotToken: String, userName: String) {
        chatClient?.stopVoiceChat()
        chatClient?.removeAll()

        val client = ChatClient(
            context = this,
            robotKey = robotKey,
            robotToken = robotToken,
            userName = userName
        )
        chatClient = client

        tvVersion.text = "v${client.getSdkVersion()}"

        client.on(ChatEvent.SESSION_STARTED) { _, _ ->
            setStatus("In Call")
            setSessionButtons(true)
        }

        client.on(ChatEvent.SESSION_ENDED) { _, _ ->
            setStatus("Call Ended")
            setSessionButtons(false)
        }

        client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
            if (data is ChannelMessage) {
                appendMessage("AI: ${data.text}")
            }
        }

        client.on(ChatEvent.USER_MESSAGE) { _, data ->
            if (data is ChannelMessage) {
                appendMessage("Me: ${data.text}")
            }
        }

        client.on(ChatEvent.AUDIO_MUTED) { _, _ ->
            isMuted = true
            btnMute.text = "Unmute"
        }

        client.on(ChatEvent.AUDIO_UNMUTED) { _, _ ->
            isMuted = false
            btnMute.text = "Mute"
        }

        client.on(ChatEvent.ERROR) { _, data ->
            val msg = when (data) {
                is ErrorMessage -> "[${data.code}] ${data.errMsg}"
                else -> data?.toString() ?: "Unknown error"
            }
            setStatus("Error: $msg")
            Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
            setSessionButtons(false)

        }

        // Subscribe to all events
        client.onAny { event, data ->
            when (event) {
                ChatEvent.ERROR -> {
                    val msg = when (data) {
                        is ErrorMessage -> "[${data.code}] ${data.errMsg}"
                        else -> data?.toString() ?: "Unknown error"
                    }
                    Log.d(TAG, "Event: ERROR data=$msg")
                }

                ChatEvent.SESSION_STARTED -> Log.d(TAG, "Event: SESSION_STARTED")
                ChatEvent.SESSION_ENDED -> Log.d(TAG, "Event: SESSION_ENDED")
                ChatEvent.ROBOT_MESSAGE -> {
                    if (data is ChannelMessage) {
                        Log.d(TAG, "Event: ROBOT_MESSAGE text=${data.text}")
                    } else {
                        Log.d(TAG, "Event: ROBOT_MESSAGE data=${data?.toString()}")
                    }
                }

                ChatEvent.USER_MESSAGE -> {
                    if (data is ChannelMessage) {
                        Log.d(TAG, "Event: USER_MESSAGE text=${data.rawJson}")
                        Log.d(TAG, "Event: USER_MESSAGE text=${data.text}")
                    } else {
                        Log.d(TAG, "Event: USER_MESSAGE data=${data?.toString()}")
                    }
                }

                ChatEvent.AUDIO_MUTED -> Log.d(TAG, "Event: AUDIO_MUTED")
                ChatEvent.AUDIO_UNMUTED -> Log.d(TAG, "Event: AUDIO_UNMUTED")
                ChatEvent.ROBOT_JOINED -> Log.d(TAG, "Event: ROBOT_JOINED")
                ChatEvent.ROBOT_LEFT -> Log.d(TAG, "Event: ROBOT_LEFT")
            }
        }
    }

    private fun startChat() {
        if (!checkPermissions()) {
            requestPermissions()
            return
        }

        val robotKey = etRobotKey.text?.toString().orEmpty().trim()
        val robotToken = etRobotToken.text?.toString().orEmpty().trim()
        val userName = etUserName.text?.toString().orEmpty().trim()
        if (robotKey.isEmpty() || robotToken.isEmpty() || userName.isEmpty()) {
            Toast.makeText(this, "Robot key, token, and user name are required", Toast.LENGTH_SHORT)
                .show()
            return
        }

        initChatClient(robotKey, robotToken, userName)

        setStatus("Connecting...")
        btnStart.isEnabled = false
        tvMessages.text = ""
        chatClient!!.startVoiceChat()
    }

    private fun stopChat() {
        setStatus("Disconnecting...")
        chatClient?.stopVoiceChat()
    }

    private fun toggleMute() {
        isMuted = !isMuted
        chatClient?.setAudioEnabled(!isMuted)
    }

    private fun setStatus(status: String) {
        tvStatus.text = status
    }

    private fun setSessionButtons(active: Boolean) {
        btnStart.isEnabled = !active
        btnStop.isEnabled = active
        btnInterrupt.isEnabled = active
        btnMute.isEnabled = active
        setCredentialFieldsEnabled(!active)
        if (!active) {
            isMuted = false
            btnMute.text = "Mute"
        }
    }

    private fun setCredentialFieldsEnabled(enabled: Boolean) {
        tilRobotKey.isEnabled = enabled
        tilRobotToken.isEnabled = enabled
        tilUserName.isEnabled = enabled
    }

    private fun appendMessage(text: String) {
        tvMessages.append("$text\n")
        scrollView.post { scrollView.fullScroll(ScrollView.FOCUS_DOWN) }
    }

    private fun getRequiredPermissions(): Array<String> {
        val permissions = mutableListOf(Manifest.permission.RECORD_AUDIO)
        return permissions.toTypedArray()
    }

    private fun checkPermissions(): Boolean {
        return getRequiredPermissions().all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        ActivityCompat.requestPermissions(this, getRequiredPermissions(), PERMISSION_REQ_ID)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQ_ID && checkPermissions()) {
            setStatus("Ready")
            startChat()
        } else {
            Toast.makeText(this, "Audio permission required", Toast.LENGTH_LONG).show()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        chatClient?.stopVoiceChat()
        chatClient?.removeAll()
        chatClient = null
    }
}
