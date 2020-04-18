//
//  BLEManager.m

//
//  Created by Tarun Singh on 07/04/2020.
//  Copyright (c) 2020 Tarun Singh. All rights reserved.
//

#import "BLEManager.h"
#import <UIKit/UIKit.h>

#define CALLBACK_NONE 0
#define CALLBACK_RSSI 1
#define CALLBACK_SEND 2
#define CALLBACK_READ 3
#define CALLBACK_WRRS 4

#define TRANSFER_SERVICE_UUID           @"F55B6B00-73F1-4D4D-8E47-C090502DBD63"
#define TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FAEB13D4"


@implementation BLEManager

@synthesize discoveredPeripherals;

@synthesize delegate;

static BLEManager *manager = nil;

BOOL isConnecting;
int settedRSSI = defaultRSSI;

int lockCallBack = CALLBACK_NONE;

int currentRSSI;
NSData *currentData = nil;

NSError *writeResCode = nil;

NSString *currentService = nil;
NSString *currentCharacteristic = nil;

+ (BLEManager *)sharedManager
{
    return [self sharedManagerWithDelegate:nil];
}

+ (BLEManager *)sharedManagerWithDelegate:(id<BLEManagerDelegate>)delegate
{
    if(manager == nil)
    {
        manager = [[BLEManager alloc] initWithDelegate:delegate];
    }
    return manager;
}

- (void)disableBLEManager
{
    NSLog(@"disableBLEManager");
    if(manager != nil && self.delegate != nil)
    {
        [self.delegate BLEManagerDisabledDelegate];
    }
    self.delegate = nil;
    centralManager = nil;
    manager = nil;
}

- (void)delegateNew {
    [self.delegate newDelegate:@"UUIDString"];
}


- (id) initWithDelegate:(id<BLEManagerDelegate>)delegate
{
    self = [super init];
    if(self)
    {
        isConnecting = NO;
        self.delegate = delegate;
        discoveredPeripherals = [[NSMutableArray alloc] initWithObjects:nil];
    }
    return  self;
}

