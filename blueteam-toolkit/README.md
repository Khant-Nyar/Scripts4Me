# Blue Team Security Toolkit

A production-grade, modular Bash-based security framework for analyzing web server logs and detecting various attack patterns.

## Features

- **Advanced Attack Detection**
  - SQL Injection (SQLi)
  - Remote Code Execution (RCE)
  - Cross-Site Scripting (XSS)
  - Path Traversal
  - Log4Shell (CVE-2021-44228)
  - Webshell/Backdoor Detection
  - Brute Force Detection
  - Directory Enumeration Detection
  - Sensitive File Probing Detection
  - Scanner Activity Detection

- **Analysis Features**
  - IP Profiling (top attackers)
  - User Agent Analysis
  - Timeline Analysis
  - Threat Scoring
  - Risk Level Classification (CRITICAL, HIGH, MEDIUM, LOW)

- **Output Options**
  - Terminal TUI with colorized output
  - JSON export mode
  - CSV export mode
  - Quiet mode

## Architecture

```
blueteam-toolkit/
├── blueteam.sh           # Main entry point
├── core/                 # Core utilities
│   ├── Colors.sh         # Terminal colors
│   ├── Logger.sh         # Logging functions
│   ├── Utils.sh          # Utility functions
│   └── Config.sh         # Configuration management
├── detectors/            # Attack detection modules
│   ├── SQLiDetector.sh
│   ├── RCEDetector.sh
│   ├── BackdoorDetector.sh
│   ├── BruteForceDetector.sh
│   ├── XSSDetector.sh
│   ├── PathTraversalDetector.sh
│   ├── Log4ShellDetector.sh
│   ├── ScannerDetector.sh
│   ├── FileDisclosureDetector.sh
│   └── EnumerationDetector.sh
├── analyzers/            # Analysis modules
│   ├── IPProfiler.sh
│   └── TimelineAnalyzer.sh
├── ui/                   # User interface
│   ├── Banner.sh
│   └── ReportPrinter.sh
├── config/               # Configuration
│   └── default.conf
└── sample_access.log     # Sample log file for testing
```

## Installation

```bash
cd blueteam-toolkit
chmod +x blueteam.sh
```

## Usage

```bash
# Basic usage
./blueteam.sh /var/log/nginx/access.log

# JSON output
./blueteam.sh --json /var/log/nginx/access.log

# CSV output
./blueteam.sh --csv /var/log/nginx/access.log

# Quiet mode (no banner)
./blueteam.sh --quiet /var/log/nginx/access.log

# Verbose mode
./blueteam.sh --verbose /var/log/nginx/access.log

# Top N attackers
./blueteam.sh --top 50 /var/log/nginx/access.log

# Show help
./blueteam.sh --help
```

## Supported Log Formats

- Apache Combined Log Format
- Nginx Access Log Format
- Custom formats (with modification)

## Detection Patterns

### SQL Injection
- UNION SELECT, INSERT, DELETE, UPDATE, DROP statements
- OR/AND based injections
- Boolean-based blind injection
- Time-based blind injection
- Encoded payloads

### Remote Code Execution
- Command injection patterns
- System/Exec/Passthru functions
- Script interpreter invocations
- Network tools (wget, curl)
- Base64 encoded payloads
- JNDI injection (Log4Shell)

### XSS
- Script tag injection
- Event handlers (onerror, onload, etc.)
- URL encoding
- HTML entity encoding
- Unicode escaping

### Path Traversal
- Directory traversal patterns
- Encoded traversals
- Windows path traversal
- Sensitive file access attempts

## Threat Scoring

- **CRITICAL** (100 points each): SQLi, RCE, Backdoor, Log4Shell
- **HIGH** (50 points each): Brute Force, XSS, File Disclosure  
- **MEDIUM** (20 points each): Path Traversal, Enumeration
- **LOW** (5 points each): Scanner Activity

Risk Level:
- CRITICAL: Score > 1000
- HIGH: Score > 500
- MEDIUM: Score > 100
- LOW: Score <= 100

## Requirements

- Bash 3.2+
- Standard Unix utilities (awk, grep, sed, sort, uniq, wc)
- Terminal with color support (optional)

## Performance

The toolkit is optimized for large log files:
- Uses awk for efficient pattern matching
- Single-pass analysis where possible
- Temporary workspace for intermediate results
- Parallel detector execution

## Exit Codes

- 0: Successful execution
- 1: Error (invalid arguments, file not found, etc.)

## License

This tool is provided for defensive security purposes only.

## Author

Blue Team Security Toolkit v1.0.0
