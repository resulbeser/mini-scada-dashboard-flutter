# Mini SCADA Dashboard

A Flutter-based mini SCADA (Supervisory Control and Data Acquisition) dashboard application that simulates real-time monitoring of electrical systems, generators, and fuel levels with WebSocket connectivity.

## Features

- **Real-time Monitoring**: Live display of electrical parameters (voltage, RPM, temperature)
- **Mains & Genset Monitoring**: Separate monitoring sections for main power and generator systems
- **Fuel Level Indicators**: Visual fuel level bars for different tanks
- **WebSocket Integration**: Real-time data communication via WebSocket
- **Responsive Design**: Works on web, mobile, and desktop platforms
- **Interactive Controls**: Manual/Auto control simulation
- **Gauge Displays**: Visual gauges for voltage and other parameters

## Screenshots

The dashboard includes:
- Voltage monitoring for L1, L2, L3 phases
- Engine parameters (RPM, Oil Temperature, Fuel %)
- Fuel tank level indicators
- Control switches for Mains/Genset/Manual/Auto modes

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **WebSocket**: Real-time communication
- **Material 3**: Modern UI design

## Installation

1. **Prerequisites**: Ensure you have Flutter SDK installed
   ```bash
   flutter doctor
   ```

2. **Clone the repository**:
   ```bash
   git clone https://github.com/resulbeser/mini-scada-dashboard-flutter.git
   cd live_counter_app
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the application**:
   ```bash
   # Web
   flutter run -d chrome
   
   # Android
   flutter run -d android
   
   # Windows
   flutter run -d windows
   ```

## Project Structure

```
lib/
├── main.dart           # Main application entry point
├── widgets/            # Custom UI components
│   ├── SectionCard     # Card container widget
│   ├── GaugeCard       # Gauge display widget
│   ├── TableCard       # Data table widget
│   ├── FuelBar         # Fuel level indicator
│   └── ControlChip     # Control button widget
└── state/
    ├── AppState        # Application state management
    └── WebSocketState  # WebSocket connection state
```

## Configuration

### WebSocket Settings
The app attempts to connect to test WebSocket servers:
- `wss://ws.postman-echo.com/raw`
- `wss://socketsbay.com/wss/v2/1/demo/`
- `wss://echo-websocket.herokuapp.com/`

To use your own WebSocket server, modify the URLs in `WebSocketState.connect()` method.

### Simulated Data
The application generates simulated data based on a counter:
- Voltage values: 180V - 260V range
- Engine RPM: 1500 ± 200 RPM
- Oil temperature: 60°C ± 20°C
- Fuel levels: 0% - 100%

## Usage

1. **Start the application**: The app automatically attempts WebSocket connection on startup
2. **Monitor data**: View real-time electrical parameters and fuel levels
3. **Control simulation**: Use RUN button to increment counter and simulate data changes
4. **Reset**: Use STOP button to reset all values
5. **WebSocket status**: Check connection status at the bottom of the screen

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  web_socket_channel: ^2.4.0
```

## Troubleshooting

### WebSocket Connection Issues
If WebSocket connection fails:
1. Check internet connectivity
2. Try different WebSocket test servers
3. For local development, ensure firewall allows WebSocket connections
4. On web platform, CORS policies may block connections

### Platform-specific Issues
- **Web**: Some WebSocket servers may block connections due to CORS
- **Mobile**: Ensure network permissions are granted
- **Desktop**: Check firewall settings

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

**Resul Beser**
- GitHub: [@resulbeser](https://github.com/resulbeser)

## Acknowledgments

- Flutter team for the excellent framework
- Material Design for UI components
- WebSocket test servers for connectivity testing