# pragma mark - CBCentralManager Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBManagerStatePoweredOn) {
        totalRSSI = 0;
        rssiCount = 0;
        [centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
      //  [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:nil];
        
      //  [NSTimer scheduledTimerWithTimeInterval:timeInverval target:self selector:@selector(scanBleTimeout:) userInfo:nil repeats:NO];
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"advertisementData===================:%@",advertisementData);
    NSLog(@"RSSI --------------------------- :%@",RSSI);
    NSLog(@"Peripheral Identifier is %@", peripheral.identifier);
    NSLog(@"Peripheral TXPower is is %@", [advertisementData valueForKey:@"CBAdvertisementDataTxPowerLevelKey"]);
    NSNumber *TXPower = [advertisementData valueForKey:@"CBAdvertisementDataTxPowerLevelKey"];
    NSLog(@"TX Power is %@", TXPower);
    
    
    NSArray *serviceUUID = [advertisementData valueForKey:@"kCBAdvDataServiceUUIDs"];
    NSString *UUIDString = [[serviceUUID objectAtIndex:0] UUIDString];
    
    int txPower = -59;
    float distance = 0;
    if (RSSI == 0) {
        NSLog(@"Device very far");
    }
    int ratio =  [RSSI intValue] *1.0/txPower;
    if (ratio < 1.0) {
        distance = pow(ratio, 10);
        NSLog(@"DISTANCE IS %f", distance);
    } else {
        distance = (0.89976) * pow(ratio, 7.7095) + 0.111;
        NSLog(@"DISTANCE IS %f", distance);
    }
    
    [peripheralArray addObject:peripheral.identifier.UUIDString];
    for (NSString *item in peripheralArray) {
        if (item == peripheral.identifier.UUIDString) {
            rssiCount += 1;
            totalRSSI = totalRSSI + RSSI.intValue;
            
            if (rssiCount == 5)  {
                rssiCount = 0;
            }
        }
    }
    
    int avgRSSI  = totalRSSI / 5;
    
    
    if (serviceUUID.count > 0) {
        
        NSMutableDictionary *objDict = [[NSMutableDictionary alloc]init];
        objDict[@"name"] = peripheral.name;
        objDict[@"UUID"] = UUIDString;
        objDict[@"distance"] = [[NSNumber numberWithFloat:distance] stringValue];
        objDict[@"rssi"] = [RSSI stringValue];
        objDict[@"id"] = peripheral.identifier;
        objDict[@"serviceUUIDs"] = peripheral.name;
        objDict[@"manufacturerData"] = @"";
        objDict[@"mtu"] = 0;
        objDict[@"overflowServiceUUIDs"] = nil;
        objDict[@"isConnectable"] = false;
        objDict[@"solicitedServiceUUIDs"] = nil;
        objDict[@"serviceData"] = @"";
        
        NSNotification *scanNotification = [NSNotification notificationWithName:@"DEVICE_SCANNED"
          object:self userInfo:objDict];
        [[NSNotificationCenter defaultCenter] postNotification:scanNotification];
    }
    
    if(peripheral.identifier == nil || RSSI.intValue < settedRSSI)
    {
        return;
    }
        
    for(int i = 0; i < discoveredPeripherals.count; i++){
        CBPeripheral *p = [self.discoveredPeripherals objectAtIndex:i];
            
        if([peripheral.identifier.UUIDString isEqualToString:p.identifier.UUIDString]){
            [self.discoveredPeripherals replaceObjectAtIndex:i withObject:peripheral];
//            NSLog(@"Duplicate UUID found updating...");
            return;
        }
    }
    [self.discoveredPeripherals addObject:peripheral];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"didConnectPeripheral");
    [self.delegate BLEManagerDidConnectPeripheral:peripheral];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didDisconnectPeripheral");
    lockCallBack = CALLBACK_NONE;
    writeResCode = [NSError errorWithDomain:@"" code:0 userInfo:@""];
    [self.delegate BLEManagerDisconnectPeripheral:peripheral error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    for(CBService *service in peripheral.services){
//        NSLog(@"service.UUID:%@",service.UUID.UUIDString);
//        if([currentService isEqualToString:service.UUID.UUIDString]){
//            NSArray *arr = [[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:currentCharacteristic], nil];
//            [peripheral discoverCharacteristics:arr forService:service];
//        }
        
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
    NSLog(@"service.UUID:%@",service.UUID.UUIDString);
    for(CBCharacteristic *characteristic in service.characteristics){
        NSLog(@"characteristic.UUID:%@, current:%@",characteristic.UUID.UUIDString,currentCharacteristic);
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didUpdateValueForCharacteristic");
//    NSLog(@"error(%d):%@", (int)error.code, [error localizedDescription]);
//    NSLog(@"data:%@", characteristic.value);
    
    switch (lockCallBack) {
        case CALLBACK_NONE:
        {
            currentData = nil;
            currentService = nil;
            currentCharacteristic = nil;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.delegate BLEManagerReceiveData:characteristic.value fromPeripheral:peripheral andServiceUUID:characteristic.service.UUID.UUIDString andCharacteristicUUID:characteristic.UUID.UUIDString];
            });
            break;
        }
        case CALLBACK_SEND:
        case CALLBACK_READ:
        {
            currentData = characteristic.value;
            break;
        }
        default:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.delegate BLEManagerReceiveData:characteristic.value fromPeripheral:peripheral andServiceUUID:characteristic.service.UUID.UUIDString andCharacteristicUUID:characteristic.UUID.UUIDString];
            });
            break;
        }
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didWriteValueForCharacteristic");
//    NSLog(@"charUUID:%@, error:%@", characteristic.UUID.UUIDString, [error localizedDescription]);
    writeResCode = error == nil ? [NSError errorWithDomain:@"" code:0 userInfo:@""] : error;
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral
                          error:(NSError *)error {
    
    NSLog(@"peripheral RSSI:%d",peripheral.RSSI.intValue);
    if(lockCallBack == CALLBACK_RSSI){
        currentRSSI = (int)peripheral.RSSI.integerValue;
    }
}

- (BOOL)isConnecting
{
    return isConnecting;
}

