---
title: "LLVM Encoding Asm Label"
date: 2018-03-14T14:40:01+08:00
draft: false
categories: ["llvm", "compiler"]
---

汇编代码中的Label标记了一段汇编代码的起始地址，主要用在分支、跳转类的指令中，
一般汇编代码中的Label以字符串的形式出现，如：

    bne  r0, r1, __IF_THEN      # 如果r0!=r1,跳转到__IF_THEN标记的代码段
    jmp  __IF_ELSE              # 跳转到__IF_ELSE标记的代码段

其中`__IF_THEN`和`__IF_ELSE`分别标记了`if`语句的两个分支。
但是在实际的可执行文件中，Label并不存在，分支跳转指令中实际存储的是offset：

    -Op- -Rs- -Rt-      -    offset       -
    1000 0000 0001 0000 0000 0000 0000 1000 # bne  r0, r1, 8
                                            # 目标指令与当前PC差为8个字节
                                            # 跳过了一条jmp指令
    -Op-                -    offset       -
    1001 0000 0000 0000 0000 0000 0010 1000 # jmp  40
                                            # 跳过了9条指令

Label信息在编译初始阶段无法确定，直到最终完成编译的时候才会赋予其具体的值，
因此无法对Label进行静态的编码。
LLVM中使用**fixup**来处理这些在`MCCodeEmitter`中无法确定的信息。

以`jmp $target`指令为例，实现Label编码需要如下步骤：

1.  定义`jtarget`作为jmp指令的Operand:
    
        def jtarget : Operand<OtherVT> {
          let EncoderMethod = "getJumpTargetOpValue";
        }
    
    这里要指明使用`getJumpTargetOpValue()`方法来对该Operand进行编码

1.  定义`jmp`指令

        def B : InstJ<0b1001, (outs), (ins jtarget:$Addr),
                      "jmp $Addr", [(br bb:$Addr)]>;
    
    指定`jmp`指令输入类型为`jtarget`，这里jmp指令的基本编码是在`InstJ`类中定义的，
    但是实际上在`MCCodeEmitter::encodeInstruction()`完成的时候，
    `$Addr`域的编码还是全0。

1.  定义新的fixup类型：

        // in file: lib/Target/XXX/MCTargetDesc/XXXFixup.h
        namespace llvm {
        namespace XXX {
        enum Fixups {
            fixup_xxx_br16 = FirstTargetFixupKind,
            LastTargetFixupKind,
            NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
        };
        }
        }

1.  实现`getJumpTargetOpValue()`：

        unsigned XXXMCCodeEmitter::
        getJumpTargetOpValue(const MCInst &MI, unsigned OpIdx,
                             SmallVectorImpl<MCFixup> &Fixups,
                             const MCSubtargetInfo &STI) const {
          const MCOperand &MO = MI.getOperand(OpIdx);
          if (MO.isReg() || MO.isImm())
            return getMachineOpValue(MI, MO, Fixups, STI);
          Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                           (MCFixupKind)XXX::fixup_xxx_br16));
          return 0;
        }
    
    当`MCCodeEmitter`对指令进行编码的时候，会调用该函数来计算`jtarget`的编码，
    这里为该Label生成一个fixup，留待后续处理，并直接返回0作为临时编码。

1.  在`AsmBackend`中调整fixup：

        // in file: lib/Target/XXX/MCTargetDesc/XXXAsmBackend.h
        const MCFixupKindInfo &getFixupKindInfo(MCFixupKind Kind) const override {
          const static MCFixupKindInfo Infos[XXX::NumTargetFixupKinds] = {
          // This table *must* be in the order that the fixup_* kinds are defined in
          // XXXFixupKinds.h.
          //
          // Name                       Offset   Size  Flags
            { "fixup_xxx_br16",           0,       16,   MCFixupKindInfo::FKF_IsPCRel },
          };
          ...
        
        static unsigned adjustFixupValue(const MCFixup &Fixup, uint64_t Value,
                                         MCContext *Ctx = NULL) {
          ...
          case XXX::fixup_xxx_br16: {
            return Value & 0xffff;
          }
          ...
    
    `AsmBackend`执行的时候已经有Label的信息了，由于指定了`FKF_IsPCRel`属性，
    这里的`Value`就是与当前PC的offset。
    某些定长指令集会使用`jmp #instr`而不是`jmp #bytes`的语义，
    这种情况可以`return (Value >> 2)`（假设4byte）。

全部实现后，通过`clang -c --target=xxx test.cpp`编译出来的二进制就可以正常编码Label的offset了。