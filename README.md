# Lid Harmonium

This project converts a MacBook into a digital harmonium. It uses the lid opening angle sensor to control the volume ("Bellows") and the keyboard to play notes.

## Architecture

The system consists of two parts:
1. **LidHarmoniumBackend (.NET)**: Handles the physics simulation (Air Pressure, Decay) and state management.
2. **LidSensorWatcher (Swift)**: Reads the hardware Lid Sensor, captures Key strokes, and generates low-latency audio.

See [Architecture Diagram](docs/architecture.mmd) for the data flow.
See [Physics Diagram](docs/physics.mmd) for the bellows simulation logic.

## Prerequisites

- **MacBook** (with a Lid Sensor).
- **Xcode** (for the Swift App).
- **.NET SDK 8.0** (for the Backend).

## How to Run

You must run the Backend first, then the Client.

### 1. Start the Backend

Open a terminal at the project root and run:

```bash
cd LidHarmoniumBackend
dotnet run --urls="http://localhost:5000"
```

The server will start listening on port 5000. It performs the "Physics Loop" (60 times per second) to calculate Air Pressure.

### 2. Start the Mac App

1. Open `LidSensorWatcher.xcodeproj` in Xcode.
2. Ensure the Signing and Capabilities are set correctly for your team.
3. Run the scheme `LidSensorWatcher`.
4. The app window must be **focused** to capture keyboard input.

## Features

- **Keyboard Notes**: Keys `a` through `l` mapped to C4-D5.
- **Bellows Physics**: 
  - Movement of the lid (Opening/Closing) pumps "Air" into the system.
  - Faster movement increases volume.
  - Stopping movement causes volume to sustain (Infinite Sustain).
- **Audio Engine**: 
  - Uses `AVAudioEngine` with `AVAudioUnitVarispeed` for pitch shifting.
  - Implements a Sine Wave generator.

## Troubleshooting

- **No Sound**: Ensure the Lid is moving. The instrument requires "Pumping" to generate initial pressure.
- **Connection Failed**: Ensure the .NET backend is running on port 5000 before starting the App.
