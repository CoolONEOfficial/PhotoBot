

<p align="center"><img width=200 src="logo.png" alt="Vkontakter logo"></p>

# PhotoBot

PhotoBot is chatbot for photographers and other people related to photography.

[![MacOS and Linux build](https://github.com/CoolONEOfficial/PhotoBot/actions/workflows/swift.yml/badge.svg)](https://github.com/CoolONEOfficial/PhotoBot/actions/workflows/swift.yml)
[![Language](https://img.shields.io/badge/language-Swift%205.1-orange.svg)](https://swift.org/download/)
[![Platform](https://img.shields.io/badge/platform-Linux%20/%20macOS-ffc713.svg)](https://swift.org/download/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/CoolONEOfficial/Vkontakter/blob/master/LICENSE)

<p align="center"><img width=200 src="macstadium.png" alt="MacStadium logo"></p>

What does it do
---------------

PhotoBot is chatbot for photographers and other people related to photography. That bot allows clients to create orders, see portfolio, reviews and so on.
It was built on top of [Botter](https://github.com/CoolONEOfficial/botter) framework

## Get started

### Create .env or .env.development with:

```env
DATABASE_URL=postgresql://USERNAME@localhost/DB_NAME
TG_BOT_TOKEN=...
VK_GROUP_TOKEN=...
VK_ADMIN_NICKNAME=...
TG_ADMIN_NICKNAME=...
VK_BUFFER_USER_ID=...
TG_BUFFER_USER_ID=...
VK_GROUP_ID=... (Optional)
VK_NEW_SERVER_NAME=... (Optional)
TARGET_PLATFORM=... (Optional)
VK_PORT and TG_PORT or PORT=... (Optional)
WEBHOOKS_URL=... (Optional)
```

Documentation
---------------

- Read [our wiki](https://github.com/CoolONEOfficial/PhotoBot/wiki)
- Read [Botter documentation](https://github.com/CoolONEOfficial/Botter)
- Read [An official documentation of Vapor](https://docs.vapor.codes/4.0/)

Requirements
---------------

- Ubuntu 16.04 or later with [Swift 5.1 or later](https://swift.org/getting-started/) / macOS with [Xcode 11 or later](https://swift.org/download/)
- Vk account and a Vk App for mobile platform or online (desktop client does not support some chatbot features)
- [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md) for dependencies 
- [Vapor 4](https://vapor.codes)

Contributing
---------------

See [CONTRIBUTING.md](CONTRIBUTING.md) file.

Author
---------------

Nikolai Trukhin

[coolone.official@gmail.com](mailto:coolone.official@gmail.com)
[@cooloneofficial](https://t.me/cooloneofficial)

