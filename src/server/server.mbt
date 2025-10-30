// async_chat.mb
// Moonbit WebSocket 聊天服务器（依赖 node ws 模块）
// 使用: npm install ws && moon build && node ./target/cmd/main/main.js

#external
type Ws
#external
type Wss
#external
type JsAny

// -------------------- extern --------------------

// 在 Node.js 控制台输出一行字符串。
extern "js" fn js_log(s: String) -> Unit =
    #|(s) => console.log(s)

// create a WebSocket.Server on port
extern "js" fn js_create_wss(port: Int) -> Wss =
    #|(p) => { const WebSocket = require('ws'); return new WebSocket.Server({ port: p }); }

// register 'connection' handler
extern "js" fn js_wss_on_connection(wss: Wss, cb: (Ws) -> Unit) -> Unit =
    #|(wss, cb) => wss.on('connection', (ws) => cb(ws))

//这里就是异步的原理 , wss 自带异步手段 , cb是一个回调函数 , 当有连接进来时 , wss会调用cb函数 , 并把ws传进去

// send raw string on a ws
extern "js" fn js_ws_send(ws: Ws, s: String) -> Unit =
    #|(ws, s) => { if (ws && ws.readyState === ws.OPEN) ws.send(s); }

//这里是发送的原理 , ws是一个连接 , 连接有一个状态 , 如果状态是打开的 , 那么就发送字符串s

// register ws.on('message', cb)
extern "js" fn js_ws_on_message(ws: Ws, cb: (String) -> Unit) -> Unit =
    #|(ws, cb) => ws.on('message', (m) => cb(String(m)))

//这里是接收消息的原理 , ws是一个连接 , 连接有一个事件 , 事件是message , 当有消息进来时 , ws会调用cb函数 , 并把消息m传进去

// register ws.on('close', cb)
extern "js" fn js_ws_on_close(ws: Ws, cb: () -> Unit) -> Unit =
    #|(ws, cb) => ws.on('close', () => cb())

// ws.ping wrapper
extern "js" fn js_ws_ping(ws: Ws) -> Unit =
    #|(ws) => { try { if (ws && ws.ping) ws.ping(() => {}); } catch(e) {} }

// broadcast
extern "js" fn js_wss_broadcast(wss: Wss, s: String) -> Unit =
    #|(wss, s) => {
    #| for (const client of wss.clients) {
    #|   try { if (client && client.readyState === client.OPEN) client.send(s); } catch(e) {}
    #| }
    #| }

// isAlive flag
extern "js" fn js_set_alive(ws: Ws, v: Bool) -> Unit =
    #|(ws, v) => { try { ws.isAlive = v; } catch(e) {} }

// get/set custom props
extern "js" fn js_set_prop(ws: Ws, key: String, val: String) -> Unit =
    #|(ws, key, val) => { try { ws[key] = val; } catch(e) {} }
extern "js" fn js_get_prop(ws: Ws, key: String) -> String =
    #|(ws, key) => { try { return String(ws[key] || ''); } catch(e) { return ''; } }

// JSON
extern "js" fn js_json_stringify(o: JsAny) -> String = #|(o) => JSON.stringify(o)
extern "js" fn js_json_parse(s: String) -> JsAny = #|(s) => JSON.parse(s)

// object helpers
extern "js" fn js_make_obj() -> JsAny = #|() => ({})
extern "js" fn js_obj_set(o: JsAny, k: String, v: String) -> Unit = #|(o,k,v)=>{ o[k] = v }
extern "js" fn js_obj_get(o: JsAny, k: String) -> String = #|(o,k)=> String(o[k] || "")

// pong
extern "js" fn js_register_pong(ws: Ws, cb: () -> Unit) -> Unit =
    #|(ws, cb) => { try { ws.on('pong', cb); } catch(e) {} }

// heartbeat
extern "js" fn js_iterate_clients_and_handle(wss: Wss) -> Unit =
    #|(wss) => {
    #|  for (const c of wss.clients) {
    #|    try {
    #|      if (c.isAlive === false) { c.terminate(); continue; }
    #|      c.isAlive = false;
    #|      if (c.ping) c.ping(() => {});
    #|    } catch(e) {}
    #|  }
    #|}

// setInterval
extern "js" fn js_set_interval(cb: () -> Unit, ms: Int) -> JsAny =
    #|(cb, ms) => setInterval(cb, ms)

// Date.now
extern "js" fn _Date_now() -> Int = #| () => Date.now()

// -------------------- helpers --------------------

fn now_ms() -> Int { return _Date_now() }

fn send_obj_to_ws(ws: Ws, obj: JsAny) -> Unit {
    let s = js_json_stringify(obj)
    js_ws_send(ws, s)
}

fn broadcast_obj(wss: Wss, obj: JsAny) -> Unit {
    let s = js_json_stringify(obj)
    js_wss_broadcast(wss, s)
}

// -------------------- server --------------------

fn start_server(port: Int) -> Unit {
    js_log("starting chat server on port " + port.to_string())
    let wss = js_create_wss(port)

    let mut next_id: Int = 1

    js_wss_on_connection(wss, fn(ws: Ws) -> Unit {
        let my_id: Int = next_id
        next_id = next_id + 1

        js_set_prop(ws, "_mb_id", my_id.to_string())
        js_set_prop(ws, "_mb_name", "User" + my_id.to_string())
        js_set_alive(ws, true)

        let welcome = js_make_obj()
        js_obj_set(welcome, "type", "welcome")
        js_obj_set(welcome, "id", my_id.to_string())
        send_obj_to_ws(ws, welcome)

        js_ws_on_message(ws, fn(msg: String) -> Unit {
            let typ = js_obj_get(js_json_parse(msg), "type")

            if (typ == "set-name") {
                let newname = js_obj_get(js_json_parse(msg), "name")
                let name = if newname == "" { "User" + my_id.to_string() } else { newname }
                js_set_prop(ws, "_mb_name", name)

                let join = js_make_obj()
                js_obj_set(join, "type", "join")
                js_obj_set(join, "id", my_id.to_string())
                js_obj_set(join, "name", name)
                js_obj_set(join, "ts", now_ms().to_string())
                broadcast_obj(wss, join)
                return
            }

            if (typ == "chat") {
                let text = js_obj_get(js_json_parse(msg), "text")
                let chat = js_make_obj()
                js_obj_set(chat, "type", "chat")
                js_obj_set(chat, "id", my_id.to_string())
                js_obj_set(chat, "name", js_get_prop(ws, "_mb_name"))
                js_obj_set(chat, "text", text)
                js_obj_set(chat, "ts", now_ms().to_string())
                broadcast_obj(wss, chat)
                return
            }
        })

        js_ws_on_close(ws, fn() -> Unit {
            let name = js_get_prop(ws, "_mb_name")
            let leave = js_make_obj()
            js_obj_set(leave, "type", "leave")
            js_obj_set(leave, "id", my_id.to_string())
            js_obj_set(leave, "name", name)
            js_obj_set(leave, "ts", now_ms().to_string())
            broadcast_obj(wss, leave)
        })

        js_register_pong(ws, fn() -> Unit { js_set_alive(ws, true) })
    })

    ignore(js_set_interval(fn() -> Unit { js_iterate_clients_and_handle(wss) }, 30000))
    js_log("server started.")
}

fn main() -> Unit {
    start_server(8080)
}