

# Chromium Development Environment Setup Scripts

This project provides a set of shell scripts to automate the setup of a complete Chromium development environment on **Ubuntu 24.04**. These scripts streamline the process of installing necessary tools, downloading the Chromium source code, and configuring the development environment, saving you time and effort.

## Features

- **Automated Installation**: Fully automates the setup of a Chromium development environment.
- **Highly Customizable**: Use the `defconfig.sh` file to tailor the installation to your specific needs, including which tools to install and how to configure the environment.
- **Comprehensive Tooling**: Installs a wide range of essential development tools, including:
  - Google Chrome Browser
  - Visual Studio Code (with recommended extensions)
  - Notepad++
  - Tabby Terminal
  - Minicom & Picocom
  - Meld (Diff & Merge Tool)
  - GParted (Partition Editor)
  - And many more!


## Prerequisites

- **Operating System**: Ubuntu 24.04 LTS is required. While newer versions may work, they are not officially supported.
- **Internet Connection**: A stable internet connection is required to download the necessary files and source code.

## Getting Started

To get started, simply download and run the main installation script. Open your terminal and execute the following commands:

```bash
# Download the main installation script
wget https://raw.githubusercontent.com/yuansco/scripts/main/chrome_auto_install.sh

# Make the script executable
chmod +x ./chrome_auto_install.sh

# Run the script
./chrome_auto_install.sh

# Reboot the system to apply all changes
reboot
```

The script will guide you through the rest of the process.

## Configuration

Before the main installation begins, the script will download a `defconfig.sh` file. This file allows you to customize the installation by setting various options. You can edit this file to:

- Set your Git username and email.
- Choose which development tools and applications to install.
- Configure the Chromium source code branch and repository settings.
- Enable or disable features like the Docker-based Servod setup.

Simply open the `defconfig.sh` file in a text editor, modify the options as needed, and save the file. The installation will proceed with your custom configuration.

## Scripts Overview

This project consists of the following scripts:

- **`chrome_auto_install.sh`**: The main script that orchestrates the entire setup process.
- **`install_chrome_dev_environment.sh`**: Performs the bulk of the installation, including installing tools and setting up the Chromium source code.
- **`defconfig.sh`**: The configuration file for the installation.


