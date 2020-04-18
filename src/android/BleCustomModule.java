package com.covidcontacttracing;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.ParcelUuid;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.RequiresApi;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import org.json.JSONArray;

import javax.annotation.Nullable;


public class BleCustomModule extends ReactContextBaseJavaModule {

    String str;
    ReactApplicationContext reactContext;
    public static Callback success;
    public static Callback success2;
    Context applicationContext;


    // private Handler mHandler = new Handler();
    private List<ScanFilter> filters = new ArrayList<>();


    BleCustomModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        //this.applicationContext = applicationContext;
        //  mBluetoothLeScanner = BluetoothAdapter.getDefaultAdapter().getBluetoothLeScanner();

        if (!BluetoothAdapter.getDefaultAdapter().isMultipleAdvertisementSupported()) {
            // Toast.makeText(this, "Multiple advertisement not supported", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    public String getName() {
        return "BleCustomModule";
    }

    //int resultCode = -1;
    /*@ReactMethod
    public void startOcr(Callback success) {
        this.success = success;
        getReactApplicationContext().getCurrentActivity().startActivityForResult(
                new Intent(getReactApplicationContext().getCurrentActivity(), CameraActivity.class), -1);
        Log.e("startOcr", String.valueOf(success != null));

    }

    @ReactMethod
    public void startQR(Callback success) {
        this.success2 = success;
        Context context = getReactApplicationContext().getCurrentActivity();
        getReactApplicationContext().getCurrentActivity().startActivityForResult(
                new Intent(context, QrActivity.class), -1);
        Log.e("startOcr", String.valueOf(success != null));

    }*/

    ScanCallback mScanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            super.onScanResult(callbackType, result);
            Log.e("mBluetoothLeScanner", "Result : " + result);
            if (result == null
                    || result.getDevice() == null
                    || TextUtils.isEmpty(result.getDevice().getName())) {
                Log.e("mBluetoothLeScanner", "Result : " + result);
                return;
            } else {
                Log.e("mBluetoothLeScanner", "Result : " + result);
                int txPower = result.getTxPower();
            }

            StringBuilder builder = new StringBuilder(result.getDevice().getName());

            builder.append("\n").append(new String(result.getScanRecord().getServiceData(result.getScanRecord().getServiceUuids().get(0)), Charset.forName("UTF-8")));

            // mText.setText(builder.toString());


