# <h1 align="center"> An EigenLayer AVS 🌐 </h1>

**A simple Hello World AVS for EigenLayer with the ECDSA-based Contract Configuration**

## 📚 Prerequisites

Before you can run this project, you will need to have the following software installed on your machine:

- [Rust](https://www.rust-lang.org/tools/install)
- [Forge](https://getfoundry.sh)

You will also need to install [cargo-tangle](https://crates.io/crates/cargo-tangle), our CLI tool for creating and
deploying Blueprints:

To install the Tangle CLI, run the following command:

> Supported on Linux, MacOS, and Windows (WSL2)

```bash
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/tangle-network/gadget/releases/download/cargo-tangle-v0.1.2/cargo-tangle-installer.sh | sh
```

Or, if you prefer to install the CLI from crates.io:

```bash
cargo install cargo-tangle --force # to get the latest version.
```

## 🚀 Getting Started

Once `cargo-tangle` is installed, you can create a new project with the following command:

```bash
cargo tangle blueprint create --name <project-name> --eigenlayer <type>
```
where `<project-name>` is the name of the project that will be generated, and `<type>` is BLS or ECDSA. This is the ECDSA 
version of the template, so you could run the following command to generate an ECDSA-based project called `ecdsa-test`:

```bash
cargo tangle blueprint create --name ecdsa-test --eigenlayer ECDSA
```

Upon running the above command, you will be prompted with questions regarding the setup for your generated project. If you aren't sure for any of them, you can just hit enter to select the default for that questions. 

### Note
If you choose to use `foundry.toml` for the Soldeer configuration (the default), you will need to delete the following files from the `contracts` directory:
- `foundry.toml`
- `remappings.txt`
- `soldeer.lock`

This will allow the generated project to work out of the box. This will be fixed in the future, so that nothing needs to be deleted.

## 📚 Overview

This project is about creating a simple Hello World AVS for EigenLayer.
An AVS (Actively Validated Service) is an off-chain service that runs arbitrary computations for a user-specified period of time.

## 📜 License

Licensed under either of

* Apache License, Version 2.0
  ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
* MIT license
  ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## 📬 Feedback and Contributions

We welcome feedback and contributions to improve this blueprint.
Please open an issue or submit a pull request on
our [GitHub repository](https://github.com/tangle-network/blueprint-template/issues).

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.
