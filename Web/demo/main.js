import { ChatClient, VoiceEvents } from '@koi-video/voice-realtime-sdk';

const LS_ROBOT_KEY = 'voice-realtime-sdk-demo:robot-key';
const LS_ROBOT_TOKEN = 'voice-realtime-sdk-demo:robot-token';

const $ = id => document.getElementById(id);

const logBox = $('logBox');
const btnStart = $('btnStart');
const btnStop = $('btnStop');
const btnMute = $('btnMute');
const btnUnmute = $('btnUnmute');
const btnInterrupt = $('btnInterrupt');
const btnClear = $('btnClear');
const sessionLine = $('sessionLine');
const sessionIdText = $('sessionIdText');
const chatMessages = $('chatMessages');
const chatStatusBadge = $('chatStatusBadge');

/** @type {ChatClient | null} */
let client = null;
/** @type {string | null} */
let sessionId = null;

function log(msg, data) {
  const line = document.createElement('div');
  line.className = 'line';
  const t = new Date().toISOString().slice(11, 23);
  const text =
    typeof data === 'undefined'
      ? msg
      : `${msg} ${JSON.stringify(data, null, 0)}`;
  line.innerHTML = `<span class="time">[${t}]</span> ${escapeHtml(text)}`;
  logBox.appendChild(line);
  logBox.scrollTop = logBox.scrollHeight;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function setRunning(running) {
  btnStart.disabled = running;
  btnStop.disabled = !running;
  btnMute.disabled = !running;
  btnUnmute.disabled = !running;
  btnInterrupt.disabled = !running;
}

function setChatBadge(text, live = false) {
  chatStatusBadge.textContent = text;
  chatStatusBadge.classList.toggle('is-live', live);
}

const bubbleElBySegment = new Map();

function segmentMapKey(role, segmentId) {
  return `${role}:${String(segmentId)}`;
}

function clearChatMessages() {
  chatMessages.innerHTML = '';
  bubbleElBySegment.clear();
}

function appendOrMergeSubtitle(role, content, segmentId) {
  const text = content == null ? '' : String(content);

  if (segmentId === undefined || segmentId === null) {
    createChatRow(role, text);
    return;
  }

  const key = segmentMapKey(role, segmentId);
  const bubbleEl = bubbleElBySegment.get(key);

  if (bubbleEl) {
    if (role === 'user') {
      bubbleEl.textContent = text;
    } else {
      const prev = bubbleEl.textContent;
      if (text.startsWith(prev) && text.length >= prev.length) {
        bubbleEl.textContent = text;
      } else {
        bubbleEl.textContent += text;
      }
    }
  } else {
    const bubble = createChatRow(role, text);
    bubbleElBySegment.set(key, bubble);
  }

  chatMessages.scrollTop = chatMessages.scrollHeight;
}

/** @returns {HTMLDivElement} */
function createChatRow(role, text) {
  const row = document.createElement('div');
  row.className = `chat-row chat-row--${role}`;

  const av = document.createElement('span');
  av.className = `chat-avatar chat-avatar--${role}`;
  av.textContent = role === 'bot' ? 'AI' : '我';

  const bubble = document.createElement('div');
  bubble.className = `chat-bubble chat-bubble--${role}`;
  bubble.textContent = text;

  if (role === 'bot') {
    row.appendChild(av);
    row.appendChild(bubble);
  } else {
    row.appendChild(bubble);
    row.appendChild(av);
  }

  chatMessages.appendChild(row);
  return bubble;
}

function appendChatSystem(text) {
  const div = document.createElement('div');
  div.className = 'chat-system';
  div.textContent = text;
  chatMessages.appendChild(div);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

/** @param {{ server?: boolean }} [opts] */
function appendChatAction(text, opts = {}) {
  const div = document.createElement('div');
  div.className = opts.server
    ? 'chat-action chat-action--server'
    : 'chat-action';
  const mark = document.createElement('span');
  mark.className = 'chat-action-mark';
  mark.textContent = opts.server ? '服务端' : '本地操作';
  const body = document.createElement('span');
  body.className = 'chat-action-body';
  body.textContent = text;
  div.appendChild(mark);
  div.appendChild(body);
  chatMessages.appendChild(div);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

function saveAuthToStorage(robotKey, robotToken) {
  try {
    localStorage.setItem(LS_ROBOT_KEY, robotKey);
    localStorage.setItem(LS_ROBOT_TOKEN, robotToken);
  } catch (e) {
    console.warn('[demo] localStorage write failed', e);
  }
}

function restoreAuthFromStorage() {
  let restored = false;
  try {
    const rk = localStorage.getItem(LS_ROBOT_KEY);
    const rt = localStorage.getItem(LS_ROBOT_TOKEN);
    if (rk) {
      $('robotKey').value = rk;
      restored = true;
    }
    if (rt) {
      $('robotToken').value = rt;
      restored = true;
    }
  } catch (e) {
    console.warn('[demo] localStorage read failed', e);
  }
  return restored;
}

function bindClientEvents() {
  if (!client) return;

  client.on(VoiceEvents.ALL, (eventName, data) => {
    log(`[ALL] ${eventName}`, data);
  });

  client.on(VoiceEvents.ERROR, data => {
    log('[ERROR]', data);
  });

  client.on(VoiceEvents.SESSION_CREATED, () => {
    setChatBadge('通话中', true);
    appendChatSystem('会话已建立，可开始说话');
  });

  client.on(VoiceEvents.SESSION_STARTED, () => {
    appendChatSystem('SESSION_STARTED（与 SESSION_CREATED 同机同载荷）');
  });

  client.on(VoiceEvents.AUDIO_MUTED, data => {
    if (data.sessionId !== sessionId) return;
    appendChatAction('AUDIO_MUTED（本地采集已静音）');
  });

  client.on(VoiceEvents.AUDIO_UNMUTED, data => {
    if (data.sessionId !== sessionId) return;
    appendChatAction('AUDIO_UNMUTED（本地采集已打开）');
  });

  client.on(VoiceEvents.USER_MESSAGE, data => {
    if (data.sessionId !== sessionId) return;
    appendOrMergeSubtitle('user', data.content, data.segmentId);
    if (data.raw) {
      log('[USER_MESSAGE] raw (full server object)', data.raw);
    }
  });

  client.on(VoiceEvents.ROBOT_MESSAGE, data => {
    if (data.sessionId !== sessionId) return;
    appendOrMergeSubtitle('bot', data.content, data.segmentId);
    if (data.raw) {
      log('[ROBOT_MESSAGE] raw (full server object)', data.raw);
    }
  });

  client.on(VoiceEvents.INTERRUPT, data => {
    if (data.sessionId !== sessionId) return;
    appendChatAction('打断已生效（来自语音流 interrupt）', { server: true });
  });

  client.on(VoiceEvents.SESSION_ENDED, data => {
    appendChatSystem(`会话结束（${data.reason || 'unknown'}）`);
    setChatBadge('未连接', false);
    sessionLine.hidden = true;
    setRunning(false);
    client = null;
    sessionId = null;
  });
}

btnClear.addEventListener('click', () => {
  logBox.innerHTML = '';
});

btnStart.addEventListener('click', async () => {
  const robotKey = $('robotKey').value.trim();
  const robotToken = $('robotToken').value.trim();
  let userNameRaw = $('userName').value.trim();

  if (!robotKey || !robotToken) {
    log('请填写 Robot-Key 与 Robot-Token');
    return;
  }
  if (!userNameRaw) {
    $('userName').value = 'demo_test';
    userNameRaw = 'demo_test';
    log('已自动生成 userName', userNameRaw);
  }

  saveAuthToStorage(robotKey, robotToken);

  try {
    client = new ChatClient(
      {
        robotKey,
        robotToken
      },
      {
        userName: userNameRaw
      }
    );
    bindClientEvents();

    clearChatMessages();
    setChatBadge('连接中…', false);

    sessionId = await client.startVoiceChat();
    sessionIdText.textContent = sessionId;
    sessionLine.hidden = false;
    setRunning(true);
    log('startVoiceChat 成功', { sessionId });
  } catch (e) {
    log('启动失败', { message: e?.message || String(e) });
    clearChatMessages();
    setChatBadge('未连接', false);
    client = null;
    sessionId = null;
    sessionLine.hidden = true;
    setRunning(false);
  }
});

btnStop.addEventListener('click', async () => {
  if (!client || !sessionId) return;
  const sid = sessionId;
  try {
    await client.stopVoiceChat();
    log('stopVoiceChat 完成', { sessionId: sid });
  } catch (e) {
    log('stopVoiceChat 异常（可能 RTC 已断）', {
      message: e?.message || String(e)
    });
  }
});

btnMute.addEventListener('click', async () => {
  if (!client || !sessionId) return;
  try {
    await client.setAudioEnabled({ bool: false });
    log('麦克风已静音');
    appendChatAction('已静音（麦克风采集已关闭）');
  } catch (e) {
    log('静音失败', { message: e?.message || String(e) });
  }
});

btnUnmute.addEventListener('click', async () => {
  if (!client || !sessionId) return;
  try {
    await client.setAudioEnabled({ bool: true });
    log('麦克风已打开');
    appendChatAction('已取消静音（麦克风采集已打开）');
  } catch (e) {
    log('取消静音失败', { message: e?.message || String(e) });
  }
});

btnInterrupt.addEventListener('click', () => {
  if (!client || !sessionId) return;
  try {
    client.interrupt();
    log('已发送 interrupt 命令');
    appendChatAction('已发送打断指令（sendStreamMessage）');
  } catch (e) {
    log('interrupt 失败', { message: e?.message || String(e) });
  }
});

const hadAuthCache = restoreAuthFromStorage();
setRunning(false);
if (hadAuthCache) {
  log('已从 localStorage 恢复 Robot-Key / Robot-Token');
}
log('就绪。填写密钥后点击「开始语音」（校验通过后会自动写入本地缓存）');
