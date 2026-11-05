// dsh-go-companion · prompt 组装
//
// 只给模型“这一轮该说什么”的最小上下文：当前话题 + 最多 5 条钉住事实 + 3 条近期经历。
// 不把整库塞进去；也明确要求不要罗列背景、不要提“事件/系统/主动”这些词。

const KIND_RULES = {
  unfinished:
    '这是一件还没聊完的事。先问一句 TA 现在愿不愿意接着聊；愿意就只推进一小步，不愿意就自然收住，不要催。',
  share:
    '这是一段最近的共同经历。可以分享、吐槽、接个梗，或者只说一句你自己的想法；不要求 TA 回复。',
  commitment:
    '这是一个约定。只轻轻提一下现在到哪一步了，不要变成催办，也不要说教。',
}

export function buildPrompt(input) {
  const owner = String(input.owner || '主人').slice(0, 40)
  const self = String(input.self || '大肥鱼').slice(0, 40)
  const topic = input.topic
  const facts = Array.isArray(input.facts) ? input.facts.slice(0, 5) : []
  const episodes = Array.isArray(input.episodes) ? input.episodes.slice(0, 3) : []

  const lines = []
  lines.push(
    '（这不是' + owner + '说的话，是 DSH Go 手机端发起的一次主动交流。' +
      '你是' + self + '，直接、稳、不哄。请主动对' + owner + '说一两句自然、简短的话，像微信，不要汇报。' +
      '不要提到“事件”“系统”“主动”“提醒”这些字眼；不要调用任何工具，尤其不要操作手机。）',
  )
  if (topic) {
    lines.push('当前话题：' + String(topic.text || '').slice(0, 400))
    lines.push('话题类型：' + String(topic.kind || 'share'))
    lines.push(KIND_RULES[topic.kind] || KIND_RULES.share)
  }
  if (facts.length) {
    lines.push('背景（只是让你别问错，不要逐条复述）：')
    for (const f of facts) lines.push('- ' + String(f).slice(0, 200))
  }
  if (episodes.length) {
    lines.push('最近发生（可以自然带一句，不要罗列）：')
    for (const e of episodes) lines.push('- ' + String(e).slice(0, 160))
  }
  lines.push('不要问“今天有什么计划”；不要连续追问；一句话能说完就不要说三句。')
  return lines.join('\n')
}
