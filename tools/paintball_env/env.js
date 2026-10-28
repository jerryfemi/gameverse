const {chromium}=require('playwright');const http=require('http');const fs=require('fs');const path=require('path');
const srv=http.createServer((q,s)=>{const p=path.join(__dirname,decodeURIComponent(q.url.split('?')[0]));fs.readFile(p,(e,d)=>{if(e){s.writeHead(404);return s.end()}s.writeHead(200,{'Content-Type':p.endsWith('.js')?'text/javascript':p.endsWith('.html')?'text/html':p.endsWith('.png')?'image/png':'application/octet-stream'});s.end(d)})}).listen(8133);
(async()=>{const b=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const pg=await b.newPage();pg.on('pageerror',e=>console.log('E',e.message));pg.on('console',m=>{if(m.type()=='error')console.log('C',m.text())});
await pg.goto('http://localhost:8133/env.html');await pg.waitForFunction('window.ready',null,{timeout:300000});console.log(JSON.stringify(await pg.evaluate('window.info')));
for(const p of ['Ground','Props'])fs.writeFileSync(p.toLowerCase()+'_raw.png',Buffer.from((await pg.evaluate(`pass${p}()`)).split(',')[1],'base64'));
await b.close();srv.close()})();
