## MACHINE PROFILE
Documentation containing the machine profile for which the results will be attributed.

**DATE RECORDED:** 2026-10-02 (YYYY-MM-DD)


| Item                 | Commands                                                             | Output (MY MACHINE)                     |
|----------------------|----------------------------------------------------------------------|-----------------------------------------|
| Architecture         | `uname -m`                                                           | aarch64                                 |
| Kernel Version       | `uname -r`                                                           | Linux 6.8.0-142-generic                 |
| Distribution         | `cat /etc/os-release \| grep PRETTY_NAME`                            | Ubuntu 24.04.4 LTS                      |
| CPUs, cores, caches  | `lscpu`, `nproc`                                                     | 4vCPUs, 1 thread per core               |
| Memory Page Size     | `getconf PAGESIZE`                                                   | 4096                                    |
| VM memory            | `free -h`                                                            | 2.9Gi                                   |
| Free Disk Space      | `df -h`                                                              | 32GB                                    |
| gcc version          | `gcc --version \| head -1`                                           | (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0 |
| camek version        | `cmake --version \| head -1`                                         | cmake version 3.28.3                    |
| glibc version        | `ldd --version \| head -1`                                           | ldd (Ubuntu GLIBC 2.39-0ubuntu8.9) 2.39 |
|Byte Order            | `lscpu \| grep 'Byte Order`                                          | Little Endian                           |
|Clocksource           |`cat /sys/devices/system/clocksource/clocksource0/current_clocksource`| arch_sys_counter                        |
| Host                 | `sysctl -n machdep.cpu.brand_string`                                 | Apple Silicon M4                        |
| Host RAM (bytes)     | `sysctl -n hw.memsize` (macOS)                                       | 17179869184 bytes (16GB)                |
| Cache Line Size      | `cat /sys/devices/system/cpu/cpu0/cache/index0/coherency_line_size`  | Not exposed in VM                       |                
| clang version        | `clang --version \| head -1`                                         | Ubuntu clang version 18.1.3 (1ubuntu1)  |
| Virtualise or emulate| UTM VM settings                                                      | Virtualised (aarch64 guest on Apple Silicon host) |
| Cache line size      | `sysctl hw.cachelinesize` (macOS host)                               | 128 bytes |
| L1i/L1d/L2, P-cores  | `sysctl -a \| grep -i cachesize` (macOS host)                        | 192 KiB / 128 KiB / 16 MiB                |
| L1i/L1d/L2, E-cores  | `sysctl -a \| grep -i cachesize` (macOS host)                        | 128 KiB / 64 KiB / 4 MiB                  |
| L3                   | `sysctl -a \| grep -i cachesize` (macOS host)                        | Not reported                              |
| Transparent huge pages | `cat /sys/kernel/mm/transparent_hugepage/enabled`                  | madvise                                   |
| perf_event_paranoid    | `cat /proc/sys/kernel/perf_event_paranoid`        | 1 (Ubuntu default is 4; persisted in /etc/sysctl.d/99-perf.conf) |
| Hardware counters      | `perf stat -e cycles,instructions true`           | not supported for instructions and cycles in VM. Cachegrind used instead. |
| Dataset Sizes          | `ls -lh data/`                                                      | 13GB                                      |
| Valgirnd version       | `valgrind --version`                                                | valgrind-3.22.0                           |
| Python version         | `python3 --version`                                                 | Python 3.12.3                             |

## Implications
- As macOS schedules vCPUs on P-cores or E-cores, results can vary run to run. Therefore, all benchmarks use multiple runs, medians, and confidence intervals.
-  With no hardware counters in the VM, cache behaviour is measured with Cachegrind (simulated, relative comparisons only).
-  ARM `char` is unsigned (x86 signed): all bytes are `uint8_t`.
-  Cache line size is 128 bytes and not 64. Phase 5 must separate head/tail with `alignas(128)`. A 32-byte order record means 4 orders per line, not 2.
