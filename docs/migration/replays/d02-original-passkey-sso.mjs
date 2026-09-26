// D02 原版 1.4.2 Passkey/SSO 与 API 门控 Firebase — Phase 771
// 钉住 passkey 字符串族、异常族、credentials 库与 ApiGated 初始化门。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const strings = `${base}/resources/res/values/strings.xml`;
const userDir = `${base}/sources/com/gingerlabs/notability/data/user`;
const provider = `${base}/sources/com/gingerlabs/notability/app/ApiGatedFirebaseInitProvider.java`;
const creds = `${base}/sources/androidx/credentials`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const s = fs.readFileSync(strings, 'utf8');
check('passkey sign-in strings exist (login surface)',
  s.includes('feature_login__sign_in_with_passkey')
  && s.includes('feature_login__passkey_no_credential')
  && s.includes('feature_login__passkey_unavailable'));
check('passkey management strings exist (settings surface) incl. screen-lock requirement',
  s.includes('feature_settings__add_passkey')
  && s.includes('feature_settings__passkey_no_create_option')
  && s.includes('feature_settings__passkey_already_added'));
check('SSO web client id + email sign-in retained',
  s.includes('sso_web_client_id') && s.includes('sign_in_with_email'));

check('passkey/sso exception family present',
  fs.existsSync(`${userDir}/MalformedPasskeyPayloadException.java`)
  && fs.existsSync(`${userDir}/PasskeyActivityGoneException.java`)
  && fs.existsSync(`${userDir}/SsoVerificationException.java`)
  && fs.existsSync(`${userDir}/NullAuthTokenException.java`));

check('androidx.credentials library shipped',
  fs.existsSync(creds) && fs.readdirSync(creds).length > 10);

const p = fs.readFileSync(provider, 'utf8');
check('ApiGatedFirebaseInitProvider gates super.onCreate on ib5.a',
  p.includes('extends jb5') && p.includes('ib5.a'));

console.log(`passkey/sso replay: ${checks.length}/${checks.length} checks green`);
