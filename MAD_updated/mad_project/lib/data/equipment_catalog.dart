import '../models/equipment_item.dart';

final List<EquipmentItem> equipmentCatalog = [
  //---- COMPUTER AND PERIPHERALS -----

  //List for Laptops
  EquipmentItem(
    name: "ASUS 2026",
    category: "Laptop",
    status: "Unavailable",
    imagePath: "assets/equipment/Asus.png",
    description: "ASUS 2026 15 inch FHD IPS Chromebook, Intel Processor Up to 2.80GHz, 4GB DDR4, 128GB Storage, HDMI, Super-Fast WiFi, Chrome OS, Pastel Silver",
  ),
  EquipmentItem(
    name: "Acer Gateway Chromebook",
    category: "Laptop",
    status: "Available",
    imagePath: "assets/equipment/Acer.png",
    description: "Acer Gateway Chromebook 11.6 inch HD Display, Intel Processor Up to 2.40GHz, 4GB DDR4, 32GB Storage, HDMI, WiFi, Chrome OS, Black",
  ),
  EquipmentItem(
    name: "Lenovo Chromebook",
    category: "Laptop",
    status: "Unavailable",
    imagePath: "assets/equipment/Lenovo.png",
    description: "Lenovo Chromebook 11.6 inch HD Display, Intel Processor Up to 2.40GHz, 4GB DDR4, 32GB Storage, HDMI, WiFi, Chrome OS, Black",
  ),
  EquipmentItem(
    name: "Hp Stream",
    category: "Laptop",
    status: "Available",
    imagePath: "assets/equipment/HP.png",
    description: "Hp Stream 11.6 inch HD Display, Intel Processor Up to 2.40GHz, 4GB DDR4, 32GB Storage, HDMI, WiFi, Chrome OS, Black",
  ),
  EquipmentItem(
    name: "Dell",
    category: "Laptop",
    status: "Available",
    imagePath: "assets/equipment/Dell.png",
    description: "Dell 15 inch FHD IPS Chromebook, Intel Processor Up to 2.80GHz, 4GB DDR4, 128GB Storage, HDMI, Super-Fast WiFi, Chrome OS, Pastel Silver",
  ),

  //List for Flash Drives
  EquipmentItem(
    name: "SanDisk Cruzer Blade 128GB ",
    category: "Flash Drives",
    status: "Available",
    imagePath: "assets/equipment/Sandisk.png",
    description: "SanDisk Cruzer Blade 128GB USB 3.0 Flash Drive",
  ),
  EquipmentItem(
    name: "HKC USB 3.0 Flash Drive 32GB",
    category: "Flash Drives",
    status: "Available",
    imagePath: "assets/equipment/HKC.png",
    description: "HKC USB 3.0 Flash Drive 32GB",
  ),
  EquipmentItem(
    name: "Kingston USB Pendrive 8GB",
    category: "Flash Drives",
    status: "Available",
    imagePath: "assets/equipment/Kingston.png",
    description: "Kingston USB Pendrive 8GB",
  ),
  EquipmentItem(
    name: "2TB 2in1 USB 3.0 Flash Drive Type C",
    category: "Flash Drives",
    status: "Available",
    imagePath: "assets/equipment/2TB.png",
    description: "2TB 2in1 USB 3.0 Flash Drive Type C",
  ),

  //List for Wireless Mouse
  EquipmentItem(
    name: "INPHIC F1",
    category: "Wireless Mouse",
    status: "Available",
    imagePath: "assets/equipment/Inphic.png",
    description: "INPHIC F1 Wireless Mouse Rechargeable 500mAh Adjustable 1600DPI Ergonomic Silent Clickable Mouse",
  ),
  EquipmentItem(
    name: "Zeus M220",
    category: "Wireless Mouse",
    status: "Available",
    imagePath: "assets/equipment/Zeus.png",
    description: "Zeus M220 Wireless Gaming Mouse / Office Mouse With Nano Receiver And A Free Battery",
  ),
  EquipmentItem(
    name: "Fantech Raigor WG10",
    category: "Wireless Mouse",
    status: "Available",
    imagePath: "assets/equipment/Fantech.png",
    description: "Fantech Raigor II WG10 Wireless Gaming Mouse 2000 DPI 2.4 Ghz Pro Gaming Mouse",
  ),
  EquipmentItem(
    name: "HP S4000",
    category: "Wireless Mouse",
    status: "Available",
    imagePath: "assets/equipment/HPMouse.png",
    description: "HP Wireless Mouse S4000 Silent Portable Gaming Mouse USB Receiver 2.4GHz Adjustable DPI for Laptop PC Desktop",
  ),

  //List for Keyboards
  EquipmentItem(
    name: "Inplay BK680",
    category: "Keyboards",
    status: "Available",
    imagePath: "assets/equipment/Inplay.png",
    description: "Inplay BK680 RGB Gaming Keyboard Rainbow Light Waterproof Smooth Membrane Keyboard",
  ),
  EquipmentItem(
    name: "Gigaware K550",
    category: "Keyboards",
    status: "Available",
    imagePath: "assets/equipment/Gigaware.png",
    description: "Gigaware K550 87Key Mechanical Keyboard",
  ),
  EquipmentItem(
    name: "Zeus K-55",
    category: "Keyboards",
    status: "Available",
    imagePath: "assets/equipment/ZeusKeyboard.png",
    description: "Zeus K-55 RGB Gaming Keyboard 104 Keys Backlight Wired Mechanical Keyboard",
  ),

  //List for Webcams
  EquipmentItem(
    name: "INPLAY C1080PRO",
    category: "Webcams",
    status: "Available",
    imagePath: "assets/equipment/InplayWeb.png",
    description: "INPLAY C1080PRO USB Web Camera FHD 1080P Hi-Speed Build-in Mic Web Camera",
  ),
  EquipmentItem(
    name: "ICON 2k Video",
    category: "Webcams",
    status: "Available",
    imagePath: "assets/equipment/Icon.png",
    description: "ICON 2k Video Web Camera",
  ),
  EquipmentItem(
    name: "Rapow X801",
    category: "Webcams",
    status: "Available",
    imagePath: "assets/equipment/Rapow.png",
    description: "Rapow X801 Webcam Computer Camera Wired High Definition 1080P 2MP USB Built in Microphone",
  ),

  //List for Numeric Keypads
  EquipmentItem(
    name: "A4Tech FK13M Fstyler",
    category: "Numeric Keypads",
    status: "Available",
    imagePath: "assets/equipment/A4TECH fk13m.png",
    description: "A4Tech FK13M Fstyler Wired Numeric Keypad Micro USB",
  ),
  EquipmentItem(
    name: "ROBOT RK01",
    category: "Numeric Keypads",
    status: "Available",
    imagePath: "assets/equipment/Robot .png",
    description:
        "ROBOT RK01 Wired Numeric Keypad Black Original Small and Portable",
  ),

  //---- Cables, LAN, and Adapters -----

  //List for HDMI cables
  EquipmentItem(
    name: "UGREEN Premium (1m)",
    category: "HDMI Cables",
    status: "Available",
    imagePath: "assets/equipment/U1m.png",
    description: "UGREEN Premium HDMI Cable 1m 4K 60Hz High Speed HDMI Cable with Ethernet, Compatible with PS5, PS4, Xbox, TV, Monitor, Projector",
  ),
  EquipmentItem(
    name: "UGREEN Premium (2m)",
    category: "HDMI Cables",
    status: "Available",
    imagePath: "assets/equipment/U2m.png",
    description: "UGREEN Premium HDMI Cable 2m 4K 60Hz High Speed HDMI Cable with Ethernet, Compatible with PS5, PS4, Xbox, TV, Monitor, Projector",
  ),
  EquipmentItem(
    name: "UGREEN Premium (3m)",
    category: "HDMI Cables",
    status: "Available",
    imagePath: "assets/equipment/U3m.png",
    description: "UGREEN Premium HDMI Cable 3m 4K 60Hz High Speed HDMI Cable with Ethernet, Compatible with PS5, PS4, Xbox, TV, Monitor, Projector",
  ),
  EquipmentItem(
    name: "UGREEN Premium (5m)",
    category: "HDMI Cables",
    status: "Available",
    imagePath: "assets/equipment/U5m.png",
    description: "UGREEN Premium HDMI Cable 5m 4K 60Hz High Speed HDMI Cable with Ethernet, Compatible with PS5, PS4, Xbox, TV, Monitor, Projector",
  ),

  //Extension
  EquipmentItem(
    name: "Extension outlets",
    category: "Extension Cords",
    status: "Available",
    imagePath: "assets/equipment/Extension.png",
    description:
        "Extension Outlet Socket Plug With Switch Usb Cable Power Supply",
  ),
  EquipmentItem(
    name: "Zeus Multi-Function",
    category: "Extension Cords",
    status: "Available",
    imagePath: "assets/equipment/ZeusExt.png",
    description: "Zeus Multi-Function Socket Extension Outlet with 4 Power Socket AND 2 USB Ports",
  ),
  EquipmentItem(
    name: "Mitsushi 3 Sockets",
    category: "Extension Cords",
    status: "Available",
    imagePath: "assets/equipment/Mitsushi.png",
    description:
        "Mitsushi Power Extension Outlets Charger Power Strip (3 Sockets)",
  ),

  // USB-to-Ethernet Adapter
  EquipmentItem(
    name: "TRANYOO HB1-4 hub",
    category: "USB-to-Ethernet Adapter",
    status: "Available",
    imagePath: "assets/equipment/Tranyoo.png",
    description: "TRANYOO HB1-4 hub Type-C/USB to 4 USB and Ethernet Cable hub high-speed transmission",
  ),
  EquipmentItem(
    name: "Vention USB 3.0 2.0C",
    category: "USB-to-Ethernet Adapter",
    status: "Available",
    imagePath: "assets/equipment/vention.png",
    description: "Vention USB 3.0 2.0 C To Gigabit Ethernet Adapter Rj45 Network Card 1000mbps",
  ),
  EquipmentItem(
    name: "INPHIC USB 3.0 2.0C ",
    category: "USB-to-Ethernet Adapter",
    status: "Available",
    imagePath: "assets/equipment/InphicUSB.png",
    description: "INPHIC USB 3.0 2.0C to Gigabit Ethernet adapter Rj45 network card 1000mbps laptop",
  ),

  //LAN Cables
  EquipmentItem(
    name: "UGREEN 3M Cat6 UTP",
    category: "LAN Cables",
    status: "Available",
    imagePath: "assets/equipment/Ugreen3mCat6.png",
    description: "UGREEN 3M Cat6 UTP Network Cable Gigabit LAN Cord 250MHz Gold Connector (BLACK)",
  ),
  EquipmentItem(
    name: "UGREEN 5M Cat6 UTP",
    category: "LAN Cables",
    status: "Available",
    imagePath: "assets/equipment/Ugreen5mCat6.png",
    description: "UGREEN 5M Cat6 UTP Network Cable Gigabit LAN Cord 250MHz Gold Connector (Blue)",
  ),
  EquipmentItem(
    name: "UGREEN 10M Cat6 UTP ",
    category: "LAN Cables",
    status: "Available",
    imagePath: "assets/equipment/Ugreen 10mCat6.png",
    description: "UGREEN 10M Cat6 UTP Network Cable Gigabit LAN Cord 250MHz Gold Connector (Black)",
  ),

  //Presentation Clicker
  EquipmentItem(
    name: "Vention Presenter",
    category: "Presentation Clicker",
    status: "Available",
    imagePath: "assets/equipment/VentionClicker.png",
    description: "Vention Rechargeable Wireless Presenter Red/Green Laser Pointer 2.4GHz",
  ),
  EquipmentItem(
    name: "TYLEX XP60 ",
    category: "Presentation Clicker",
    status: "Available",
    imagePath: "assets/equipment/TYLEX.png",
    description: "TYLEX XP60 Top Grade Business PPT Laser Pointer 2.4GHz Multi-OS Compatible Plug And Play",
  ),
  //Speaker
  EquipmentItem(
    name: "Fantech Beat Pro GS306",
    category: "Speaker",
    status: "Available",
    imagePath: "assets/equipment/FantechBeat.png",
    description: "Fantech Beat Pro GS306 Gaming Speaker with Deep Bass Boost and RGB Lights",
  ),
  EquipmentItem(
    name: "Popcorn CS006",
    category: "Speaker",
    status: "Available",
    imagePath: "assets/equipment/popcorn.png",
    description: "Popcorn CS006 Mini Computer Speaker for PC RGB Soundbar Desktop Gaming Speaker Laptop",
  ),
  EquipmentItem(
    name: "Inplay MS003",
    category: "Speaker",
    status: "Available",
    imagePath: "assets/equipment/Inplay MS003.png",
    description: "Inplay MS003 Mini RGB Speakers 3D Surround Shocking Bass Boost USB+3.5mm Port For Laptop",
  ),

  //---- Networking Equipment and Tools -----

  //Switches
  EquipmentItem(
    name: "TP-Link LS1005",
    category: "Switches",
    status: "Available",
    imagePath: "assets/equipment/Ls1005.png",
    description: "TP-Link LS1005 Switch (White)",
  ),
  EquipmentItem(
    name: "TP-Link LS1005G",
    category: "Switches",
    status: "Available",
    imagePath: "assets/equipment/Ls1005 G.png",
    description: "TP-Link LS1005G Switch (Black)",
  ),
  EquipmentItem(
    name: "TP-Link LS105G",
    category: "Switches",
    status: "Available",
    imagePath: "assets/equipment/LS105G.png",
    description: "TP-Link LS105G Switch (Midgnight Blue)",
  ),
  EquipmentItem(
    name: "TP-Link LS1008",
    category: "Switches",
    status: "Available",
    imagePath: "assets/equipment/Ls1008.png",
    description: "TP-Link LS1008 Switch (White)",
  ),

  //LAn Cable Tester
  EquipmentItem(
    name: "Network Cable Tester",
    category: "LAN Cable Tester",
    status: "Available",
    imagePath: "assets/equipment/CableTester.png",
    description: "Network Cable Tester,Telephone Cable Wire Detection Equipment RJ45 RJ11 RJ12 CAT5 UTP",
  ),
  EquipmentItem(
    name: "ZoeRax",
    category: "LAN Cable Tester",
    status: "Available",
    imagePath: "assets/equipment/ZoeRax.png",
    description: "ZoeRax Network Ethernet Cable Tester for LAN RJ45 Cat5 Cat5e Cat6/6a/7 UTP/Shielded Cable",
  ),
  EquipmentItem(
    name: "ZoeRax USB Rechargeable",
    category: "LAN Cable Tester",
    status: "Available",
    imagePath: "assets/equipment/ZoeRaxUsb.png",
    description: "ZoeRax USB Rechargeable Network Cable Tester RJ45 RJ11 RJ12 LAN Tester with LED",
  ),

  //Crimping tool
  EquipmentItem(
    name: "ArgoX ",
    category: "Crimping Tool",
    status: "Available",
    imagePath: "assets/equipment/ArgoX.png",
    description: "ArgoX Network Crimping Tool 4P+6P+8P - Wire Stripper for RJ45, RJ11, RJ12 Cables",
  ),
  EquipmentItem(
    name: "UGREEN",
    category: "Crimping Tool",
    status: "Available",
    imagePath: "assets/equipment/UgreenCrimp.png",
    description: "UGREEN 3 in 1 Multifunctional Crimping Cutting Stripping Network Cable Pliers For Cat 6",
  ),
  EquipmentItem(
    name: "ZOERAX",
    category: "Crimping Tool",
    status: "Available",
    imagePath: "assets/equipment/ZoeRax Crimp.png",
    description: "ZOERAX RJ45 Crimping Tool Kit Pass Through Crimper for Cat6 Cat5e Ethernet Cable",
  ),
  EquipmentItem(
    name: "Vention",
    category: "Crimping Tool",
    status: "Available",
    imagePath: "assets/equipment/VentionCrimp.png",
    description: "Vention Multifunctional 4P / 6P / 8P Crimping Tool w/ for RJ45 Lan Network Cable",
  ),
];
