# v1.2 通信协议
## 接收数据包结构

传感器设备通过 **FFE4** 特征主动上报健康数据。

| 字段 | 索引 | 长度 | 数据类型 | 说明 |
|------|------|------|----------|------|
| 帧头1 | Byte 0 | 1 byte | UInt8 | 固定值 `0xAA` |
| 帧头2 | Byte 1 | 1 byte | UInt8 | 固定值 `0x55` |
| 心率  | Byte 2 | 1 byte | UInt8 | 心率值 (40-200 bpm) |
| 血氧  | Byte 3 | 1 byte | UInt8 | 血氧饱和度 (0-100%) |
| 电池电压高8位 | Byte 4 | 1 byte | UInt8 | 电池电压高字节 |
| 电池电压低8位 | Byte 5 | 1 byte | UInt8 | 电池电压低字节 |
| 步数  | Byte 6 | 1 byte | UInt8 | 步数高字节 |
| 步数  | Byte 7 | 1 byte | UInt8 | 步数低字节 |
| 版本号 | Byte 8 | 1 byte | UInt8 | 版本号，例如12代表1.2；24代表2.4 |
| 预留位 | Byte 9 | 1 byte | UInt8 | 预留以后备用 |
| 预留位 | Byte 10 | 1 byte | UInt8 | 预留以后备用 |
| 预留位 | Byte 11 | 1 byte | UInt8 | 预留以后备用 |
| 预留位 | Byte 12 | 1 byte | UInt8 | 预留以后备用 |
| 预留位 | Byte 13 | 1 byte | UInt8 | 预留以后备用 |
| 预留位位 | Byte 14 | 1 byte | UInt8 | 预留以后备用 |
| 帧尾1 | Byte 15 | 1 byte | UInt8 | 固定值 `0x55` |
| 帧尾2 | Byte 16 | 1 byte | UInt8 | 固定值 `0xAA` |

**数据包总长度**: 17 bytes