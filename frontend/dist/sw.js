/*
 DigiKavach Service Worker & IndexedDB Background Sync Engine
 =============================================================
 Fixes BUGWA-102: Service Worker IndexedDB background sync fails to retry
 queued reports if payload exceeds 10MB.
 Features:
 1. IndexedDB Offline Report Queue (DigiKavachOfflineDB).
 2. Large Payload Chunking: Automatically splits payloads > 10MB into 2MB chunks.
 3. Automatic Retry Loop & Status Management.
*/

const CACHE_NAME = 'digikavach-v2.4.0';
const DB_NAME = 'DigiKavachOfflineDB';
const DB_VERSION = 1;
const MAX_PAYLOAD_SIZE = 10 * 1024 * 1024; // 10MB
const CHUNK_SIZE = 2 * 1024 * 1024; // 2MB

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Helper: Open IndexedDB Database
function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains('offline_reports')) {
        const store = db.createObjectStore('offline_reports', { keyPath: 'id', autoIncrement: true });
        store.createIndex('status', 'status', { unique: false });
        store.createIndex('createdAt', 'createdAt', { unique: false });
      }
      if (!db.objectStoreNames.contains('report_chunks')) {
        const chunkStore = db.createObjectStore('report_chunks', { keyPath: 'chunkId' });
        chunkStore.createIndex('reportId', 'reportId', { unique: false });
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

// Background Sync Listener
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-offline-reports') {
    event.waitUntil(processOfflineQueue());
  }
});

async function processOfflineQueue() {
  const db = await openDB();
  const tx = db.transaction('offline_reports', 'readwrite');
  const store = tx.objectStore('offline_reports');
  const request = store.getAll();

  request.onsuccess = async () => {
    const reports = request.result || [];
    const pendingReports = reports.filter((r) => r.status === 'PENDING' || r.status === 'RETRYING');

    for (const report of pendingReports) {
      try {
        await syncSingleReport(db, report);
      } catch (err) {
        console.error(`Background sync failed for report #${report.id}:`, err);
        await updateReportStatus(db, report.id, 'RETRYING', (report.retryCount || 0) + 1);
      }
    }
  };
}

async function syncSingleReport(db, report) {
  const payloadStr = JSON.stringify(report.payload || {});
  const payloadBytes = new Blob([payloadStr]).size;

  if (payloadBytes > MAX_PAYLOAD_SIZE) {
    console.log(`📦 Payload for report #${report.id} exceeds 10MB (${(payloadBytes / (1024*1024)).toFixed(2)}MB). Executing chunking...`);
    await syncChunkedReport(db, report, payloadStr);
  } else {
    // Standard Direct Sync
    const res = await fetch('/api/v1/scans/assess', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: payloadStr
    });

    if (res.ok) {
      await updateReportStatus(db, report.id, 'SYNCED', report.retryCount || 0);
    } else {
      throw new Error(`HTTP ${res.status}: ${res.statusText}`);
    }
  }
}

async function syncChunkedReport(db, report, payloadStr) {
  const totalChunks = Math.ceil(payloadStr.length / CHUNK_SIZE);
  console.log(`Splitting report #${report.id} into ${totalChunks} chunks of 2MB...`);

  for (let i = 0; i < totalChunks; i++) {
    const chunkData = payloadStr.substring(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE);
    const chunkRes = await fetch('/api/v1/scans/upload-chunk', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        reportId: report.id,
        chunkIndex: i,
        totalChunks: totalChunks,
        chunkData: chunkData
      })
    });

    if (!chunkRes.ok) {
      throw new Error(`Chunk ${i}/${totalChunks} upload failed with status ${chunkRes.status}`);
    }
  }

  // Finalize assembly
  const finalRes = await fetch('/api/v1/scans/assemble-report', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reportId: report.id, totalChunks: totalChunks })
  });

  if (finalRes.ok) {
    await updateReportStatus(db, report.id, 'SYNCED', report.retryCount || 0);
  } else {
    throw new Error('Final assembly of chunked report failed.');
  }
}

async function updateReportStatus(db, id, status, retryCount) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction('offline_reports', 'readwrite');
    const store = tx.objectStore('offline_reports');
    const getReq = store.get(id);

    getReq.onsuccess = () => {
      const data = getReq.result;
      if (data) {
        data.status = retryCount >= 5 ? 'FAILED_PERMANENT' : status;
        data.retryCount = retryCount;
        data.updatedAt = new Date().toISOString();
        store.put(data);
      }
      resolve();
    };
    getReq.onerror = () => reject(getReq.error);
  });
}
