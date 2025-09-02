import { emit } from '../../lib/sessionBus.js';

/**
 * Initialize session logger for Codex.
 * @param {{sessionId:string,source:string}} cfg
 */
export function initSessionLogger({ sessionId, source }) {
  const agent = source;
  return {
    onUserPrompt(text) {
      emit(sessionId, 'llm.message', source, {
        agent,
        role: 'user',
        text,
      });
    },
    onToken(delta) {
      emit(sessionId, 'llm.tokens', source, { agent, delta });
    },
    onAssistantDone(full) {
      emit(sessionId, 'llm.message', source, {
        agent,
        role: 'assistant',
        text: full,
      });
    },
    onToolCall(name, args) {
      emit(sessionId, 'llm.tool_call', source, { agent, name, args });
    },
  };
}
