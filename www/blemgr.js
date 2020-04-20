var exec = require('cordova/exec');
var PLUGIN_NAME = 'BLEManager';

module.exports = {
    
    // iOS only functions
    scanningForPeripherals: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "scanningForPeripherals", []);
    },

    
    initPeripheralManager: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "initPeripheralManager", []);
    },

    startAdvertising: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "startAdvertising", []);
    },
    
    //Android only functions
    BleCustomModule: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "BleCustomModule", []);
    },
    
    onScanResult: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "onScanResult", []);
    },
    
    onBatchScanResults: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "onBatchScanResults", []);
    },
    
    onScanFailed: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "onScanFailed", []);
    },
    
    sendEvent: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "sendEvent", []);
    },
    
    advertise: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "advertise", []);
    },
    
    discover: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "discover", []);
    },
    
    getUUID: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "getUUID", []);
    },
    
    getRandomID: function (success, failure) {
        cordova.exec(success, failure, "BLEManager", "getRandomID", []);
    }
    
};