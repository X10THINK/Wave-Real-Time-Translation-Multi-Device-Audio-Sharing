# Network Roles Versus Theater Speaker Positions

**Source:** `theater_setup_screen.dart`, lines 6–7, 61–63, 145–148.

**Network role:** How a phone participates in communication and transport, such as Host, Relay or Receiver.

**Speaker-position label:** Where a phone is intended to be placed relative to a viewer, for example Front Left, Center or Rear Right.

The source explicitly says these are independent. A device does not become a network relay because it is marked Surround Left. Radio links cannot by themselves provide an accurate physical positioning measurement.

This screen exposes Host-controlled position labels for peers already reported by native connectivity. It does not perform precise triangulation, create multichannel DSP outputs or establish synchronized 5.1/7.1 audio.

**Viva sentence:** `Speaker labels describe intended placement; network roles describe transport participation. They are different properties of a device.`