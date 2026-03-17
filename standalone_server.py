#!/usr/bin/env python3
"""
standalone_server.py — single-file HTTP server for LORD v4.07 keygen

No dependencies outside the Python standard library. Drop this file into the
same folder as `lordkey.py` and run `python3 standalone_server.py`.

Usage:
  python3 standalone_server.py [port]

Default port: 8000
"""
from __future__ import annotations

import json
import html
import sys
from wsgiref.simple_server import make_server
from urllib.parse import parse_qs

from lordkey import compute_lord_keys
from counter import increment_counter

INDEX_HTML = r"""
<!doctype html>
<html lang="en">
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>LORD v4.07 Key Generator</title>
<style>
    :root{--bg:#070707;--panel:#0f0f0f;--accent:#ff1e1e;--gold:#ffcc33;--muted:#9aa4a6}
    body{background:var(--bg);color:#e8e8e8;font-family:monospace;max-width:900px;margin:28px auto;padding:24px}
    .container{background:linear-gradient(180deg,rgba(255,255,255,0.02),transparent);padding:18px;border-radius:10px;border:1px solid rgba(255,255,255,0.03)}
    h1{color:var(--gold);margin:0 0 8px 0}
    .banner{color:var(--accent);font-weight:bold;font-size:14px;line-height:1;white-space:pre;}
    form{margin:14px 0}
    input{background:#111;border:1px solid #222;color:#eee;padding:6px 8px;border-radius:4px}
    button{background:var(--accent);color:#111;border:none;padding:8px 12px;border-radius:6px;cursor:pointer}
    .out{margin-top:12px;padding:12px;background:#060606;border:1px solid #222;border-radius:6px}
    .keys{display:flex;gap:12px;flex-wrap:wrap;margin-top:8px}
    .key{background:#110000;border:1px solid rgba(255,30,30,0.15);padding:8px 12px;border-radius:6px;color:var(--gold);font-weight:700}
    .meta{color:var(--muted);font-size:13px}
</style>
<body>
    <div class="container">
        <div class="banner">
            _____   _____   _____   _____   _____
         |  _  | |  _  | |  _  | |  _  | |  _  |
         | | | | | | | | | | | | | | | | | | | |
         | |_| | | |_| | | |_| | | |_| | | |_| |
         |_____| |_____| |_____| |_____| |_____|

            LEGEND OF THE RED DRAGON — v4.07
        </div>
        <h1>LORD Key Generator</h1>
        <div class="meta">Retro BBS-themed interface — enter names and generate the five registration numbers.</div>

        <form id="form" action="/" method="POST">
            <label>Sysop Name: <input id="sysop" name="sysop" required></label>&nbsp;&nbsp;
            <label>BBS Name: <input id="bbs" name="bbs" required></label>&nbsp;&nbsp;
            <button type="submit">Generate</button>
        </form>

        <div id="out" class="out">
            <div class="meta">Output will appear here.</div>
            <div id="keys" class="keys"></div>
        </div>
    </div>

    <script>
        const form = document.getElementById('form');
        const keysEl = document.getElementById('keys');
        const outMeta = document.querySelector('#out .meta');

        function showError(msg){
            outMeta.textContent = 'Error: ' + msg;
            keysEl.innerHTML = '';
        }

        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            outMeta.textContent = 'Generating...';
            keysEl.innerHTML = '';
            const sysop = document.getElementById('sysop').value;
            const bbs = document.getElementById('bbs').value;
            try {
                const r = await fetch('/api/keys', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ sysop, bbs }),
                });
                const j = await r.json();
                if (!r.ok) return showError(j.error || 'Request failed');

                outMeta.textContent = `Sysop: ${j.sysop} · BBS: ${j.bbs}`;
                // render keys as retro boxes
                j.keys.forEach((k, i) => {
                    const div = document.createElement('div');
                    div.className = 'key';
                    div.textContent = `#${i+1}: ${k}`;
                    keysEl.appendChild(div);
                });
            } catch (err) {
                showError(err.message || err);
            }
        });
    </script>
</body>
</html>
"""

def json_resp(start_response, data, status='200 OK'):
    body = json.dumps(data, ensure_ascii=False).encode('utf-8')
    start_response(status, [
        ('Content-Type', 'application/json; charset=utf-8'),
        ('Content-Length', str(len(body))),
    ])
    return [body]

def text_resp(start_response, text, status='200 OK'):
    body = text.encode('utf-8')
    start_response(status, [
        ('Content-Type', 'text/html; charset=utf-8'),
        ('Content-Length', str(len(body))),
    ])
    return [body]


