/**
 * Public "join" landing page for group invite links.
 *
 * Invites share an https:// URL like /functions/v1/join?code=WV6XLYGY
 * because WhatsApp only linkifies http(s) links. This function renders a
 * small page whose "Open in Share Adi" button hands the browser off to the
 * app's custom scheme: shareadi://join?code=...
 *
 * Deploy: Supabase dashboard -> Edge Functions -> "Deploy a new function" ->
 * "Via Editor" -> name it "join" -> paste this file -> Deploy.
 * Then open the function's Settings tab and turn OFF "Enforce JWT/Verify
 * JWT" so the page can be opened from a plain browser link without a key.
 */

const renderPage = (code: string, encoded: string) => {
  const codeBox = code
    ? `<div class="code-box">${code}</div>
       <button onclick="location.href='shareadi://join?code=${encoded}'">Open in Share Adi</button>`
    : `<button id="openBtn" hidden>Open in Share Adi</button>`;
  const visibleCode = code ? code : "is missing its group code";
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Share Adi &middot; Join group</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; display: flex;
    align-items: center; justify-content: center; padding: 24px;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: #f0fffb; color: #0d352e;
  }
  .card {
    background: #ffffff; border-radius: 20px;
    box-shadow: 0 12px 40px rgba(0,0,0,0.12);
    padding: 32px 24px; max-width: 420px; width: 100%; text-align: center;
  }
  .logo {
    display: inline-flex; align-items: center; gap: 8px;
    font-weight: 800; font-size: 20px; color: #00695c; margin-bottom: 8px;
  }
  .logo .dot {
    width: 22px; height: 22px; border-radius: 50%;
    background: #00695c; color: #fff;
    display: inline-flex; align-items: center; justify-content: center;
    font-size: 12px;
  }
  h1 { font-size: 20px; margin: 12px 0 4px; }
  p.sub { color: #546e7a; font-size: 14px; margin: 0 0 20px; }
  .code-box {
    background: #e0f2f1; border-radius: 12px; padding: 12px;
    font-size: 22px; letter-spacing: 3px; font-weight: 700;
    color: #004d40; margin-bottom: 20px;
  }
  button {
    width: 100%; border: 0; border-radius: 14px; padding: 16px;
    font-size: 16px; font-weight: 700; color: #fff;
    background: #00695c; cursor: pointer; margin-bottom: 16px;
  }
  .fallback {
    border-top: 1px solid #eceff1; padding-top: 16px; text-align: left;
  }
  .fallback h3 { font-size: 14px; margin: 0 0 8px; color: #37474f; }
  .fallback ol { margin: 0; padding-left: 18px; color: #546e7a; font-size: 13px; line-height: 1.7; }
  .fallback b { color: #004d40; }
</style>
</head>
<body>
<div class="card">
  <div class="logo"><span class="dot">&rarr;</span>Share Adi</div>
  <h1>Join this group</h1>
  <p class="sub">This link opens Share Adi.</p>
  ${codeBox}
  <div class="fallback">
    <h3>Nothing happened?</h3>
    <ol>
      <li>Install <b>Share Adi</b> from the Play Store if you don't have it.</li>
      <li>Open the app and tap <b>Join a group</b>.</li>
      <li>Enter this code: <b>${visibleCode === "is missing its group code" ? "" : visibleCode}</b></li>
    </ol>
  </div>
</div>
</body>
</html>`;
};

Deno.serve((req: Request) => {
  const url = new URL(req.url);
  const code = (url.searchParams.get("code") ?? "").trim().toUpperCase();
  const encoded = encodeURIComponent(code);
  return new Response(renderPage(code, encoded), {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
    },
  });
});