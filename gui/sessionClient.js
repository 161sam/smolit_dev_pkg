export function connectSession(sessionId, { onEvent } = {}) {
  const url = (typeof window !== 'undefined' && window.SD_WS_URL) ||
    'ws://127.0.0.1:52321';
  let socket;
  const queue = [];
  function send(msg) {
    if (socket && socket.readyState === 1) socket.send(msg);
    else queue.push(msg);
  }
  function open() {
    socket = new WebSocket(url);
    socket.onopen = () => {
      send(JSON.stringify({ op: 'subscribe', session_id: sessionId }));
      while (queue.length) socket.send(queue.shift());
    };
    socket.onmessage = (ev) => {
      let evt;
      try {
        evt = JSON.parse(typeof ev.data === 'string' ? ev.data : ev.data.toString());
      } catch {
        return;
      }
      onEvent && onEvent(evt);
    };
    socket.onclose = () => setTimeout(open, 1000);
    socket.onerror = () => {};
  }
  open();
  return {
    publish(event) {
      send(JSON.stringify({ op: 'publish', session_id: sessionId, event }));
    },
  };
}
