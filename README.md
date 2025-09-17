# Zephyr on Nix 

A reproducible Zephyr RTOS project using Nix for dependency management.

## 🚀 Quick Start

### Prerequisites
- [Nix](https://nixos.org/download.html) with flakes enabled
- Git

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/my-zephyr-project.git
   cd my-zephyr-project
   ```

2. **Enter the development environment:**
   ```bash
   nix develop
   ```

3. **Initialize the project (first time only):**
   ```bash
   ./scripts/setup.sh
   ```

4. **Build the project:**
   ```bash
   west build -b nrf52840dk_nrf52840 .
   ```

5. **Flash to device:**
   ```bash
   west flash
   ```

## 📁 Project Structure

```
my-zephyr-project/
├── flake.nix              # Nix development environment
├── west.yml               # West manifest (pins Zephyr version)
├── zephyr/                # Zephyr RTOS (managed by west, gitignored)
├── src/                   # Your application source code
├── dts/overlays/          # Device tree overlays
└── scripts/               # Helper scripts
```

## 🔧 Development Workflow

### Building
```bash
# Clean build
west build -b nrf52840dk_nrf52840 . --pristine

# Incremental build
west build
```

### Flashing and Debugging
```bash
# Flash to device
west flash

# Debug with GDB
west debug

# Monitor serial output
west espmonitor  # or minicom, screen, etc.
```

### Updating Dependencies
```bash
# Update west dependencies
west update

# Update Nix dependencies
nix flake update
```

## 🎯 Key Features

- **📌 Pinned Versions**: Zephyr version is locked in `west.yml`
- **🔄 Reproducible**: Nix ensures identical environments across machines
- **⚡ Fast Setup**: Single `nix develop` command gets everything ready
- **🧹 Clean**: No global installation pollution
- **🔒 Locked Dependencies**: `flake.lock` ensures exact package versions

## 📋 Supported Boards

- nRF52840 DK (`nrf52840dk_nrf52840`)
- Add more boards as needed...

## 🔄 Updating Zephyr Version

1. Update the `revision` in `west.yml`:
   ```yaml
   revision: v3.6.0  # New version
   ```

2. Update west dependencies:
   ```bash
   west update
   ```

3. Commit the changes:
   ```bash
   git add west.yml
   git commit -m "Update Zephyr to v3.6.0"
   ```

## 🛠️ Customization

### Adding New Dependencies

1. **Python packages**: Add to `pythonEnv` in `flake.nix`
2. **System packages**: Add to `buildInputs` in `flake.nix`
3. **Zephyr modules**: Add to `projects` in `west.yml`

### Custom Board Support

1. Add board definition to `boards/`
2. Update build commands to use your custom board

## 🐛 Troubleshooting

### Common Issues

**"nix flakes are an experimental feature"**
```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**"west: command not found"**
- Make sure you're in the Nix shell: `nix develop`

**"ZEPHYR_BASE not set"**
- Run the setup script: `./scripts/setup.sh`

**Build errors after updating**
- Try a clean build: `west build --pristine`

**Permission denied on /dev/ttyACM0**
- Add your user to the `dialout` group (Linux)
- Use `sudo` for flashing (not recommended)

## 📚 Documentation

- [Zephyr Documentation](https://docs.zephyrproject.org/)
- [West Documentation](https://docs.zephyrproject.org/latest/develop/west/index.html)
- [Nix Documentation](https://nixos.org/manual/nix/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request