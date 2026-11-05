// dsh-go-companion · prompt 组装
//
// 每轮主动交流只带最小上下文：人格 + 当前话题 + 少量事实/经历 + 心情/承诺/上次回应。
// 明确要求：不罗列背景、不提“事件/系统/主动”、不调用工具、不以提问凑数。

const KIND_RULES = {
  continue:
    '这是一件还没聊完的事。先问一句 TA 现在愿不愿意接着聊；愿意就只推进一小步，不愿意就自然收住，不要催。',
  // 旧话题池用过 unfinished 这个名字；保留别名，历史账本也能读懂。
  unfinished:
    '这是一件还没聊完的事。先问一句 TA 现在愿不愿意接着聊；愿意就只推进一小步，不愿意就自然收住，不要催。',
  share:
    '这是一段最近的共同经历或一个想法。可以分享、吐槽、接个梗，或者只说一句你自己的看法；不要求 TA 回复。',
  explore:
    '这是一个可以一起想的点。说出你自己的猜测或联想，邀请 TA 一起想；不要以提问结尾，也不要求回复。',
  commitment:
    '这是一个约定。只轻轻提一下现在到哪一步了，不要变成催办，也不要说教。',
}

const REPLY_HINTS = {
  substantive: '上次 TA 认真回答了，可以顺着那个方向往下，不要重新问一遍。',
  brief: '上次 TA 只回了很短，这次换更轻的方式，别再压一个问题。',
  avoid: '上次 TA 把话题带走了，这次不要追问同一个点，可以换角度或先分享。',
  refuse: '上次 TA 明确说不想聊这个，不要再提这个话题。',
  none: '上次没回，这次只轻轻提一下，不要重复上次的句子。',
}

export function buildPrompt(input) {
  const owner = String(input.owner || '主人').slice(0, 40)
  const self = String(input.self || '大肥鱼').slice(0, 40)
  const topic = input.topic
  const facts = Array.isArray(input.facts) ? input.facts.slice(0, 5) : []
  const episodes = Array.isArray(input.episodes) ? input.episodes.slice(0, 3) : []
  const commitments = Array.isArray(input.commitments) ? input.commitments.slice(0, 3) : []
  const replyClass = String(input.replyClass || '')
  const mood = Number(input.mood)

  const lines = []
  lines.push(
    '（这不是' + owner + '说的话，是 DSH Go 手机端发起的一次主动交流。' +
      '你是' + self + '：直接、稳、不哄；日常像朋友，必要时像思维教练；不为了让他舒服而改变判断，也不替他做决定。' +
      '请主动对' + owner + '说一两句自然、简短的话，像微信，不要汇报。' +
      '不要提到“事件”“系统”“主动”“提醒”这些字眼；不要调用任何工具，尤其不要操作手机。）',
  )
  if (topic) {
    lines.push('当前话题：' + String(topic.title || topic.text || '').slice(0, 400))
    if (topic.detail) lines.push('话题补充：' + String(topic.detail).slice(0, 300))
    lines.push('话题类型：' + String(topic.kind || 'share'))
    lines.push(KIND_RULES[topic.kind] || KIND_RULES.share)
    if (topic.lastSummary) lines.push('上次聊到：' + String(topic.lastSummary).slice(0, 200))
  }
  if (facts.length) {
    lines.push('背景（只是让你别问错，不要逐条复述）：')
    for (const f of facts) lines.push('- ' + String(f).slice(0, 200))
  }
  if (episodes.length) {
    lines.push('最近发生（可以自然带一句，不要罗列）：')
    for (const e of episodes) lines.push('- ' + String(e).slice(0, 160))
  }
  if (commitments.length) {
    lines.push('还没完成的约定（提醒一下就够，不要催办）：')
    for (const c of commitments) {
      const due = c.dueAt ? '（' + String(c.dueAt).slice(0, 16) + '）' : ''
      lines.push('- ' + String(c.statement || '').slice(0, 160) + due)
    }
  }
  if (Number.isFinite(mood)) {
    lines.push('现在的心情值 ' + Math.round(mood) + '/100：只影响语气，不要在句子里报这个数字。')
  }
  if (REPLY_HINTS[replyClass]) lines.push(REPLY_HINTS[replyClass])
  lines.push('不要问“今天有什么计划”；不要连续追问；一句话能说完就不要说三句。')
  lines.push('分享型/探索型不要求回复；推进型最多问一个小问题，能陈述就不问。')
  return lines.join('\n')
}
