---
layout: page
title: Resume
icon: fas fa-file
order: 1
---

<div style="display: flex; justify-content: flex-end; gap: 0.5rem; margin-top: -1.5rem; margin-bottom: 1rem;">
  <button id="toggle-lang"
          style="width: 160px; height: 36px; font-size: 14px; border: 1px solid #007bff; background: white; color: #007bff; border-radius: 5px; display: flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer;">
    <i class="fas fa-language"></i> &nbsp; <span id="toggle-lang-text">切换为中文</span>
  </button>
  <a href="{{ '/assets/files/resume_cn.pdf' | relative_url }}"
     download
     id="download-btn"
     style="width: 160px; height: 36px; font-size: 14px; border: 1px solid #198754; background: white; color: #198754; border-radius: 5px; display: flex; align-items: center; justify-content: center; gap: 6px; text-decoration: none;">
    <i class="fas fa-file-download"></i> &nbsp; <span id="download-text">Download PDF</span>
  </a>
</div>


<div id="lang-en" markdown="1">

## Yunfan Zhang

**Email:** hzzyf1206@gmail.com  
**Mobile:** +86-13738067577

---

## <i class="fas fa-graduation-cap"></i> &nbsp; **Education**

#### **Duke University**  
*M.S. in Electrical and Computer Engineering*  
**Aug 2023 – May 2025**  
GPA: 4.0 / 4.0 (5 A+)  
Teaching Assistant for: *Fundamental of Computer System and Engineering*  
**Relevant Coursework:** Digital and Analog VLSI Design, Semiconductor Device for IC, Computer Architecture, C/C++ Programming, Full-stack IoT System Development, Deep Learning Neural Networks, Random Signal and Noise

#### **University of Nottingham Ningbo China (UNNC)**  
*BEng (Hons) in Electrical and Electronic Engineering*  
**Sep 2019 – Jun 2023**  
GPA: 3.94 / 4.0 (Grade 78/100)  
**Awards:** Provost's Scholarship (2 years, top 1.5%), Distinguished Graduate  
**Programs Attended:** FURP Research Program, Summer Mini Semester, High-Flyer Scheme  
**Relevant Coursework:** Analog and Digital Electronics Circuits, RF, Robotics and Control, Sensing Systems, Embedded Computing, Signal Processing, C/C++, Power and Energy, Artificial Intelligence

#### **National University of Singapore**  
*Summer Research Project: Artificial Intelligence of Things*  
**Jul – Aug 2021**  
Developed an **Intelligent Irrigation System** using KNN, including circuit design, IoT architecture, data pipeline, and front-end UI.

#### **Peking University**  
*Summer School: Python Programming and Application*  

**Jul – Aug 2020**

---

## <i class="fas fa-flask"></i> &nbsp; **Projects & Research**

#### **ATPG Implementation with Siemens Tessent [Design for Test]** 
**Jan – Jun 2025**  
- Implemented scan chain insertion and ATPG pattern generation on RISC-V using Siemens Tessent.  
- Automated DFT using Tcl scripting; optimized scan architecture and validation.  
- Evaluated Tessent TestKompress for compression performance.

#### **Blood Glucose Monitoring Front-End IC Design [ASIC]**
**Jun 2024 – May 2025**  
- Designed folded-cascode op-amp and switched-capacitor sensing circuit for 0.3–45 μA.  
- Built second-order delta-sigma 12-bit ADC schematic and layout.

#### **50MHz 8-bit SAR ADC with Control Logic [Mixed-Signal IC]**
**Jan – May 2024**  
- Developed schematic & layout for 50MS/s 8-bit SAR ADC with split DAC, 2-stage dynamic comparator (124ps for 10 μV), low-power logic (936 μW), and adjustable sampling rate.

#### **Self-supervised Learning: SimCLR and RotNet**  
**Jan – Apr 2024**  
- Studied trade-offs in batch size, epochs, compute in SSL.  
- Fine-tuned SimCLR (ResNet50) and RotNet (ResNet18) on CIFAR-10.  
- Designed multi-positive NT-Xent loss, achieving +0.87% Top-1 accuracy.

#### **Adjustable PWM Generator [VLSI Design]**
**Oct – Dec 2023**  
- Created high-resolution (16-bit), low-power (15.12 μW@10 MHz) PWM generator in Cadence Virtuoso (TSMC 65nm).  
- Validated design using vector simulation.

#### **Computer System Architecture Design**  
**Oct – Dec 2023**  
- Built MIPS processor with extended ISA in structural Verilog, implemented on FPGA.  
- Created FSMs for VGA, PS2 interfaces.  
- Realized flappy bird game with scoring, PRNG, and peripheral support.