def render_html(sysop: str = '', bbs: str = '', keys=None, error: str | None = None):
        """Render the page with optional results (server-side)."""
        keys = keys or []
        esc_sysop = html.escape((sysop or '').upper())
        esc_bbs = html.escape((bbs or '').upper())
        banner = (
                "  _____   _____   _____   _____   _____\n"
                " |  _  | |  _  | |  _  | |  _  | |  _  |\n"
                " | | | | | | | | | | | | | | | | | | | |\n"
                " | |_| | | |_| | | |_| | | |_| | | |_| |\n"
                " |_____| |_____| |_____| |_____| |_____|\n\n"
                " LEGEND OF THE RED DRAGON — v4.07"
        )

        keys_html = ''.join(
                f'<div class="key">#{i}: {html.escape(str(k))}</div>' for i, k in enumerate(keys, start=1)
        )

        error_html = ''
        if error:
                error_html = '<div class="meta" style="color:#ff8d8d">' + html.escape(error) + '</div>'

        page_parts = []
        page_parts.append('<!doctype html>')
        page_parts.append('<html lang="en">')
        page_parts.append('<meta charset="utf-8" />')
        page_parts.append('<meta name="viewport" content="width=device-width,initial-scale=1" />')
        page_parts.append('<title>LORD v4.07 Key Generator</title>')
        page_parts.append('<style>')
        page_parts.append(':root{--bg:#070707;--panel:#0f0f0f;--accent:#ff1e1e;--gold:#ffcc33;--muted:#9aa4a6}')
        page_parts.append('body{background:var(--bg);color:#e8e8e8;font-family:monospace;max-width:900px;margin:28px auto;padding:24px}')
        page_parts.append('.container{background:linear-gradient(180deg,rgba(255,255,255,0.02),transparent);padding:18px;border-radius:10px;border:1px solid rgba(255,255,255,0.03)}')
        page_parts.append('h1{color:var(--gold);margin:0 0 8px 0}')
        page_parts.append('.banner{color:var(--accent);font-weight:bold;font-size:14px;line-height:1;white-space:pre;}')
        page_parts.append('form{margin:14px 0}')
        page_parts.append('input{background:#111;border:1px solid #222;color:#eee;padding:6px 8px;border-radius:4px}')
        page_parts.append('button{background:var(--accent);color:#111;border:none;padding:8px 12px;border-radius:6px;cursor:pointer}')
        page_parts.append('.out{margin-top:12px;padding:12px;background:#060606;border:1px solid #222;border-radius:6px}')
        page_parts.append('.keys{display:flex;gap:12px;flex-wrap:wrap;margin-top:8px}')
        page_parts.append('.key{background:#110000;border:1px solid rgba(255,30,30,0.15);padding:8px 12px;border-radius:6px;color:var(--gold);font-weight:700}')
        page_parts.append('.meta{color:var(--muted);font-size:13px}')
        page_parts.append('</style>')

        page_parts.append('<body>')
        page_parts.append('<div class="container">')
        page_parts.append('<div class="banner">' + html.escape(banner) + '</div>')
        page_parts.append('<h1>LORD Key Generator</h1>')
        page_parts.append('<div class="meta">Retro BBS-themed interface — enter names and generate the five registration numbers.</div>')

        page_parts.append('<form id="form" action="/" method="POST">')
        page_parts.append('<label>Sysop Name: <input id="sysop" name="sysop" value="' + esc_sysop + '" required></label>&nbsp;&nbsp;')
        page_parts.append('<label>BBS Name: <input id="bbs" name="bbs" value="' + esc_bbs + '" required></label>&nbsp;&nbsp;')
        page_parts.append('<button type="submit">Generate</button>')
        page_parts.append('</form>')

        page_parts.append('<div id="out" class="out">')
        page_parts.append(error_html)
        if esc_sysop or esc_bbs:
                page_parts.append('<div class="meta">' + 'Sysop: ' + esc_sysop + ' · BBS: ' + esc_bbs + '</div>')
        else:
                page_parts.append('<div class="meta">Output will appear here.</div>')
        page_parts.append('<div id="keys" class="keys">' + keys_html + '</div>')
        page_parts.append('</div>')
        page_parts.append('</div>')

        # client-side progressive enhancement script (keeps using /api/keys)
        page_parts.append('<script>')
        page_parts.append("const form = document.getElementById('form');")
        page_parts.append("const keysEl = document.getElementById('keys');")
        page_parts.append("const outMeta = document.querySelector('#out .meta');")
        page_parts.append('function showError(msg){ outMeta.textContent = "Error: " + msg; keysEl.innerHTML = ""; }')
        page_parts.append("form.addEventListener('submit', async (e) => { e.preventDefault(); outMeta.textContent = 'Generating...'; keysEl.innerHTML = ''; const sysop = document.getElementById('sysop').value; const bbs = document.getElementById('bbs').value; try { const r = await fetch('/api/keys', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ sysop, bbs }), }); const j = await r.json(); if (!r.ok) return showError(j.error || 'Request failed'); outMeta.textContent = `Sysop: ${j.sysop} · BBS: ${j.bbs}`; j.keys.forEach((k, i) => { const div = document.createElement('div'); div.className = 'key'; div.textContent = `#${i+1}: ${k}`; keysEl.appendChild(div); }); } catch (err) { showError(err.message || err); } });")
        page_parts.append('</script>')
        page_parts.append('</body>')
        page_parts.append('</html>')

        return '\n'.join(page_parts)

