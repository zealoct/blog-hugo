---
title: NVidia Profiler
date: 2018-08-09
toc: true
---

# Profiler

- nvprof
  - nvvp
  - nsight

## Metrics 分类

**说明**：以下多级列表中所涉及到的各种分类的统计项均为举例说明所用，并非完整列表，查看所有性能数据统计的完整列表请查看[此链接](https://docs.nvidia.com/cuda/profiler-users-guide/index.html#metrics-reference)。

整体分类：数量统计类、效率统计类、利用率统计类、overhead 统计类

### 整体的利用率

- `achieved_occupancy`
  - *Ratio of the average active warps per active cycle to the maximum number of warps supported on a multiprocessor*

### 指令相关

#### 指令执行数量统计

- `cf_executed`
  - *Number of executed control-flow instructions*
-  `flop_count_dp`
-  `flop_count_dp_add` 
- `inst_executed`

#### 指令发射数量统计

- `cf_issued`
  - *Number of issued control-flow instructions*
- `inst_issued`

#### 指令执行统计数据

- `ipc`
- `ipc_instance`
  - *Instructions executed per cycle for a single multiprocessor*
- `issued_ipc`
- `inst_per_warp`
  - *Average number of instructions executed by each warp*

#### 执行效率

- `branch_efficiency`
  - *Ratio of non-divergent branches to total branches expressed as percentage*
- `flop_dp_efficiency`
- `gld_efficiency`

#### 指令执行单元利用等级

- `alu_fu_utilization`
- `cf_fu_utilization`
  - *The utilization level of the multiprocessor function units that execute control-flow instructions on a scale of 0 to 10*

#### Overhead

- `inst_replay_overhead`
  - *Average number of replays for each instruction executed*

#### Stalls 统计

* `stall_exec_dependency`
  * *Percentage of stalls occurring because an input required by the instruction is not yet available*
* `stall_inst_fetch`
* `stall_memory_dependency`
* `stall_sync`

### 内存相关

#### 各种读、写、请求吞吐

- `atomic_throughput`
  - *Global memory atomic and reduction throughput*
- `dram_read_throughput`
- `ecc_throughput`
- `gld_requested_throughput`
- `gld_throughput`
- `l2_l1_read_throughput`

#### 各种读、写、请求数量

- `atomic_transactions`
  - *Global memory atomic and reduction transactions*
- `dram_read_transactions`
- `ecc_transactions`
- `gld_transactions`

####  每个 request 内的平均数量计数

- `atomic_transactions_per_request`
  - *Average number of global memory atomic and reduction transactions performed for each atomic and reduction instruction*
- `gld_transactions_per_request`

#### 一些利用等级统计

- `dram_utilization`
  - *The utilization level of the device memory relative to the peak utilization on a scale of 0 to 10*
- `l2_utilization`

#### Overhead

- `atomic_replay_overhead`
  - *Average number of replays due to atomic and reduction bank conflicts for each instruction executed*
- `global_cache_replay_overhead`

#### Cache 命中率

- `l2_l1_read_hit_rate`
  - *Hit rate at L2 cache for all read requests from L1 cache*
- `l2_tex_read_hit_rate`

#### 数据大小统计

- `dram_write_bytes`
  - *Total bytes written from L2 cache to DRAM*
- `pcie_total_data_received`
  - *Total data bytes received through PCIe*
- `pcie_total_data_transmitted`
- `nvlink_user_data_received`
- `nvlink_user_data_transmitted`

## Metric 采集范围

每个 Metric 数据均有一个**采集范围**的概念，也就是说该性能数据在什么范围下是准确的，根据文档描述，共有三中范围：

1. **Single-context**：当GPU 上只有一个 Context 执行的时候，该数据才可准确采集；
2. **Multi-context**：当GPU 上有多个 Context 在同时执行的时候，该数据可精确到每个 Context 的粒度；
3. **Device**：表明该数据是在设备级别进行采集的；

绝大部分的数据都是 Multi-context 级别的，个别数据如 `pcie_total_data_received` 为 Device 级别的，在当前版本的文档中没有看到 Single-context 级别的数据，猜测应该是被 Device 级别替换掉了，从语义上来看 Device 是一种对 Single-context 更准确的描述。