#### **Non-invasive Sensor Intelligence for Smart Buildings [Research @ UNNC]**  
**Jun 2022 – Apr 2023**  
- Designed sensor circuits, PCBs, and embedded software; built SQL-based IoT network.  
- Combined spectrum clustering + LSTM, achieving 89.2–90.3% activity recognition accuracy.

#### **Ultra-Wideband Indoor Positioning [RA @ UNNC]**  
**Jan – Apr 2022**  
- Reviewed literature, prepared experiments, and collected data.  
- Used regression forests to correct multipath-induced errors, achieving ~80% detection accuracy.

#### **Small Electric Vehicle with Vision Recognition**  
**Sep 2021 – Jun 2022**  
- Designed 50 W DC-DC converter, developed CPLD UART control.  
- Integrated sensors (gyro, ultrasonic), motor, display, and audio control.  
- Used OpenCV with Raspberry Pi for real-time vision tasks.

---

## <i class="fas fa-users"></i> &nbsp; **Extracurricular Activities**

#### **RoboMaster University Series Competition (UNNC)**  
**Oct 2021 – Jan 2022**  
- Built motion control system for robot (STM32 + Mecanum wheels).  
- Coordinated between algorithm & mechanical teams to resolve control protocol issues.

#### **Deputy Director, WEAVER Organization (UNNC)**  
**Jun 2020 – Jun 2021**  
- Managed finances, external relations, and event organization.  
- Assisted admission office for outreach in Hangzhou.

---

## <i class="fas fa-briefcase"></i> &nbsp; Internship Experience

#### **Software Development Intern – Continental AG, Shanghai**  
**Jun – Aug 2023**  
- Assisted validation for Xiaomi vehicle software systems.  
- Gained system-level understanding of vehicle software & hardware integration.

#### **Embedded Systems Intern – Serendipity @ UNNC Incubator**  
**Feb – Jun 2022**  
- Worked on 2nd-gen intelligent facial cleaning device.  
- Developed hardware/software, programmed and debugged chips, and interfaced sensors/actuators.  
- Gained experience with Linux kernel C programming.

---

## <i class="fas fa-tools"></i> &nbsp; **Skills**

- **Languages:** C / C++, Python, MATLAB, Verilog HDL  
- **Design Software:** Cadence Virtuoso, Altium Designer, MATLAB, SOLIDWORKS  
- **Hardware:** Mixed-signal IC design (schematic & layout), PCB design, embedded systems, soldering  
- **EDA Tools:** Siemens Tessent (DFT & compression)  
- **Robotics:** System control, real-time sensor integration  
- **Deep Learning:** CNN, RNN, self-supervised learning, pruning, and compression

</div>


<div id="lang-cn" style="display: none;" markdown="1">

## 张云帆

**邮箱：** hzzyf1206@gmail.com  
**电话：** +86-13738067577

---

## <i class="fas fa-graduation-cap"></i> &nbsp; 教育背景

#### **杜克大学（Duke University）**  
*电子与计算机工程硕士*  
**2023年8月 – 2025年5月**  
GPA: 4.0 / 4.0（5门A+）  
担任课程助教：*计算机系统与工程基础*  
**相关课程：** 数字与模拟VLSI设计、半导体器件、计算机体系结构、C/C++编程、全栈物联网系统开发、深度学习、随机信号与噪声

#### **宁波诺丁汉大学（UNNC）**  
*电子与电气工程荣誉学士*  
**2019年9月 – 2023年6月**  
GPA: 3.94 / 4.0（平均分78/100）  
**奖项：** 院长奖学金（两年，前1.5%）、优秀毕业生  
**项目经历：** FURP研究计划、暑期学期、精英项目  
**相关课程：** 模拟与数字电子电路、射频、机器人与控制、传感系统、嵌入式系统、信号处理、C/C++、能源与电力、人工智能

#### **新加坡国立大学（NUS）**  
*暑期研究项目：人工智能物联网*  
**2021年7月 – 2021年8月**  
使用KNN算法开发**智能灌溉系统**，包括电路设计、物联网架构、数据流程及前端界面设计。

#### **北京大学**  
*暑期课程：Python编程与应用*  
**2020年7月 – 2020年8月**

---

## <i class="fas fa-flask"></i> &nbsp; 项目与研究经历

#### **基于Siemens Tessent的ATPG实现 [可测性设计]**  
**2025年1月 – 2025年6月**  
- 在RISC-V平台上实现扫描链插入与ATPG激励生成  
- 编写Tcl脚本实现自动化DFT流程，优化扫描结构与验证  
- 评估Tessent TestKompress的压缩效果

