import './styles.css';
import { start } from './ui/app';

declare const __SINGLE_FILE__: boolean;

start();

// Installable PWA: register the offline cache when served over http(s). The single-file build skips it.
if (!__SINGLE_FILE__ && 'serviceWorker' in navigator && location.protocol.startsWith('http') && !import.meta.env.DEV) {
  window.addEventListener('load', () => { navigator.serviceWorker.register('./sw.js').catch(() => undefined); });
}
