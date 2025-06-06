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

# Project Folder Struture
```
- dreamos-core                          // the core component to manage the whole system
  - dk-ivi-lite                         // a simple IVI write by Qt6 C++ to provide an user interface
  - dm-manager                          // C++ app, core component to orchestrate the whole system: swupdate, sw install,...
- installation-scripts                  // installtion script, to setup new dreamKIT SW from scratch
  - jetson-orin                         // installation guide and scripts for jetson ORIN
  - nxp-s32g                            // installation guide and scripts for NXP S32G
- qm-apps                               // sample QM app (comsumer), these apps provide value to end user 
  - BYOD-coffeemachine-app              // an app to trigger coffee machine when you on door in the morning
  - dreampack-HVAC-app                  // an app to control HVAC dreamPACK
- services                              // sample service(provider), these services expose vehicle API to external 
  - BYOD-coffeemachine-service          // this service provide API to control coffee machine
  - dreampack-HVAC-CAN-provider          // this service provide API to control HVAC dreamPACK(convert CAN signal to vehicle API)
```

## Approach
1. **First Time Setup**: If your DreamKit hardware doesn't have DreamOS installed, follow the instructions in /installation-scripts.
2. **Explore Examples**: Experiment with the sample services and apps located in /services and /apps.
3. **Create a Service**: Build your own service to expose APIs for your hardware/features.
4. **Build a QM App**: Use your new APIs, along with existing ones, to create a cross-platform QM application.
5. **Connect and Extend**: Integrate your app with cloud services or UI apps to complete your feature