#### **血糖检测前端芯片设计 [ASIC]**  
**2024年6月 – 2025年5月**  
- 设计了折叠共源共栅运放与0.3–45μA范围的开关电容感测电路  
- 完成二阶Δ-Σ 12位ADC的原理图与版图设计

#### **50MHz 8位SAR ADC与控制逻辑 [混合信号IC]**  
**2024年1月 – 2024年5月**  
- 设计了50MS/s 8位SAR ADC，包括分裂式DAC、2级动态比较器（124ps@10μV）、低功耗逻辑（936μW）  
- 支持采样速率可调

#### **自监督学习：SimCLR与RotNet**  
**2024年1月 – 2024年4月**  
- 研究了批次大小、训练周期与计算资源之间的权衡  
- 在CIFAR-10上微调SimCLR（ResNet50）与RotNet（ResNet18）  
- 设计多正样本NT-Xent损失函数，提升Top-1准确率0.87%

#### **可调PWM发生器 [VLSI设计]**  
**2023年10月 – 2023年12月**  
- 在Cadence Virtuoso中设计16位高分辨率低功耗PWM（15.12μW@10MHz，TSMC 65nm）  
- 通过向量仿真验证功能

#### **计算机系统架构设计**  
**2023年10月 – 2023年12月**  
- 使用结构化Verilog构建带扩展指令集的MIPS处理器，并部署至FPGA  
- 编写FSM控制VGA与PS2接口，实现Flappy Bird游戏

#### **智能建筑无创传感器研究 [UNNC科研项目]**  
**2022年6月 – 2023年4月**  
- 设计传感器电路与PCB，开发嵌入式软件并构建基于SQL的物联网系统  
- 利用频谱聚类与LSTM识别活动，准确率89.2–90.3%

#### **超宽带室内定位研究 [UNNC科研助理]**  
**2022年1月 – 2022年4月**  
- 完成文献调研、实验设计与数据采集  
- 利用回归森林校正多径误差，检测准确率约80%

#### **具视觉识别功能的小型电动车**  
**2021年9月 – 2022年6月**  
- 设计50W DC-DC转换器，开发基于CPLD的串口控制  
- 集成陀螺仪、超声波、马达、显示与音频控制  
- 使用树莓派与OpenCV实现实时视觉识别

---

## <i class="fas fa-users"></i> &nbsp; 课外活动

#### **RoboMaster 机器人比赛（UNNC）**  
**2021年10月 – 2022年1月**  
- 基于STM32设计全向轮机器人运动控制系统  
- 在算法与机械团队之间协调通信协议问题

#### **WEAVER组织副主任（UNNC）**  
**2020年6月 – 2021年6月**  
- 负责财务管理、对外交流及活动组织  
- 协助招生办进行杭州地区宣讲与接待

---

## <i class="fas fa-briefcase"></i> &nbsp; 实习经历

#### **软件开发实习生 – 大陆集团（上海）**  
**2023年6月 – 2023年8月**  
- 协助小米汽车软件系统验证  
- 熟悉车辆软件与硬件系统集成流程

#### **嵌入式系统实习生 – Serendipity（UNNC孵化器）**  
**2022年2月 – 2022年6月**  
- 参与第二代智能洁面仪研发  
- 负责软硬件开发、芯片编程与调试、传感器控制  
- 学习Linux内核C语言开发

---

## <i class="fas fa-tools"></i> &nbsp; 技能

- **编程语言：** C / C++、Python、MATLAB、Verilog HDL  
- **设计软件：** Cadence Virtuoso、Altium Designer、MATLAB、SOLIDWORKS  
- **硬件技能：** 混合信号IC设计（原理图与版图）、PCB设计、嵌入式系统、焊接  
- **EDA工具：** Siemens Tessent（DFT与压缩）  
- **机器人技术：** 控制系统设计、传感器集成  
- **深度学习：** CNN、RNN、自监督学习、剪枝与压缩  

</div>

<script>
  const btn = document.getElementById('toggle-lang');
  const en = document.getElementById('lang-en');
  const cn = document.getElementById('lang-cn');

  const langText = document.getElementById('toggle-lang-text');
  const downloadText = document.getElementById('download-text');
  const downloadBtn = document.getElementById('download-btn');

  btn.addEventListener('click', () => {
    const isEnglish = en.style.display !== 'none';
    en.style.display = isEnglish ? 'none' : '';
    cn.style.display = isEnglish ? '' : 'none';

    langText.textContent = isEnglish ? 'Switch to English' : '切换为中文';
    downloadText.textContent = isEnglish ? '下载 PDF 简历' : 'Download PDF';
    downloadBtn.href = isEnglish ? '{{ "/assets/files/resume_cn.pdf" | relative_url }}' : '{{ "/assets/files/resume_en.pdf" | relative_url }}';
  });
</script>