            WritableMap params = Arguments.createMap();
            params.putString("eventProperty", "someValue");
            sendEvent(reactContext, "EventReminder", params);
        }

        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            super.onBatchScanResults(results);
            Log.e("BLE", "onBatchScanResults: " + results);
        }

        @Override
        public void onScanFailed(int errorCode) {
            Log.e("BLE", "Discovery onScanFailed: " + errorCode);
            showToast("Discovery onScanFailed: " + errorCode);
            super.onScanFailed(errorCode);
        }
    };

    private void sendEvent(ReactApplicationContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }


    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @ReactMethod
    public void advertise(Callback Callback) {
        BluetoothLeAdvertiser advertiser = BluetoothAdapter.getDefaultAdapter().getBluetoothLeAdvertiser();
        UUID uId = getUUID();
        // String uId  =   "CDB7950D-73F1-4D4D-8E47-C090502DBD63";
        AdvertiseSettings settings = new AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .setConnectable(false)
                .build();

        ParcelUuid pUuid = new ParcelUuid(uId);
//        ParcelUuid pUuid = new ParcelUuid(UUID.fromString(uId));

        AdvertiseData data = new AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .addServiceUuid(pUuid)
                .build();

        AdvertiseCallback advertisingCallback = new AdvertiseCallback() {
            @Override
            public void onStartSuccess(AdvertiseSettings settingsInEffect) {
                super.onStartSuccess(settingsInEffect);
                showToast("Advertising onStartSuccess: ");
            }

            @Override
            public void onStartFailure(int errorCode) {
                Log.e("BLE", "Advertising onStartFailure: " + errorCode);
                showToast("Advertising onStartFailure: " + errorCode);
                super.onStartFailure(errorCode);
            }
        };

        if (advertiser != null) {
            advertiser.startAdvertising(settings, data, advertisingCallback);
        }
        Callback.invoke(uId.toString());
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @ReactMethod
    private void discover() {
        BluetoothLeScanner mBluetoothLeScanner = BluetoothAdapter.getDefaultAdapter().getBluetoothLeScanner();
        UUID uId = getUUID();
        //    String uId  =   "CDB7950D-73F1-4D4D-8E47-C090502DBD63";
        ScanFilter filter = new ScanFilter.Builder()
                .setServiceUuid(new ParcelUuid(uId))
//                .setServiceUuid(new ParcelUuid(UUID.fromString(uId)))
                .build();
        filters.add(filter);

        ScanSettings settings = new ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build();


        if (!BluetoothAdapter.getDefaultAdapter().isMultipleAdvertisementSupported()) {
            // Toast.makeText(this, "Multiple advertisement not supported", Toast.LENGTH_SHORT).show();
            Log.e("mBluetoothLeScanner", "Multiple advertisement not supported");
        }


        if (mBluetoothLeScanner != null) {
            Log.e("mBluetoothLeScanner", "insidenotnull");
            mBluetoothLeScanner.startScan(new ScanCallback() {
                @Override
                public void onScanResult(int callbackType, ScanResult result) {
                    super.onScanResult(callbackType, result);
                    Log.e("mBluetoothLeScanner", "onScanResult : " + result);

                    if (result == null) {
                        Log.e("mBluetoothLeScanner", "Result : " + result.getDevice());
                        return;
                    } else {
                        Log.e("Checking bluetooth Status", "Result : " + result);
//                        int txPower = result.getTxPower();

                        ArrayList<String> list = new ArrayList<>();
//
                        List<ParcelUuid> uuidArray = result.getScanRecord().getServiceUuids();
                        Log.e("uuidArray", "array : " + result.getScanRecord().getServiceUuids());
                        if(uuidArray != null) {
                            Log.e("uuidArray", "Size : " + uuidArray.size());
                            if (uuidArray.size() > 0) {
                                for (int i = 0; i < uuidArray.size(); i++) {
                                    list.add(uuidArray.get(i).toString());
                                }
                            }

                            JSONArray jsArray = new JSONArray(list);
//                        }
                            WritableMap params = Arguments.createMap();
                            params.putString("name", result.getDevice().getName());
                            params.putString("id", result.getDevice().getAddress());
                            params.putInt("mtu", 0);
                            params.putInt("txPower", result.getTxPower());
                            params.putInt("rssi", result.getRssi());
                            params.putInt("txPowerLevel", result.getScanRecord().getTxPowerLevel());
                            params.putString("localName", result.getScanRecord().getDeviceName());
                            params.putString("manufacturerData", result.getScanRecord().getManufacturerSpecificData().toString());
                            params.putBoolean("isConnectable", result.isConnectable());
                            params.putString("deviceName", result.getScanRecord().getDeviceName());
                            params.putString("SacnnedData", list.toString());
                            params.putString("serviceUUIDs", list.size() > 0 ? list.get(0) : "");
                            Log.e("Serachinhggggggg", "Serachinhggggggg : " + params);
                            sendEvent(reactContext, "EventReminder", params);

                        }}
                 }

                 @Override
                 public void onBatchScanResults(List<ScanResult> results) {
                     super.onBatchScanResults(results);
                     Log.e("mBluetoothLeScanner", "onBatchScanResults : "+results);
                 }

                 @Override
                 public void onScanFailed(int errorCode) {
                     super.onScanFailed(errorCode);
                    //  BluetoothAdapter.getDefaultAdapter().disable();
                    //  BluetoothAdapter.getDefaultAdapter().enable();
                     Log.e("mBluetoothLeScanner", "onScanFailed : "+errorCode);
                 }
             });
         }else {
             Log.e("mBluetoothLeScanner", "error in connectingl");
              mBluetoothLeScanner = BluetoothAdapter.getDefaultAdapter().getBluetoothLeScanner();
             Log.e("mBluetoothLeScanner", "Scanner : "+(mBluetoothLeScanner == null));
         }

        // mHandler.postDelayed(new Runnable() {
        //     @Override
        //     public void run() {
        //         mBluetoothLeScanner.stopScan(mScanCallback);
        //     }
        // }, 10000);
    }

    @ReactMethod
    private void showToast(String message) {

//        WritableMap params = Arguments.createMap();
//        params.putString("eventProperty", "someValue");
//        sendEvent(reactContext, "EventReminder", params);
        // Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show();
    }

    // private String getUUID() {
    //     TelephonyManager tManager = (TelephonyManager) getSystemService("CDB7950D-73F1-4D4D-8E47-C090502DBD63");
    //     String uuid = tManager.getDeviceId();
    //     return uuid;
    // }
      private UUID getUUID() {

           String str =  Settings.Secure.getString(reactContext.getContentResolver(), Settings.Secure.ANDROID_ID);

            UUID uuid = UUID.nameUUIDFromBytes(str.getBytes());
            String uuidM = uuid.toString();
          String appendedUdid= uuidM.substring(9,uuidM.length());
//       
          appendedUdid ="F55B6B00-"+appendedUdid;
          UUID UUID_1
                  = UUID
                  .fromString(appendedUdid);
          return UUID_1;
//          return uuid;
//   return "f5bac11b-c71d-3bb1-a6d4-4ccbf210d871";
    //   return UUID.randomUUID().toString(); 
  }

    private String getRandomID(){
        return UUID.randomUUID().toString();
    }
}
