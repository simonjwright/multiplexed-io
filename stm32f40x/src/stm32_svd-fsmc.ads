--  This spec has been automatically generated from STM32F40x.svd

pragma Restrictions (No_Elaboration_Code);
pragma Ada_2012;

with System;

package STM32_SVD.FSMC is
   pragma Preelaborate;

   ---------------
   -- Registers --
   ---------------

   subtype BCR1_MBKEN_Field is STM32_SVD.Bit;
   subtype BCR1_MUXEN_Field is STM32_SVD.Bit;
   subtype BCR1_MTYP_Field is STM32_SVD.UInt2;
   subtype BCR1_MWID_Field is STM32_SVD.UInt2;
   subtype BCR1_FACCEN_Field is STM32_SVD.Bit;
   subtype BCR1_BURSTEN_Field is STM32_SVD.Bit;
   subtype BCR1_WAITPOL_Field is STM32_SVD.Bit;
   subtype BCR1_WAITCFG_Field is STM32_SVD.Bit;
   subtype BCR1_WREN_Field is STM32_SVD.Bit;
   subtype BCR1_WAITEN_Field is STM32_SVD.Bit;
   subtype BCR1_EXTMOD_Field is STM32_SVD.Bit;
   subtype BCR1_ASYNCWAIT_Field is STM32_SVD.Bit;
   subtype BCR1_CBURSTRW_Field is STM32_SVD.Bit;

   --  SRAM/NOR-Flash chip-select control register 1
   type BCR1_Register is record
      --  MBKEN
      MBKEN          : BCR1_MBKEN_Field := 16#0#;
      --  MUXEN
      MUXEN          : BCR1_MUXEN_Field := 16#0#;
      --  MTYP
      MTYP           : BCR1_MTYP_Field := 16#0#;
      --  MWID
      MWID           : BCR1_MWID_Field := 16#1#;
      --  FACCEN
      FACCEN         : BCR1_FACCEN_Field := 16#1#;
      --  unspecified
      Reserved_7_7   : STM32_SVD.Bit := 16#1#;
      --  BURSTEN
      BURSTEN        : BCR1_BURSTEN_Field := 16#0#;
      --  WAITPOL
      WAITPOL        : BCR1_WAITPOL_Field := 16#0#;
      --  unspecified
      Reserved_10_10 : STM32_SVD.Bit := 16#0#;
      --  WAITCFG
      WAITCFG        : BCR1_WAITCFG_Field := 16#0#;
      --  WREN
      WREN           : BCR1_WREN_Field := 16#1#;
      --  WAITEN
      WAITEN         : BCR1_WAITEN_Field := 16#1#;
      --  EXTMOD
      EXTMOD         : BCR1_EXTMOD_Field := 16#0#;
      --  ASYNCWAIT
      ASYNCWAIT      : BCR1_ASYNCWAIT_Field := 16#0#;
      --  unspecified
      Reserved_16_18 : STM32_SVD.UInt3 := 16#0#;
      --  CBURSTRW
      CBURSTRW       : BCR1_CBURSTRW_Field := 16#0#;
      --  unspecified
      Reserved_20_31 : STM32_SVD.UInt12 := 16#0#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for BCR1_Register use record
      MBKEN          at 0 range 0 .. 0;
      MUXEN          at 0 range 1 .. 1;
      MTYP           at 0 range 2 .. 3;
      MWID           at 0 range 4 .. 5;
      FACCEN         at 0 range 6 .. 6;
      Reserved_7_7   at 0 range 7 .. 7;
      BURSTEN        at 0 range 8 .. 8;
      WAITPOL        at 0 range 9 .. 9;
      Reserved_10_10 at 0 range 10 .. 10;
      WAITCFG        at 0 range 11 .. 11;
      WREN           at 0 range 12 .. 12;
      WAITEN         at 0 range 13 .. 13;
      EXTMOD         at 0 range 14 .. 14;
      ASYNCWAIT      at 0 range 15 .. 15;
      Reserved_16_18 at 0 range 16 .. 18;
      CBURSTRW       at 0 range 19 .. 19;
      Reserved_20_31 at 0 range 20 .. 31;
   end record;

   subtype BTR_ADDSET_Field is STM32_SVD.UInt4;
   subtype BTR_ADDHLD_Field is STM32_SVD.UInt4;
   subtype BTR_DATAST_Field is STM32_SVD.Byte;
   subtype BTR_BUSTURN_Field is STM32_SVD.UInt4;
   subtype BTR_CLKDIV_Field is STM32_SVD.UInt4;
   subtype BTR_DATLAT_Field is STM32_SVD.UInt4;
   subtype BTR_ACCMOD_Field is STM32_SVD.UInt2;

   --  SRAM/NOR-Flash chip-select timing register 1
   type BTR_Register is record
      --  ADDSET
      ADDSET         : BTR_ADDSET_Field := 16#F#;
      --  ADDHLD
      ADDHLD         : BTR_ADDHLD_Field := 16#F#;
      --  DATAST
      DATAST         : BTR_DATAST_Field := 16#FF#;
      --  BUSTURN
      BUSTURN        : BTR_BUSTURN_Field := 16#F#;
      --  CLKDIV
      CLKDIV         : BTR_CLKDIV_Field := 16#F#;
      --  DATLAT
      DATLAT         : BTR_DATLAT_Field := 16#F#;
      --  ACCMOD
      ACCMOD         : BTR_ACCMOD_Field := 16#3#;
      --  unspecified
      Reserved_30_31 : STM32_SVD.UInt2 := 16#3#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for BTR_Register use record
      ADDSET         at 0 range 0 .. 3;
      ADDHLD         at 0 range 4 .. 7;
      DATAST         at 0 range 8 .. 15;
      BUSTURN        at 0 range 16 .. 19;
      CLKDIV         at 0 range 20 .. 23;
      DATLAT         at 0 range 24 .. 27;
      ACCMOD         at 0 range 28 .. 29;
      Reserved_30_31 at 0 range 30 .. 31;
   end record;

   subtype BCR_MBKEN_Field is STM32_SVD.Bit;
   subtype BCR_MUXEN_Field is STM32_SVD.Bit;
   subtype BCR_MTYP_Field is STM32_SVD.UInt2;
   subtype BCR_MWID_Field is STM32_SVD.UInt2;
   subtype BCR_FACCEN_Field is STM32_SVD.Bit;
   subtype BCR_BURSTEN_Field is STM32_SVD.Bit;
   subtype BCR_WAITPOL_Field is STM32_SVD.Bit;
   subtype BCR_WRAPMOD_Field is STM32_SVD.Bit;
   subtype BCR_WAITCFG_Field is STM32_SVD.Bit;
   subtype BCR_WREN_Field is STM32_SVD.Bit;
   subtype BCR_WAITEN_Field is STM32_SVD.Bit;
   subtype BCR_EXTMOD_Field is STM32_SVD.Bit;
   subtype BCR_ASYNCWAIT_Field is STM32_SVD.Bit;
   subtype BCR_CBURSTRW_Field is STM32_SVD.Bit;

   --  SRAM/NOR-Flash chip-select control register 2
   type BCR_Register is record
      --  MBKEN
      MBKEN          : BCR_MBKEN_Field := 16#0#;
      --  MUXEN
      MUXEN          : BCR_MUXEN_Field := 16#0#;
      --  MTYP
      MTYP           : BCR_MTYP_Field := 16#0#;
      --  MWID
      MWID           : BCR_MWID_Field := 16#1#;
      --  FACCEN
      FACCEN         : BCR_FACCEN_Field := 16#1#;
      --  unspecified
      Reserved_7_7   : STM32_SVD.Bit := 16#1#;
      --  BURSTEN
      BURSTEN        : BCR_BURSTEN_Field := 16#0#;
      --  WAITPOL
      WAITPOL        : BCR_WAITPOL_Field := 16#0#;
      --  WRAPMOD
      WRAPMOD        : BCR_WRAPMOD_Field := 16#0#;
      --  WAITCFG
      WAITCFG        : BCR_WAITCFG_Field := 16#0#;
      --  WREN
      WREN           : BCR_WREN_Field := 16#1#;
      --  WAITEN
      WAITEN         : BCR_WAITEN_Field := 16#1#;
      --  EXTMOD
      EXTMOD         : BCR_EXTMOD_Field := 16#0#;
      --  ASYNCWAIT
      ASYNCWAIT      : BCR_ASYNCWAIT_Field := 16#0#;
      --  unspecified
      Reserved_16_18 : STM32_SVD.UInt3 := 16#0#;
      --  CBURSTRW
      CBURSTRW       : BCR_CBURSTRW_Field := 16#0#;
      --  unspecified
      Reserved_20_31 : STM32_SVD.UInt12 := 16#0#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for BCR_Register use record
      MBKEN          at 0 range 0 .. 0;
      MUXEN          at 0 range 1 .. 1;
      MTYP           at 0 range 2 .. 3;
      MWID           at 0 range 4 .. 5;
      FACCEN         at 0 range 6 .. 6;
      Reserved_7_7   at 0 range 7 .. 7;
      BURSTEN        at 0 range 8 .. 8;
      WAITPOL        at 0 range 9 .. 9;
      WRAPMOD        at 0 range 10 .. 10;
      WAITCFG        at 0 range 11 .. 11;
      WREN           at 0 range 12 .. 12;
      WAITEN         at 0 range 13 .. 13;
      EXTMOD         at 0 range 14 .. 14;
      ASYNCWAIT      at 0 range 15 .. 15;
      Reserved_16_18 at 0 range 16 .. 18;
      CBURSTRW       at 0 range 19 .. 19;
      Reserved_20_31 at 0 range 20 .. 31;
   end record;

   subtype PCR_PWAITEN_Field is STM32_SVD.Bit;
   subtype PCR_PBKEN_Field is STM32_SVD.Bit;
   subtype PCR_PTYP_Field is STM32_SVD.Bit;
   subtype PCR_PWID_Field is STM32_SVD.UInt2;
   subtype PCR_ECCEN_Field is STM32_SVD.Bit;
   subtype PCR_TCLR_Field is STM32_SVD.UInt4;
   subtype PCR_TAR_Field is STM32_SVD.UInt4;
   subtype PCR_ECCPS_Field is STM32_SVD.UInt3;

   --  PC Card/NAND Flash control register 2
   type PCR_Register is record
      --  unspecified
      Reserved_0_0   : STM32_SVD.Bit := 16#0#;
      --  PWAITEN
      PWAITEN        : PCR_PWAITEN_Field := 16#0#;
      --  PBKEN
      PBKEN          : PCR_PBKEN_Field := 16#0#;
      --  PTYP
      PTYP           : PCR_PTYP_Field := 16#1#;
      --  PWID
      PWID           : PCR_PWID_Field := 16#1#;
      --  ECCEN
      ECCEN          : PCR_ECCEN_Field := 16#0#;
      --  unspecified
      Reserved_7_8   : STM32_SVD.UInt2 := 16#0#;
      --  TCLR
      TCLR           : PCR_TCLR_Field := 16#0#;
      --  TAR
      TAR            : PCR_TAR_Field := 16#0#;
      --  ECCPS
      ECCPS          : PCR_ECCPS_Field := 16#0#;
      --  unspecified
      Reserved_20_31 : STM32_SVD.UInt12 := 16#0#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for PCR_Register use record
      Reserved_0_0   at 0 range 0 .. 0;
      PWAITEN        at 0 range 1 .. 1;
      PBKEN          at 0 range 2 .. 2;
      PTYP           at 0 range 3 .. 3;
      PWID           at 0 range 4 .. 5;
      ECCEN          at 0 range 6 .. 6;
      Reserved_7_8   at 0 range 7 .. 8;
      TCLR           at 0 range 9 .. 12;
      TAR            at 0 range 13 .. 16;
      ECCPS          at 0 range 17 .. 19;
      Reserved_20_31 at 0 range 20 .. 31;
   end record;

   subtype SR_IRS_Field is STM32_SVD.Bit;
   subtype SR_ILS_Field is STM32_SVD.Bit;
   subtype SR_IFS_Field is STM32_SVD.Bit;
   subtype SR_IREN_Field is STM32_SVD.Bit;
   subtype SR_ILEN_Field is STM32_SVD.Bit;
   subtype SR_IFEN_Field is STM32_SVD.Bit;
   subtype SR_FEMPT_Field is STM32_SVD.Bit;

   --  FIFO status and interrupt register 2
   type SR_Register is record
      --  IRS
      IRS           : SR_IRS_Field := 16#0#;
      --  ILS
      ILS           : SR_ILS_Field := 16#0#;
      --  IFS
      IFS           : SR_IFS_Field := 16#0#;
      --  IREN
      IREN          : SR_IREN_Field := 16#0#;
      --  ILEN
      ILEN          : SR_ILEN_Field := 16#0#;
      --  IFEN
      IFEN          : SR_IFEN_Field := 16#0#;
      --  Read-only. FEMPT
      FEMPT         : SR_FEMPT_Field := 16#1#;
      --  unspecified
      Reserved_7_31 : STM32_SVD.UInt25 := 16#0#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for SR_Register use record
      IRS           at 0 range 0 .. 0;
      ILS           at 0 range 1 .. 1;
      IFS           at 0 range 2 .. 2;
      IREN          at 0 range 3 .. 3;
      ILEN          at 0 range 4 .. 4;
      IFEN          at 0 range 5 .. 5;
      FEMPT         at 0 range 6 .. 6;
      Reserved_7_31 at 0 range 7 .. 31;
   end record;

   subtype PMEM_MEMSETx_Field is STM32_SVD.Byte;
   subtype PMEM_MEMWAITx_Field is STM32_SVD.Byte;
   subtype PMEM_MEMHOLDx_Field is STM32_SVD.Byte;
   subtype PMEM_MEMHIZx_Field is STM32_SVD.Byte;

   --  Common memory space timing register 2
   type PMEM_Register is record
      --  MEMSETx
      MEMSETx  : PMEM_MEMSETx_Field := 16#FC#;
      --  MEMWAITx
      MEMWAITx : PMEM_MEMWAITx_Field := 16#FC#;
      --  MEMHOLDx
      MEMHOLDx : PMEM_MEMHOLDx_Field := 16#FC#;
      --  MEMHIZx
      MEMHIZx  : PMEM_MEMHIZx_Field := 16#FC#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for PMEM_Register use record
      MEMSETx  at 0 range 0 .. 7;
      MEMWAITx at 0 range 8 .. 15;
      MEMHOLDx at 0 range 16 .. 23;
      MEMHIZx  at 0 range 24 .. 31;
   end record;

   subtype PATT_ATTSETx_Field is STM32_SVD.Byte;
   subtype PATT_ATTWAITx_Field is STM32_SVD.Byte;
   subtype PATT_ATTHOLDx_Field is STM32_SVD.Byte;
   subtype PATT_ATTHIZx_Field is STM32_SVD.Byte;

   --  Attribute memory space timing register 2
   type PATT_Register is record
      --  ATTSETx
      ATTSETx  : PATT_ATTSETx_Field := 16#FC#;
      --  ATTWAITx
      ATTWAITx : PATT_ATTWAITx_Field := 16#FC#;
      --  ATTHOLDx
      ATTHOLDx : PATT_ATTHOLDx_Field := 16#FC#;
      --  ATTHIZx
      ATTHIZx  : PATT_ATTHIZx_Field := 16#FC#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for PATT_Register use record
      ATTSETx  at 0 range 0 .. 7;
      ATTWAITx at 0 range 8 .. 15;
      ATTHOLDx at 0 range 16 .. 23;
      ATTHIZx  at 0 range 24 .. 31;
   end record;

   subtype PIO4_IOSETx_Field is STM32_SVD.Byte;
   subtype PIO4_IOWAITx_Field is STM32_SVD.Byte;
   subtype PIO4_IOHOLDx_Field is STM32_SVD.Byte;
   subtype PIO4_IOHIZx_Field is STM32_SVD.Byte;

   --  I/O space timing register 4
   type PIO4_Register is record
      --  IOSETx
      IOSETx  : PIO4_IOSETx_Field := 16#FC#;
      --  IOWAITx
      IOWAITx : PIO4_IOWAITx_Field := 16#FC#;
      --  IOHOLDx
      IOHOLDx : PIO4_IOHOLDx_Field := 16#FC#;
      --  IOHIZx
      IOHIZx  : PIO4_IOHIZx_Field := 16#FC#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for PIO4_Register use record
      IOSETx  at 0 range 0 .. 7;
      IOWAITx at 0 range 8 .. 15;
      IOHOLDx at 0 range 16 .. 23;
      IOHIZx  at 0 range 24 .. 31;
   end record;

   subtype BWTR_ADDSET_Field is STM32_SVD.UInt4;
   subtype BWTR_ADDHLD_Field is STM32_SVD.UInt4;
   subtype BWTR_DATAST_Field is STM32_SVD.Byte;
   subtype BWTR_CLKDIV_Field is STM32_SVD.UInt4;
   subtype BWTR_DATLAT_Field is STM32_SVD.UInt4;
   subtype BWTR_ACCMOD_Field is STM32_SVD.UInt2;

   --  SRAM/NOR-Flash write timing registers 1
   type BWTR_Register is record
      --  ADDSET
      ADDSET         : BWTR_ADDSET_Field := 16#F#;
      --  ADDHLD
      ADDHLD         : BWTR_ADDHLD_Field := 16#F#;
      --  DATAST
      DATAST         : BWTR_DATAST_Field := 16#FF#;
      --  unspecified
      Reserved_16_19 : STM32_SVD.UInt4 := 16#F#;
      --  CLKDIV
      CLKDIV         : BWTR_CLKDIV_Field := 16#F#;
      --  DATLAT
      DATLAT         : BWTR_DATLAT_Field := 16#F#;
      --  ACCMOD
      ACCMOD         : BWTR_ACCMOD_Field := 16#0#;
      --  unspecified
      Reserved_30_31 : STM32_SVD.UInt2 := 16#0#;
   end record
     with Volatile_Full_Access, Size => 32,
          Bit_Order => System.Low_Order_First;

   for BWTR_Register use record
      ADDSET         at 0 range 0 .. 3;
      ADDHLD         at 0 range 4 .. 7;
      DATAST         at 0 range 8 .. 15;
      Reserved_16_19 at 0 range 16 .. 19;
      CLKDIV         at 0 range 20 .. 23;
      DATLAT         at 0 range 24 .. 27;
      ACCMOD         at 0 range 28 .. 29;
      Reserved_30_31 at 0 range 30 .. 31;
   end record;

   -----------------
   -- Peripherals --
   -----------------

   --  Flexible static memory controller
   type FSMC_Peripheral is record
      --  SRAM/NOR-Flash chip-select control register 1
      BCR1  : BCR1_Register;
      --  SRAM/NOR-Flash chip-select timing register 1
      BTR1  : BTR_Register;
      --  SRAM/NOR-Flash chip-select control register 2
      BCR2  : BCR_Register;
      --  SRAM/NOR-Flash chip-select timing register 2
      BTR2  : BTR_Register;
      --  SRAM/NOR-Flash chip-select control register 3
      BCR3  : BCR_Register;
      --  SRAM/NOR-Flash chip-select timing register 3
      BTR3  : BTR_Register;
      --  SRAM/NOR-Flash chip-select control register 4
      BCR4  : BCR_Register;
      --  SRAM/NOR-Flash chip-select timing register 4
      BTR4  : BTR_Register;
      --  PC Card/NAND Flash control register 2
      PCR2  : PCR_Register;
      --  FIFO status and interrupt register 2
      SR2   : SR_Register;
      --  Common memory space timing register 2
      PMEM2 : PMEM_Register;
      --  Attribute memory space timing register 2
      PATT2 : PATT_Register;
      --  ECC result register 2
      ECCR2 : STM32_SVD.Word;
      --  PC Card/NAND Flash control register 3
      PCR3  : PCR_Register;
      --  FIFO status and interrupt register 3
      SR3   : SR_Register;
      --  Common memory space timing register 3
      PMEM3 : PMEM_Register;
      --  Attribute memory space timing register 3
      PATT3 : PATT_Register;
      --  ECC result register 3
      ECCR3 : STM32_SVD.Word;
      --  PC Card/NAND Flash control register 4
      PCR4  : PCR_Register;
      --  FIFO status and interrupt register 4
      SR4   : SR_Register;
      --  Common memory space timing register 4
      PMEM4 : PMEM_Register;
      --  Attribute memory space timing register 4
      PATT4 : PATT_Register;
      --  I/O space timing register 4
      PIO4  : PIO4_Register;
      --  SRAM/NOR-Flash write timing registers 1
      BWTR1 : BWTR_Register;
      --  SRAM/NOR-Flash write timing registers 2
      BWTR2 : BWTR_Register;
      --  SRAM/NOR-Flash write timing registers 3
      BWTR3 : BWTR_Register;
      --  SRAM/NOR-Flash write timing registers 4
      BWTR4 : BWTR_Register;
   end record
     with Volatile;

   for FSMC_Peripheral use record
      BCR1  at 0 range 0 .. 31;
      BTR1  at 4 range 0 .. 31;
      BCR2  at 8 range 0 .. 31;
      BTR2  at 12 range 0 .. 31;
      BCR3  at 16 range 0 .. 31;
      BTR3  at 20 range 0 .. 31;
      BCR4  at 24 range 0 .. 31;
      BTR4  at 28 range 0 .. 31;
      PCR2  at 96 range 0 .. 31;
      SR2   at 100 range 0 .. 31;
      PMEM2 at 104 range 0 .. 31;
      PATT2 at 108 range 0 .. 31;
      ECCR2 at 116 range 0 .. 31;
      PCR3  at 128 range 0 .. 31;
      SR3   at 132 range 0 .. 31;
      PMEM3 at 136 range 0 .. 31;
      PATT3 at 140 range 0 .. 31;
      ECCR3 at 148 range 0 .. 31;
      PCR4  at 160 range 0 .. 31;
      SR4   at 164 range 0 .. 31;
      PMEM4 at 168 range 0 .. 31;
      PATT4 at 172 range 0 .. 31;
      PIO4  at 176 range 0 .. 31;
      BWTR1 at 260 range 0 .. 31;
      BWTR2 at 268 range 0 .. 31;
      BWTR3 at 276 range 0 .. 31;
      BWTR4 at 284 range 0 .. 31;
   end record;

   --  Flexible static memory controller
   FSMC_Periph : aliased FSMC_Peripheral
     with Import, Address => FSMC_Base;

end STM32_SVD.FSMC;
