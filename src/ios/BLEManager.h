//
//  BLEManager.h
//
//  Created by Tarun Singh on 07/04/2020.
//  Copyright (c) 2020 Tarun Singh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define timeInverval 3.0f // timeount for scanning peripherals
#define defaultRSSI -100 // signal of blue device for detecting




@class BLEManager;
@protocol BLEManagerDelegate <NSObject>

@required
- (void)BLEManagerDisabledDelegate;
- (void)delegateNew;

@optional
- (void)BLEManagerReceiveAllPeripherals:(NSMutableArray *) peripherals;
- (void)BLEManagerDidConnectPeripheral:(CBPeripheral *)peripheral;
- (void)BLEManagerDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void)BLEManagerReceiveData:(NSData *) value fromPeripheral:(CBPeripheral *)peripheral andServiceUUID:(NSString *)serviceUUID andCharacteristicUUID:(NSString *)charUUID;
- (void)BLEManagerDidScanDevice:(CBPeripheral *)peripheral withADVData:(NSDictionary *)advertismentData withRSSI:(NSNumber *)rssiValue TXPower:(float) distance;
- (void)newDelegate:(NSString *)uuid;

@end

@interface BLEManager : NSObject <CBCentralManagerDelegate,CBPeripheralManagerDelegate>
{
    CBCentralManager *centralManager;
    int totalRSSI;
    int rssiCount;
    
    NSMutableArray *peripheralArray;
}

@property (strong,nonatomic) NSMutableArray *discoveredPeripherals;

@property (weak,nonatomic) id<BLEManagerDelegate> delegate;

@property (strong, nonatomic) CBPeripheralManager  *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;

@property (strong, nonatomic) NSString *deviceUUID;

+ (BLEManager *)sharedManagerWithDelegate:(id<BLEManagerDelegate>)delegate; // inital
+ (BLEManager *)sharedManager; // singleton

- (void)disableBLEManager; // disable delegate
- (BOOL)isConnecting;
- (void)scanningForPeripherals;
- (void)scanningForPeripheralsWithDistance:(int)RSSI;
- (void)stopScanningForPeripherals;
- (void)connectingPeripheral:(CBPeripheral *)peripheral;
- (void)disconnectPeripheral:(CBPeripheral *)peripheral;
- (int)readRSSI:(CBPeripheral *)peripheral;


-(void)initPeripheralManager;
-(void)startAdvertising;

- (void)scanningForServicesWithPeripheral:(CBPeripheral *)peripheral;

// after discovering services and characteristics
- (NSError *)setValue:(NSData *) data forServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral;
- (NSData *)readValueForServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral;
- (void)setNotify:(BOOL) isNotify forServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral;

@end



