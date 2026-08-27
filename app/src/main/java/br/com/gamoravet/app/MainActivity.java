package br.com.gamoravet.app;

import android.Manifest;
import android.app.Activity;
import android.app.AlarmManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView webView;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState); createNotificationChannel(); requestNotificationPermission(); webView=new WebView(this); setContentView(webView);
        WebSettings settings=webView.getSettings(); settings.setJavaScriptEnabled(true); settings.setDomStorageEnabled(true); settings.setAllowFileAccess(true); settings.setAllowContentAccess(true); settings.setDatabaseEnabled(true); settings.setLoadsImagesAutomatically(true); settings.setJavaScriptCanOpenWindowsAutomatically(false); settings.setCacheMode(WebSettings.LOAD_NO_CACHE); webView.clearCache(true); webView.clearHistory(); webView.addJavascriptInterface(new GamoraVetBridge(this),"GamoraVetAndroid");
        webView.setWebViewClient(new WebViewClient(){@Override public void onPageFinished(WebView view,String url){super.onPageFinished(view,url);if(url!=null&&url.endsWith("index.html")){view.evaluateJavascript("(function(){var v='106';function add(src,next){var s=document.createElement('script');s.src=src+'?v='+v;s.onload=next||function(){};document.body.appendChild(s)}add('medications-enhancement.js',function(){add('medication-history-fix.js',function(){add('consultations-enhancement.js',function(){add('history-enhancement.js',function(){window.__GAMORAVET_ENHANCED__=true})})})})})();",null);}}});
        webView.setWebChromeClient(new WebChromeClient()); webView.setFocusable(true); webView.setFocusableInTouchMode(true); webView.requestFocus(); webView.loadUrl("file:///android_asset/index.html");
    }
    private void createNotificationChannel(){if(Build.VERSION.SDK_INT>=Build.VERSION_CODES.O){NotificationManager manager=getSystemService(NotificationManager.class);NotificationChannel channel=new NotificationChannel(NotificationReceiver.CHANNEL_ID,"Lembretes GamoraVet",NotificationManager.IMPORTANCE_HIGH);channel.setDescription("Consultas, exames, vacinas, medicamentos e outros cuidados agendados");manager.createNotificationChannel(channel);}}
    private void requestNotificationPermission(){if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},1001);}
    public static class GamoraVetBridge {private final Activity activity;GamoraVetBridge(Activity activity){this.activity=activity;}@JavascriptInterface public boolean notificationsAvailable(){return Build.VERSION.SDK_INT<33||activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED;}@JavascriptInterface public void scheduleNotification(int id,long timestampMs,String title,String text){if(timestampMs<=System.currentTimeMillis())return;Intent intent=new Intent(activity,NotificationReceiver.class);intent.putExtra("id",id);intent.putExtra("title",title);intent.putExtra("text",text);PendingIntent pendingIntent=PendingIntent.getBroadcast(activity,id,intent,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);AlarmManager alarmManager=(AlarmManager)activity.getSystemService(Context.ALARM_SERVICE);boolean dailyMedication=title!=null&&title.toLowerCase().contains("medicamento");if(dailyMedication)alarmManager.setRepeating(AlarmManager.RTC_WAKEUP,timestampMs,AlarmManager.INTERVAL_DAY,pendingIntent);else alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,timestampMs,pendingIntent);}@JavascriptInterface public void cancelNotification(int id){Intent intent=new Intent(activity,NotificationReceiver.class);PendingIntent pendingIntent=PendingIntent.getBroadcast(activity,id,intent,PendingIntent.FLAG_NO_CREATE|PendingIntent.FLAG_IMMUTABLE);if(pendingIntent!=null){AlarmManager alarmManager=(AlarmManager)activity.getSystemService(Context.ALARM_SERVICE);alarmManager.cancel(pendingIntent);pendingIntent.cancel();}}@JavascriptInterface public void closeApp(){activity.runOnUiThread(activity::finish);}}
    @Override public void onBackPressed(){if(webView!=null)webView.evaluateJavascript("if(window.gamoraBack){window.gamoraBack();}else if(window.GamoraVetAndroid){GamoraVetAndroid.closeApp();}",null);else super.onBackPressed();}
    @Override protected void onDestroy(){if(webView!=null){webView.destroy();webView=null;}super.onDestroy();}
}
