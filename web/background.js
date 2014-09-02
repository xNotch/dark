
chrome.app.runtime.onLaunched.addListener(function(launchData) {
  chrome.app.window.create('dark.html', {
    'id': '_mainWindow', 'bounds': {'width': 853, 'height': 480 }
  });
});
