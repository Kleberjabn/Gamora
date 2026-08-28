package br.com.gamoravet.app;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.os.*;
import android.webkit.*;
import org.json.JSONObject;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {
    private WebView webView;
    private String pendingAuthUrl;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b); createNotificationChannel(); requestNotificationPermission(); captureAuthIntent(getIntent());
        webView=new WebView(this); setContentView(webView); WebSettings s=webView.getSettings(); s.setJavaScriptEnabled(true); s.setDomStorageEnabled(true); s.setAllowFileAccess(true); s.setAllowContentAccess(true); s.setDatabaseEnabled(true); s.setLoadsImagesAutomatically(true); s.setJavaScriptCanOpenWindowsAutomatically(false); s.setCacheMode(WebSettings.LOAD_NO_CACHE); webView.clearCache(true); webView.clearHistory(); webView.addJavascriptInterface(new GamoraVetBridge(this),"GamoraVetAndroid");
        webView.setWebViewClient(new WebViewClient(){@Override public void onPageFinished(WebView v,String url){super.onPageFinished(v,url);if(url!=null&&url.endsWith("index.html")){v.evaluateJavascript("(function(){var v='120';function add(src,next){var s=document.createElement('script');s.src=src+'?v='+v;s.onload=next||function(){};document.body.appendChild(s)}add('medications-enhancement.js',function(){add('medication-history-fix.js',function(){add('consultations-enhancement.js',function(){add('history-enhancement.js',function(){add('consultations-reschedule.js',function(){add('sharing-lgpd-enhancement.js',function(){add('auth-lgpd-enhancement.js',function(){add('auth-real-1.2.js',function(){window.__GAMORAVET_ENHANCED__=true})})})})})})})})})();",null);v.postDelayed(MainActivity.this::deliverPendingAuthUrl,600);}}});
        webView.setWebChromeClient(new WebChromeClient()); webView.setFocusable(true); webView.setFocusableInTouchMode(true); webView.requestFocus(); webView.loadUrl("file:///android_asset/index.html");
    }
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);captureAuthIntent(intent);if(webView!=null)webView.postDelayed(this::deliverPendingAuthUrl,300);}
    private void captureAuthIntent(Intent intent){if(intent!=null&&Intent.ACTION_VIEW.equals(intent.getAction())&&intent.getData()!=null)pendingAuthUrl=intent.getData().toString();}
    private void deliverPendingAuthUrl(){if(webView==null||pendingAuthUrl==null)return;String u=JSONObject.quote(pendingAuthUrl);pendingAuthUrl=null;webView.evaluateJavascript("window.GamoraVetAuth12&&window.GamoraVetAuth12.handleDeepLink("+u+");",null);}
    private void createNotificationChannel(){if(Build.VERSION.SDK_INT>=Build.VERSION_CODES.O){NotificationManager m=getSystemService(NotificationManager.class);NotificationChannel c=new NotificationChannel(NotificationReceiver.CHANNEL_ID,"Lembretes GamoraVet",NotificationManager.IMPORTANCE_HIGH);c.setDescription("Consultas, exames, vacinas, medicamentos e outros cuidados agendados");m.createNotificationChannel(c);}}
    private void requestNotificationPermission(){if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},1001);}

    public static class GamoraVetBridge{
        private final MainActivity a; GamoraVetBridge(MainActivity a){this.a=a;}
        @JavascriptInterface public boolean notificationsAvailable(){return Build.VERSION.SDK_INT<33||a.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED;}
        @JavascriptInterface public void scheduleNotification(int id,long ts,String title,String text){if(ts<=System.currentTimeMillis())return;Intent i=new Intent(a,NotificationReceiver.class);i.putExtra("id",id);i.putExtra("title",title);i.putExtra("text",text);PendingIntent p=PendingIntent.getBroadcast(a,id,i,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);AlarmManager am=(AlarmManager)a.getSystemService(Context.ALARM_SERVICE);boolean daily=title!=null&&title.toLowerCase().contains("medicamento");if(daily)am.setRepeating(AlarmManager.RTC_WAKEUP,ts,AlarmManager.INTERVAL_DAY,p);else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,ts,p);}
        @JavascriptInterface public void cancelNotification(int id){Intent i=new Intent(a,NotificationReceiver.class);PendingIntent p=PendingIntent.getBroadcast(a,id,i,PendingIntent.FLAG_NO_CREATE|PendingIntent.FLAG_IMMUTABLE);if(p!=null){AlarmManager am=(AlarmManager)a.getSystemService(Context.ALARM_SERVICE);am.cancel(p);p.cancel();}}
        @JavascriptInterface public void closeApp(){a.runOnUiThread(a::finish);}
        @JavascriptInterface public boolean supabaseConfigured(){return !BuildConfig.SUPABASE_URL.isEmpty()&&!BuildConfig.SUPABASE_PUBLISHABLE_KEY.isEmpty();}
        @JavascriptInterface public void authRequest(String requestId,String action,String payloadJson){new Thread(()->performAuth(requestId,action,payloadJson)).start();}
        private void performAuth(String requestId,String action,String payloadJson){int status=0;String body="";try{if(!supabaseConfigured())throw new IllegalStateException("Configuração do servidor indisponível nesta compilação.");JSONObject p=new JSONObject(payloadJson==null?"{}":payloadJson);String endpoint,method="POST";JSONObject payload=new JSONObject();if("signup".equals(action)){endpoint="/auth/v1/signup?redirect_to="+URLEncoder.encode("gamoravet://auth/callback","UTF-8");payload.put("email",p.getString("email"));payload.put("password",p.getString("password"));JSONObject data=new JSONObject();data.put("full_name",p.optString("full_name",""));data.put("role",p.optString("role","tutor"));payload.put("data",data);}else if("login".equals(action)){endpoint="/auth/v1/token?grant_type=password";payload.put("email",p.getString("email"));payload.put("password",p.getString("password"));}else if("recover".equals(action)){endpoint="/auth/v1/recover?redirect_to="+URLEncoder.encode("gamoravet://auth/callback","UTF-8");payload.put("email",p.getString("email"));}else if("refresh".equals(action)){endpoint="/auth/v1/token?grant_type=refresh_token";payload.put("refresh_token",p.getString("refresh_token"));}else if("updatePassword".equals(action)){endpoint="/auth/v1/user";method="PUT";payload.put("password",p.getString("password"));}else throw new IllegalArgumentException("Ação de autenticação inválida.");URL url=new URL(BuildConfig.SUPABASE_URL+endpoint);HttpURLConnection c=(HttpURLConnection)url.openConnection();c.setRequestMethod(method);c.setConnectTimeout(15000);c.setReadTimeout(20000);c.setDoOutput(true);c.setRequestProperty("Content-Type","application/json");c.setRequestProperty("apikey",BuildConfig.SUPABASE_PUBLISHABLE_KEY);String access=p.optString("access_token","");if(!access.isEmpty())c.setRequestProperty("Authorization","Bearer "+access);try(OutputStream os=c.getOutputStream()){os.write(payload.toString().getBytes(StandardCharsets.UTF_8));}status=c.getResponseCode();InputStream is=status>=200&&status<300?c.getInputStream():c.getErrorStream();body=readAll(is);c.disconnect();}catch(Exception e){try{body=new JSONObject().put("message",e.getMessage()==null?"Falha de comunicação.":e.getMessage()).toString();}catch(Exception ignored){body="{\"message\":\"Falha de comunicação.\"}";}}callback(requestId,status,body);}
        private String readAll(InputStream is)throws IOException{if(is==null)return "";BufferedReader r=new BufferedReader(new InputStreamReader(is,StandardCharsets.UTF_8));StringBuilder b=new StringBuilder();String line;while((line=r.readLine())!=null)b.append(line);return b.toString();}
        private void callback(String id,int status,String body){String js="window.GamoraVetAuth12&&window.GamoraVetAuth12.onNativeResult("+JSONObject.quote(id)+","+status+","+JSONObject.quote(body)+");";a.runOnUiThread(()->{if(a.webView!=null)a.webView.evaluateJavascript(js,null);});}
    }
    @Override public void onBackPressed(){if(webView!=null)webView.evaluateJavascript("if(window.gamoraBack){window.gamoraBack();}else if(window.GamoraVetAndroid){GamoraVetAndroid.closeApp();}",null);else super.onBackPressed();}
    @Override protected void onDestroy(){if(webView!=null){webView.destroy();webView=null;}super.onDestroy();}
}
