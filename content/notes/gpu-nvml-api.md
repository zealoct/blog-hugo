---
title: "NVML API 笔记"
date: 2018-08-09
toc: true
---

# NVML API

[The NVIDIA Management Library \(NVML\)](https://docs.nvidia.com/deploy/nvml-api/nvml-api-reference.html#nvml-api-reference) 是一套监控和管理 NVIDIA GPU 的 C 接口。常用的 `nvidia-smi` 工具就是基于 NVML 实现的。

整体上 NVML 接口可分为五类：

1. **支持类接口**：API 本身的初始化、状态清理等，猜测包含打开设备等，比较简单不再描述
2. **查询类接口**：查询各种状态
3. **控制类接口**：控制设备
4. **事件处理类接口**：
5. **错误报告类接口**：

## 查询类接口

查询接口又分为3小类

1. System Queries
2. Unit Queries
3. Device Queries

### System Queries

针对本地系统的查询，这一类查询接口**与设备无关**。包括查询 *Cuda驱动版本号*、*驱动版本号*、*NVML 版本号*、*进程名称*。

### Unit Queries

这个是 *[S-Class GPU](http://www.nvidia.in/object/product-tesla-S2050-in.html)* 专属的功能，一个 Unit 应该是可以包含多个 GPU 的外设（具体是什么没有深入研究），根据提供的接口来看 Unit 有独立的风扇、有 LED 和独立的温度检测，`UnitInfo_t `结构体中还包含固件版本等信息：

``` cpp
struct nvmlUnitInfo_t {
  char  firmwareVersion[96];  //  Firmware version. 
  char  id[96];               //  Product identifier. 
  char  name[96];             //  Product name. 
  char  serial[96];           //  Product serial number. 
}
```

可利用 Unit API 获取从属某个 Unit 的全部 Devices。

### Device Queries

Device 就是一块 GPU 卡，Device Queries 接口是最丰富的。详细说明可以移步 [NVML Device Queries](https://docs.nvidia.com/deploy/nvml-api/group__nvmlDeviceQueries.html#group__nvmlDeviceQueries)。这里依据功能对一些函数进行简单的分类，并列举 API 名称。

#### 获取 Device Handle

针对设备的查询接口需要传入 `nvmlDevice_t` 句柄，利用下列接口获取对应设备的句柄。

``` cpp
nvmlReturn_t nvmlDeviceGetHandleByIndex ( unsigned int  index, nvmlDevice_t* device )
nvmlReturn_t nvmlDeviceGetHandleByPciBusId ( const char* pciBusId, nvmlDevice_t* device )
nvmlReturn_t nvmlDeviceGetHandleBySerial ( const char* serial, nvmlDevice_t* device )
nvmlReturn_t nvmlDeviceGetHandleByUUID ( const char* uuid, nvmlDevice_t* device ) 
```

#### Basic Info

获取基本设备信息，设别数量、序列号、温度、UUID、名称、风扇等。

``` cpp
nvmlReturn_t nvmlDeviceGetCount ( unsigned int* deviceCount )
nvmlReturn_t nvmlDeviceGetSerial ( nvmlDevice_t device, char* serial, unsigned int  length )
nvmlReturn_t nvmlDeviceGetTemperature ( nvmlDevice_t device, nvmlTemperatureSensors_t sensorType, unsigned int* temp )
nvmlReturn_t nvmlDeviceGetTemperatureThreshold ( nvmlDevice_t device, nvmlTemperatureThresholds_t thresholdType, unsigned int* temp ) 
nvmlReturn_t nvmlDeviceGetUUID ( nvmlDevice_t device, char* uuid, unsigned int  length )
nvmlReturn_t nvmlDeviceGetName ( nvmlDevice_t device, char* name, unsigned int  length ) 
nvmlReturn_t nvmlDeviceGetFanSpeed ( nvmlDevice_t device, unsigned int* speed )
nvmlReturn_t nvmlDeviceGetBoardId ( nvmlDevice_t device, unsigned int* boardId ) 
nvmlReturn_t nvmlDeviceGetBrand ( nvmlDevice_t device, nvmlBrandType_t* type )
...
```

#### Memory & ECC

内存和 ECC 相关的信息。

``` cpp
nvmlReturn_t nvmlDeviceGetBAR1MemoryInfo ( nvmlDevice_t device, nvmlBAR1Memory_t* bar1Memory )
nvmlReturn_t nvmlDeviceGetMemoryErrorCounter ( nvmlDevice_t device, nvmlMemoryErrorType_t errorType, nvmlEccCounterType_t counterType, nvmlMemoryLocation_t locationType, unsigned long long* count )
nvmlReturn_t nvmlDeviceGetMemoryInfo ( nvmlDevice_t device, nvmlMemory_t* memory ) 

nvmlReturn_t nvmlDeviceGetDetailedEccErrors ( nvmlDevice_t device, nvmlMemoryErrorType_t errorType, nvmlEccCounterType_t counterType, nvmlEccErrorCounts_t* eccCounts )
nvmlReturn_t nvmlDeviceGetEccMode ( nvmlDevice_t device, nvmlEnableState_t* current, nvmlEnableState_t* pending ) 
nvmlReturn_t nvmlDeviceGetTotalEccErrors ( nvmlDevice_t device, nvmlMemoryErrorType_t errorType, nvmlEccCounterType_t counterType, unsigned long long* eccCounts )
...
```

#### Process

``` cpp
nvmlReturn_t nvmlDeviceGetComputeRunningProcesses ( nvmlDevice_t device, unsigned int* infoCount, nvmlProcessInfo_t* infos )
nvmlReturn_t nvmlDeviceGetGraphicsRunningProcesses ( nvmlDevice_t device, unsigned int* infoCount, nvmlProcessInfo_t* infos )
```

#### Power

``` cpp
nvmlReturn_t nvmlDeviceGetPowerManagementDefaultLimit ( nvmlDevice_t device, unsigned int* defaultLimit )
nvmlReturn_t nvmlDeviceGetPowerManagementLimit ( nvmlDevice_t device, unsigned int* limit )
nvmlReturn_t nvmlDeviceGetPowerManagementLimitConstraints ( nvmlDevice_t device, unsigned int* minLimit, unsigned int* maxLimit )
nvmlReturn_t nvmlDeviceGetPowerManagementMode ( nvmlDevice_t device, nvmlEnableState_t* mode )
nvmlReturn_t nvmlDeviceGetPowerState ( nvmlDevice_t device, nvmlPstates_t* pState )
nvmlReturn_t nvmlDeviceGetPowerUsage ( nvmlDevice_t device, unsigned int* power ) 

/* 这个不确定是否属于 power */
nvmlReturn_t nvmlDeviceGetTotalEnergyConsumption ( nvmlDevice_t device, unsigned long long* energy ) 
```

#### Affinity

``` cpp
nvmlReturn_t nvmlDeviceClearCpuAffinity ( nvmlDevice_t device )
nvmlReturn_t nvmlDeviceGetCpuAffinity ( nvmlDevice_t device, unsigned int  cpuSetSize, unsignedlong* cpuSet ) 
nvmlReturn_t nvmlDeviceSetCpuAffinity ( nvmlDevice_t device ) 
```

#### Clock、AutoBoost 相关

``` cpp
nvmlReturn_t nvmlDeviceGetClock ( nvmlDevice_t device, nvmlClockType_t clockType, nvmlClockId_t clockId, unsigned int* clockMHz )
nvmlReturn_t nvmlDeviceGetClockInfo ( nvmlDevice_t device, nvmlClockType_t type, unsigned int* clock )

nvmlReturn_t nvmlDeviceGetApplicationsClock ( nvmlDevice_t device, nvmlClockType_t clockType, unsigned int* clockMHz ) 
nvmlReturn_t nvmlDeviceGetDefaultApplicationsClock ( nvmlDevice_t device, nvmlClockType_t clockType, unsigned int* clockMHz ) 
nvmlReturn_t nvmlDeviceResetApplicationsClocks ( nvmlDevice_t device ) 

nvmlReturn_t nvmlDeviceGetAutoBoostedClocksEnabled ( nvmlDevice_t device, nvmlEnableState_t* isEnabled, nvmlEnableState_t* defaultIsEnabled )
nvmlReturn_t nvmlDeviceSetAutoBoostedClocksEnabled ( nvmlDevice_t device, nvmlEnableState_t enabled )

nvmlReturn_t nvmlDeviceGetCurrentClocksThrottleReasons ( nvmlDevice_t device, unsigned long long* clocksThrottleReasons ) 
...
```

#### PCI Info

``` cpp
nvmlReturn_t nvmlDeviceGetCurrPcieLinkGeneration ( nvmlDevice_t device, unsigned int* currLinkGen )
nvmlReturn_t nvmlDeviceGetCurrPcieLinkWidth ( nvmlDevice_t device, unsigned int* currLinkWidth ) 

nvmlReturn_t nvmlDeviceGetPciInfo ( nvmlDevice_t device, nvmlPciInfo_t* pci )
nvmlReturn_t nvmlDeviceGetPcieReplayCounter ( nvmlDevice_t device, unsigned int* value )
nvmlReturn_t nvmlDeviceGetPcieThroughput ( nvmlDevice_t device, nvmlPcieUtilCounter_t counter, unsigned int* value ) 

nvmlReturn_t nvmlDeviceGetMaxPcieLinkGeneration ( nvmlDevice_t device, unsigned int* maxLinkGen )
nvmlReturn_t nvmlDeviceGetMaxPcieLinkWidth ( nvmlDevice_t device, unsigned int* maxLinkWidth ) 
```

#### Topology

``` cpp
nvmlReturn_t nvmlDeviceGetTopologyCommonAncestor ( nvmlDevice_t device1, nvmlDevice_t device2, nvmlGpuTopologyLevel_t* pathInfo )
nvmlReturn_t nvmlDeviceGetTopologyNearestGpus ( nvmlDevice_t device, nvmlGpuTopologyLevel_t level, unsigned int* count, nvmlDevice_t* deviceArray ) 
nvmlReturn_t nvmlSystemGetTopologyGpuSet ( unsigned int  cpuNumber, unsigned int* count, nvmlDevice_t* deviceArray ) 
```

#### 其他

获取 RetiredPage、计算模式、 显示模式、Encoder 等信息，不再列举。

## 控制类接口

分为 Unit 控制和设备控制两类。

### Unit Command

只有一个设置 LED 颜色的接口。

``` cpp
nvmlReturn_t nvmlUnitSetLedState ( nvmlUnit_t unit, nvmlLedColor_t color ) 
```

### Device Command

全部接口如下，主要是针对设备一些可查询项，提供设置的功能，如 Ecc、Clock、计算模式等。

``` cpp
nvmlReturn_t nvmlDeviceClearEccErrorCounts ( nvmlDevice_t device, nvmlEccCounterType_t counterType )
nvmlReturn_t nvmlDeviceSetAPIRestriction ( nvmlDevice_t device, nvmlRestrictedAPI_t apiType, nvmlEnableState_t isRestricted )
nvmlReturn_t nvmlDeviceSetApplicationsClocks ( nvmlDevice_t device, unsigned int  memClockMHz, unsigned int  graphicsClockMHz )
nvmlReturn_t nvmlDeviceSetComputeMode ( nvmlDevice_t device, nvmlComputeMode_t mode )
nvmlReturn_t nvmlDeviceSetDriverModel ( nvmlDevice_t device, nvmlDriverModel_t driverModel, unsigned int  flags )
nvmlReturn_t nvmlDeviceSetEccMode ( nvmlDevice_t device, nvmlEnableState_t ecc )
nvmlReturn_t nvmlDeviceSetGpuOperationMode ( nvmlDevice_t device, nvmlGpuOperationMode_t mode )
nvmlReturn_t nvmlDeviceSetPersistenceMode ( nvmlDevice_t device, nvmlEnableState_t mode )
nvmlReturn_t nvmlDeviceSetPowerManagementLimit ( nvmlDevice_t device, unsigned int  limit ) 
```

## 事件处理类接口

NVML 可以向某个 Device 注册一个事件，然后等待该事件的发生。这里不再列举 API，支持的事件如下：

``` cpp
#define nvmlEventTypeAll
        Mask of all events. 
#define nvmlEventTypeClock 0x0000000000000010LL
        Event about clock changes. 
#define nvmlEventTypeDoubleBitEccError 0x0000000000000002LL
        Event about double bit ECC errors. 
#define nvmlEventTypeNone 0x0000000000000000LL
        Mask with no events. 
#define nvmlEventTypePState 0x0000000000000004LL
        Event about PState changes. 
#define nvmlEventTypeSingleBitEccError 0x0000000000000001LL
        Event about single bit ECC errors. 
#define nvmlEventTypeXidCriticalError 0x0000000000000008LL
        Event that Xid critical error occurred. 
```

## 错误报告类接口

``` cpp
const DECLDIR char* nvmlErrorString ( nvmlReturn_t result ) 
```

## 其他接口

包括 NvLink 控制、Grid 查询控制、vGPU 管理等。