def parse_post_json(environ):
    try:
        length = int(environ.get('CONTENT_LENGTH') or 0)
    except (ValueError, TypeError):
        length = 0
    if length:
        body = environ['wsgi.input'].read(length)
        try:
            return json.loads(body.decode('utf-8'))
        except Exception:
            return {}
    return {}

def application(environ, start_response):
    path = environ.get('PATH_INFO', '')
    method = environ.get('REQUEST_METHOD', 'GET')

    # Serve UI
    if path in ('/', '/ui') and method == 'GET':
        return text_resp(start_response, INDEX_HTML)

    # Server-side form POST: render results directly into HTML (non-JS fallback)
    if path in ('/', '/ui') and method == 'POST':
        ctype = environ.get('CONTENT_TYPE', '')
        if 'application/json' in ctype:
            data = parse_post_json(environ)
            sysop = data.get('sysop', '')
            bbs = data.get('bbs', '')
        else:
            # form-encoded
            length = int(environ.get('CONTENT_LENGTH') or 0)
            body = environ['wsgi.input'].read(length) if length else b''
            params = parse_qs(body.decode('utf-8'))
            sysop = params.get('sysop', [''])[0]
            bbs = params.get('bbs', [''])[0]

        sysop = (sysop or '').strip()
        bbs = (bbs or '').strip()
        if not sysop or not bbs:
            return text_resp(start_response, render_html(sysop, bbs, keys=None, error="both 'sysop' and 'bbs' are required"), )

        try:
            k1, k2, k3, k4, k5 = compute_lord_keys(sysop, bbs)
            # private usage increment (not exposed to user)
            try:
                increment_counter()
            except Exception:
                pass
            return text_resp(start_response, render_html(sysop, bbs, keys=[k1, k2, k3, k4, k5]))
        except Exception as exc:
            return text_resp(start_response, render_html(sysop, bbs, keys=None, error=str(exc)))

    # API endpoint
    if path == '/api/keys':
        # Accept GET querystring or POST JSON/form
        if method == 'GET':
            qs = parse_qs(environ.get('QUERY_STRING', ''))
            sysop = qs.get('sysop', [''])[0]
            bbs = qs.get('bbs', [''])[0]
        else:
            ctype = environ.get('CONTENT_TYPE', '')
            if 'application/json' in ctype:
                data = parse_post_json(environ)
                sysop = data.get('sysop', '')
                bbs = data.get('bbs', '')
            else:
                # form-encoded
                length = int(environ.get('CONTENT_LENGTH') or 0)
                body = environ['wsgi.input'].read(length) if length else b''
                params = parse_qs(body.decode('utf-8'))
                sysop = params.get('sysop', [''])[0]
                bbs = params.get('bbs', [''])[0]

        sysop = (sysop or '').strip()
        bbs = (bbs or '').strip()
        if not sysop or not bbs:
            return json_resp(start_response, {'error': "both 'sysop' and 'bbs' are required"}, status='400 Bad Request')

        try:
            k1, k2, k3, k4, k5 = compute_lord_keys(sysop, bbs)
        except Exception as exc:
            return json_resp(start_response, {'error': 'internal error', 'detail': str(exc)}, status='500 Internal Server Error')

        # increment counter for API usage (private)
        try:
            increment_counter()
        except Exception:
            pass

        return json_resp(start_response, {
            'sysop': sysop.upper(),
            'bbs': bbs.upper(),
            'keys': [k1, k2, k3, k4, k5],
        })

    # not found
    return json_resp(start_response, {'error': 'not found'}, status='404 Not Found')

def main(argv):
    port = 8000
    if len(argv) > 1:
        try:
            port = int(argv[1])
        except Exception:
            pass
    host = '0.0.0.0'
    print(f'Serving on http://{host}:{port} — visit / or /ui')
    with make_server(host, port, application) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\nShutting down')

if __name__ == '__main__':
    main(sys.argv)
