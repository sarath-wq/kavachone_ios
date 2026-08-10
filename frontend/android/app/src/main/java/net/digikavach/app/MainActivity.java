package net.digikavach.app;

import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.webkit.DownloadListener;
import android.webkit.URLUtil;
import android.widget.Toast;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    private BroadcastReceiver onDownloadCompleteReceiver;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        try {
            if (this.bridge != null && this.bridge.getWebView() != null) {
                // Set native Manufacturer and Model in User-Agent header
                String nativeManufacturer = Build.MANUFACTURER;
                String nativeModel = Build.MODEL;
                String currentUa = this.bridge.getWebView().getSettings().getUserAgentString();
                this.bridge.getWebView().getSettings().setUserAgentString(currentUa + " DigiKavachAppDevice/" + nativeManufacturer + "_" + nativeModel);

                // Register BroadcastReceiver to automatically open PDF report upon download completion
                onDownloadCompleteReceiver = new BroadcastReceiver() {
                    @Override
                    public void onReceive(Context context, Intent intent) {
                        try {
                            long downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1);
                            if (downloadId != -1) {
                                DownloadManager dm = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
                                if (dm != null) {
                                    Uri fileUri = dm.getUriForDownloadedFile(downloadId);
                                    String mimeType = dm.getMimeTypeForDownloadedFile(downloadId);
                                    if (fileUri != null) {
                                        Intent openIntent = new Intent(Intent.ACTION_VIEW);
                                        openIntent.setDataAndType(fileUri, mimeType != null ? mimeType : "application/pdf");
                                        openIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_GRANT_READ_URI_PERMISSION);
                                        startActivity(openIntent);
                                    }
                                }
                            }
                        } catch (Exception ex) {
                            Toast.makeText(getApplicationContext(), "PDF downloaded to Downloads folder", Toast.LENGTH_SHORT).show();
                        }
                    }
                };

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(onDownloadCompleteReceiver, new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE), Context.RECEIVER_EXPORTED);
                } else {
                    registerReceiver(onDownloadCompleteReceiver, new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));
                }

                this.bridge.getWebView().setDownloadListener(new DownloadListener() {
                    @Override
                    public void onDownloadStart(String url, String userAgent, String contentDisposition, String mimetype, long contentLength) {
                        try {
                            if (url == null || url.isEmpty()) return;

                            if (url.startsWith("blob:") || url.startsWith("data:")) {
                                Toast.makeText(getApplicationContext(), "Downloading PDF report...", Toast.LENGTH_SHORT).show();
                                return;
                            }

                            DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                            if (mimetype != null && !mimetype.isEmpty()) {
                                request.setMimeType(mimetype);
                            } else {
                                request.setMimeType("application/pdf");
                            }
                            request.addRequestHeader("User-Agent", userAgent);
                            request.setDescription("Downloading Kavach PDF Report...");
                            String fileName = URLUtil.guessFileName(url, contentDisposition, mimetype);
                            if (fileName == null || fileName.isEmpty() || !fileName.endsWith(".pdf")) {
                                fileName = "kavach_scan_report.pdf";
                            }
                            request.setTitle(fileName);
                            request.allowScanningByMediaScanner();
                            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName);
                            
                            DownloadManager dm = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
                            if (dm != null) {
                                dm.enqueue(request);
                                Toast.makeText(getApplicationContext(), "Downloading " + fileName + "...", Toast.LENGTH_SHORT).show();
                            }
                        } catch (Exception e) {
                            Toast.makeText(getApplicationContext(), "Download notice: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        }
                    }
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        try {
            if (onDownloadCompleteReceiver != null) {
                unregisterReceiver(onDownloadCompleteReceiver);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
