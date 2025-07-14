# Introduction

The digital.auto dreamKIT is a proof-of-concept (PoC) hardware, providing a hands-on, physical experience for SDV applications. With the dreamKIT you can try out your digitally developed SDV features on a physical device. Therefore, it allows you to transfer your use case from the virtual exploration phase into the productization phase.

dreamKIT is a candidate for [SDV Alliance Integration Blueprint](https://covesa.global/wp-content/uploads/2024/04/SDV-alliance-announcement-20230109.pdf). Check it out the latest COVESA white paper release [here](https://covesa.global/wp-content/uploads/2024/05/SDV-Alliance-Integration-Blueprint-20240109.pdf)

The digital.auto dreamKIT includes a vehicle computing unit, a central gateway, and a mock-up in-vehicle infotainment touch screen. dreamKIT has CAN and Ethernet interfaces to connect with external devices, that can form a Zonal E/E Architecture network topology.

The dreamKIT is a proven PoC device, which is used in multiple international show cases, as well as in different co-innovation challenges for software engineers.

For a detailed overview of the dreamKIT system architecture and component interactions, see [DreamKit Architecture Overview](docs/DreamKit-Architecture-Overview.md).

Feature overview for development, experimentation, and innovation:

- Seamless integration with playground.digital.auto: SDV applications developed on playground could be deployed to the dreamKIT within seconds, wirelessly using socketIO technology.
- Built in SDV runtime environment: powered by Eclipse SDV solutions.
- Ease of customizing and experimenting a zonal EE architecture: dreamKIT has built-in central gateway – which has CAN/ CANFD and Ethernet interfaces - to connect and expand the network topology to different zone controller ECUs
- Ease of connecting an AUTOSAR embedded ECU: dreamKIT has a SDV runtime environment, that with minimal configuration (via OTA) could recognize and integrate with an external device.

  ![dreamKITa-and-playground](https://docs.digital.auto/docs/dreamkit/overview/images/playground-dreamKIT.png)

  [![dreamKIT Introduction](https://img.youtube.com/vi/-DdnHqg3Qeg/hqdefault.jpg)](https://youtu.be/-DdnHqg3Qeg)


# dreamKIT components

![dreamKIT_architecture](https://docs.digital.auto/docs/dreamkit/architecture/images/dreamKIT_architecture.png)

dreamKIT simplifies feature development with a complete device setup. It supports all components, from cloud to ECU, enabling you to easily build and integrate features of any complexity.

### NXP S32G Goldbox
NXP S32G unlocks extensive automotive development capabilities. Connecting to diverse embedded hardware through CAN, LIN, and SOME/IP, the S32G, running either QNX or a Yocto-based build, provides a robust foundation for real-time applications and complex E/E architecture designs. This flexibility makes dreamKIT an ideal solution for prototyping and deploying automotive features requiring high performance and reliability.

Learn more about NXP S32G Goldbox [here](https://www.nxp.com/design/design-center/development-boards-and-designs/GOLDBOX)


### NVIDIA Jetson AGX Orin
dreamKIT uses the NVIDIA Jetson Orin to provide a high-performance AI-capable vehicle computer for developing UI, AI, and QM apps. Its CUDA cores make it ideal for building and testing automotive AI. DreamKit leverages the full NVIDIA software stack (CUDA, TensorRT, DeepStream, etc.) and support, simplifying development. Plus, internet connectivity enables cloud integration for FOTA, SOTA, and SDV solutions.

Learn more about Jetson AGX Orin [here](https://www.nvidia.com/en-sg/autonomous-machines/embedded-systems/jetson-orin/)

### dreamPACK

We've created an example HVAC dreamPack with standard inputs and outputs to help you get started with Vehicle APIs. This provides a practical starting point for learning and experimentation.

 ![dreamPack](https://docs.digital.auto/docs/dreamkit/overview/images/Seamless_deployment.png)


 ### Wiring

 ![dreamkit wiring](https://bewebstudio.digitalauto.tech/data/projects/fuOFE9EXs7Mv/dreamkit-wiring.png)

# Project Folder Structure
```
📱 core/                                // Core platform components
└── dk-ivi-lite/                       // Main IVI application (Qt6 C++ with embedded services)

🛠️ deployment/                          // All deployment-related files
├── installation/                       // Installation scripts
│   ├── jetson-orin/                   // Jetson ORIN platform setup
│   └── nxp-s32g/                      // NXP S32G platform setup
├── docker/                            // Docker compositions (future use)
└── scripts/                           // Deployment scripts (future use)

🧩 examples/                            // Example applications and services
├── apps/                              // Sample QM applications (consumer apps)
│   ├── BYOD-coffeemachine-app/        // Coffee machine trigger app
│   └── dreampack-HVAC-app/            // HVAC control app
└── services/                          // Sample services (providers)
    ├── BYOD-coffeemachine-service/    // Coffee machine API service
    └── dreampack-HVAC-CAN-provider/   // HVAC CAN to API bridge

📚 docs/                               // All documentation
├── architecture/                      // System architecture and diagrams
└── development/                       // Development guides and usage docs

🔧 tools/                              // Development and utility tools
├── scripts/                           // Utility scripts (future use)
└── templates/                         // Project templates (future use)

🧪 tests/                              // Test suites (future use)
├── integration/                       // Integration tests
└── e2e/                              // End-to-end tests
```

## Approach
1. **First Time Setup**: If your DreamKit hardware doesn't have DreamOS installed, follow the instructions in `/deployment/installation/`.
2. **Explore Examples**: Experiment with the sample services and apps located in `/examples/services/` and `/examples/apps/`.
3. **Core Development**: The main IVI application is located in `/core/dk-ivi-lite/` with enhanced embedded architecture.
3. **Create a Service**: Build your own service to expose APIs for your hardware/features.
4. **Build a QM App**: Use your new APIs, along with existing ones, to create a cross-platform QM application.
5. **Connect and Extend**: Integrate your app with cloud services or UI apps to complete your feature