- (void)scanningForPeripherals
{
  //  settedRSSI = defaultRSSI;
  //  [discoveredPeripherals removeAllObjects];
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)scanningForPeripheralsWithDistance:(int)RSSI
{
    settedRSSI = RSSI;
    [discoveredPeripherals removeAllObjects];
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)scanBleTimeout:(NSTimer*)timer
{
    if (centralManager != NULL){
        [centralManager stopScan];
        
//        for(CBPeripheral *p in self.peripherals){
//            NSLog(@"peripheral.name:%@",p.name);
//        }
        [self.delegate BLEManagerReceiveAllPeripherals:self.discoveredPeripherals];
        
    }else{
        NSLog(@"CM is Null!");
    }
    NSLog(@"scanTimeout");
}

- (void)stopScanningForPeripherals
{
    [centralManager stopScan];
}

- (void)connectingPeripheral:(CBPeripheral *)peripheral
{
    if(isConnecting)
    {
        return;
    }
    
    isConnecting = YES;
    
    if(centralManager != nil)
    {
        peripheral.delegate = self;
        [centralManager connectPeripheral:peripheral options:nil];
        [centralManager stopScan];
    }
    else
    {
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral
{
    
    [centralManager stopScan];
    if (peripheral == nil){
        NSLog(@"connectPeripheral is NULL");
        return;
    }else if (peripheral.state == CBPeripheralStateConnected){
        [centralManager cancelPeripheralConnection:peripheral];
    }
}

- (int)readRSSI:(CBPeripheral *)peripheral
{
    if(peripheral.state != CBPeripheralStateConnected)
    {
        [self.delegate BLEManagerDisconnectPeripheral:peripheral error:nil];
        return 0;
    }else
    {
        [self waitingCallBack];
        lockCallBack = CALLBACK_RSSI;
        
        [peripheral readRSSI];
        
        int returnRSSI = 0;
        while(currentRSSI == 0 && lockCallBack == CALLBACK_RSSI){
             [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        lockCallBack = CALLBACK_NONE; // reset lockCallBack
        
        returnRSSI = currentRSSI;
        currentRSSI = 0;
        return returnRSSI;
    }
}

- (void)scanningForServicesWithPeripheral:(CBPeripheral *)peripheral{
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (NSError *) setValue:(NSData *) data forServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral
{
    if(isConnecting){
        peripheral.delegate = self;
        CBCharacteristic *characteristic = [self findCharacteristicWithServiceUUID:serviceUUID andCharacteristicUUID:charUUID andPeripheral:peripheral];
        if(characteristic == nil) return [NSError errorWithDomain:@"" code:0 userInfo:@""];
        NSLog(@"data:%@",data);
        NSLog(@"char.UUID:%@",characteristic.UUID.UUIDString);
        
        [self waitingCallBack];
        
        CBCharacteristicProperties properties = characteristic.properties;
        CBCharacteristicWriteType writeType = CBCharacteristicWriteWithoutResponse;
        if((properties & CBCharacteristicPropertyBroadcast) == CBCharacteristicPropertyBroadcast){
            NSLog(@"CBCharacteristicPropertyBroadcast");
        }
        if((properties & CBCharacteristicPropertyRead) == CBCharacteristicPropertyRead){
            NSLog(@"CBCharacteristicPropertyRead");
        }
        if((properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse){
            NSLog(@"CBCharacteristicPropertyWriteWithoutResponse");
            writeResCode = [NSError errorWithDomain:@"" code:0 userInfo:@""];
        }
        if((properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite){
            NSLog(@"CBCharacteristicPropertyWrite");
            writeType = CBCharacteristicWriteWithResponse;
            lockCallBack = CALLBACK_WRRS;
        }
        if((properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify){
            NSLog(@"CBCharacteristicPropertyNotify");
//            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        if((properties & CBCharacteristicPropertyIndicate) == CBCharacteristicPropertyIndicate){
            NSLog(@"CBCharacteristicPropertyIndicate");
        }
        if((properties & CBCharacteristicPropertyAuthenticatedSignedWrites) == CBCharacteristicPropertyAuthenticatedSignedWrites){
            NSLog(@"CBCharacteristicPropertyAuthenticatedSignedWrites");
        }
        if((properties & CBCharacteristicPropertyExtendedProperties) == CBCharacteristicPropertyExtendedProperties){
            NSLog(@"CBCharacteristicPropertyExtendedProperties");
        }
        
        [peripheral writeValue:data forCharacteristic:characteristic type:writeType];
        
        while(writeResCode == nil){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        lockCallBack = lockCallBack == CALLBACK_WRRS ? CALLBACK_NONE : lockCallBack; // reset lockCallBack
 
        NSError *rtn;
        rtn = writeResCode;
        writeResCode = nil;
        return rtn;
    }
    return [NSError errorWithDomain:@"" code:0 userInfo:@""];
}

- (NSData *)readValueForServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral
{
    if(isConnecting){
        CBCharacteristic *characteristic = [self findCharacteristicWithServiceUUID:serviceUUID andCharacteristicUUID:charUUID andPeripheral:peripheral];
        if(characteristic == nil) return nil;
        
        [self waitingCallBack];
        lockCallBack = CALLBACK_READ;
        [peripheral readValueForCharacteristic:characteristic];
        
        NSData *returnedData = nil;
        while(currentData == nil && lockCallBack == CALLBACK_READ){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        lockCallBack = CALLBACK_NONE; // reset lockCallBack
        
        returnedData = currentData;
        currentData = nil;
        return returnedData;
    }
    return  nil;
}

- (void)setNotify:(BOOL) isNotify forServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral {
    if(isConnecting){
        peripheral.delegate = self;
        CBCharacteristic *characteristic = [self findCharacteristicWithServiceUUID:serviceUUID andCharacteristicUUID:charUUID andPeripheral:peripheral];
        NSLog(@"char.UUID:%@",characteristic.UUID.UUIDString);
        
        CBCharacteristicProperties properties = characteristic.properties;
        if((properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify){
            NSLog(@"CBCharacteristicPropertyNotify");
            [peripheral setNotifyValue:isNotify forCharacteristic:characteristic];
            lockCallBack = CALLBACK_NONE;
        }
    }
}

- (CBCharacteristic *)findCharacteristicWithServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID andPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    NSLog(@"peripheral.name:%@", peripheral.name);
    for(CBService *servie in peripheral.services){
        if([serviceUUID isEqualToString:servie.UUID.UUIDString]){
            NSLog(@"service.UUID:%@", servie.UUID.UUIDString);
            for(CBCharacteristic *characteristic in servie.characteristics){
                if([charUUID isEqualToString:characteristic.UUID.UUIDString]){
                    NSLog(@"char.UUID:%@",characteristic.UUID.UUIDString);
                    return characteristic;
                }
            }
        }
    }
    return nil;
    
}

- (void)waitingCallBack
{
    while(lockCallBack != CALLBACK_NONE){
        sleep(1);
    }
}

//Enabling device as peripheral

-(void)initPeripheralManager
{
    NSLog(@"PERIPHERAL MANAGER INITIALISED");
    self.deviceUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSArray *uuidArray = [self.deviceUUID componentsSeparatedByString:@"-"];
    NSString *manipulatedUUID = [[[[uuidArray objectAtIndex:1] stringByAppendingFormat:@"-%@-", [uuidArray objectAtIndex:2]] stringByAppendingFormat:@"%@-", [uuidArray objectAtIndex:3]] stringByAppendingFormat:@"%@", [uuidArray objectAtIndex:4]];
    self.deviceUUID = [@"F55B6B00-" stringByAppendingFormat:@"%@", manipulatedUUID];
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

-(void)startAdvertising
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
//        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:self.deviceUUID]] }];
        
   // [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID], [CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] }];
        
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID], [CBUUID UUIDWithString:self.deviceUUID]], CBAdvertisementDataLocalNameKey: self.deviceUUID }];
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataTxPowerLevelKey : @(YES)}];
        
        NSLog(@"DEVICE STARTED ADVERTISING ITSELF AS A PERIPHERAL with UUID: - %@", self.deviceUUID);
    });
}

/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    

    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");

    // Start with the CBMutableCharacteristic
 //   self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];          // TARUN 8 apr
    
    // Then the service
    CBMutableService *staticService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    //CBMutableService *uuidService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID] primary:YES];                // TARUN 8 apr
    CBMutableService *uuidService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:self.deviceUUID] primary:YES];
    
    // Add the characteristic to the service
//    transferService.characteristics = @[self.transferCharacteristic];     // TARUN 8 apr
    // And add it to the peripheral manager
    [self.peripheralManager addService:staticService];
    [self.peripheralManager addService:uuidService];
}


@end
