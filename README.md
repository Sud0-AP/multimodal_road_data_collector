# Multimodal Road Data Collector

A mobile application for collecting and analyzing road condition data using smartphone sensors and camera. The app detects road anomalies (bumps, potholes) through sensor data processing and captures synchronized video footage, creating multimodal datasets for road condition monitoring.

## Purpose

This application enables users to:
1. Collect synchronized sensor and camera data while driving on roads
2. Automatically detect road anomalies (bumps, potholes) using accelerometer data
3. Record road surface conditions for infrastructure analysis
4. Create structured datasets for road quality assessment and monitoring

## Technology Stack

- **Framework**: Flutter
- **State Management**: Flutter Riverpod
- **Navigation**: Go Router
- **Sensor Access**: sensors_plus package
- **Camera Integration**: camera package
- **Data Storage**: CSV file format for sensor data, MP4 for video
- **Time Synchronization**: NTP (Network Time Protocol)

## Key Features

### Sensor Calibration System

- **Initial Calibration**: Detects device orientation and calculates baseline sensor offsets
- **Pre-Recording Calibration**: Additional fine-tuning immediately before recording
- **Orientation Detection**: Supports multiple device mounting positions

### Bump/Pothole Detection Algorithm

The app uses a sophisticated spike detection algorithm to identify road anomalies:

1. **Data Processing Pipeline**:
   - Raw sensor readings → EMA (Exponential Moving Average) filtering → Calibration corrections
   - Calculation of acceleration magnitude: `sqrt(accelX² + accelY² + accelZ²)`
   - Dynamic threshold calculation based on device-specific calibration

2. **Detection Logic**:
   - Requires multiple consecutive readings above threshold to confirm detection
   - Implements refractory period (8 seconds) to prevent duplicate detections
   - Handles stronger anomalies within refractory period if they exceed previous magnitude by 4+
   - Synchronized linking of detections with exact video frame positions

### Data Collection & Storage

- **Sensor Data**: Stored in CSV format with the following fields:
  - Timestamp (ms)
  - Accelerometer values (X, Y, Z axes, magnitude)
  - Gyroscope values (X, Y, Z axes)
  - Bump/pothole detection flags
  - User feedback/annotations

- **Video Recording**: Synchronized with sensor data
  - Timestamped using NTP time synchronization
  - Resolution configurable through settings

- **Session Metadata**: Records calibration parameters, session timing, device orientation

## App Flow

1. **Onboarding**: First-time user setup and explanations
2. **Calibration**: Sensor calibration for accurate data collection
   - Detects device orientation
   - Calculates sensor offsets
   - Establishes bump detection threshold
3. **Home Screen**: Central hub for all activities
4. **Recording Screen**: Main data collection interface
   - Camera preview with recording controls
   - Real-time sensor visualization
   - Bump detection indicators
   - Optional annotation capabilities
5. **Recordings List**: Review and manage past recording sessions
6. **Settings**: Configure app parameters (bump sensitivity, annotation options)

## Technical Implementation Details

### Sensor Calibration Process

1. **Device Orientation Detection**:
   - Analyzes accelerometer patterns to determine mounting position
   - Supports portrait, landscape, upside-down orientations

2. **Zero-Point Calibration**:
   - Calculates accelerometer offsets: `accelXOffset`, `accelYOffset`, `accelZOffset`
   - Calculates gyroscope drift: `gyroXOffset`, `gyroYOffset`, `gyroZOffset`
   - Requires device to remain stationary during calibration

3. **Bump Threshold Calculation**:
   - Dynamic based on device and mounting characteristics
   - Applies multiplier from user settings (1.0-10.0) to adjust sensitivity

### Data Processing Formulas

- **Corrected Accelerometer Values**:
  ```
  correctedAccelZ = rawAccelZ - accelZOffset - sessionAccelOffsetZ
  ```

- **Corrected Gyroscope Values**:
  ```
  correctedGyroZ = gyroZ - gyroZOffset - gyroZDrift
  ```

- **Acceleration Magnitude Calculation**:
  ```
  accelMagnitude = sqrt(accelX² + accelY² + correctedAccelZ²)
  ```

- **Spike Detection Threshold**:
  ```
  detectionThreshold = baseThreshold × userDefinedMultiplier
  ```

### Performance Optimizations

- **EMA Filtering**: Reduces noise in accelerometer readings
- **Background CSV Writing**: Uses isolates to prevent UI jank during data saving
- **Buffered Data Storage**: Batch processing of sensor readings (300 points) before writing
- **Adaptive Sampling Rate**: Maintains consistent data collection regardless of device capabilities

## Data Privacy

- The app collects **only** camera data and motion sensor data (accelerometer, gyroscope)
- No location data (GPS coordinates), personal information, audio, or network information is collected
- All data is stored locally on the device, with user-controlled sharing options

## Future Development

- Data visualization and analysis tools
- Route tracking integration
- Cloud storage options for datasets
- Machine learning integration for improved anomaly detection
- Collaborative mapping features
