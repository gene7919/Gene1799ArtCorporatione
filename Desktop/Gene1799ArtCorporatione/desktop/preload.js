const { contextBridge, ipcMain } = require('electron');

contextBridge.exposeInMainWorld('electron', {
  invoke: (channel, data) => ipcMain.invoke(channel, data),
  on: (channel, callback) => ipcMain.on(channel, callback)
});
