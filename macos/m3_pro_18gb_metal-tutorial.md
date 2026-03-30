# Local LLMs on macOS (Apple Silicon)

This guide provides step-by-step instructions to get a Large Language Model running locally on your Accenture Mac using 
[llama.cpp](https://github.com/ggerganov/llama.cpp). 

llama.cpp is the open-source foundation of popular local LLM tools like [Ollama](https://ollama.com/download) and [LM Studio](https://lmstudio.ai/) with zero restrictions on commerical distribution. 

New features, updates and bugfixes are available first in llama.cpp and new [Hugging Face](https://huggingface.co/) models are typically available within hours (instead of weeks/months).

We'll focus on setting up a local LLM server, optimising that for Apple silicon and finally making it easily accessible from any prototyping project with a single system-wide command.

This guide uses exclusively Terminal commands; you can find Terminal in Applications → Utilities, or search for it with Spotlight using `Cmd + Space` and is optimised for Apple Silicon Macs (M1/M2/M3/M4) which benefit from Metal GPU acceleration. 

## Prerequisites

Before starting this, make sure you have the following:

- **macOS** on an Apple Silicon Mac (M1, M2, M3, or M4). Check your hardware with About This Mac under the Apple symbol in the top left of your screen.

- **Homebrew**, check if it is installed by running `brew` in Terminal, if the command is not found, install it by running:
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- **SSH Key Authentication with GitHub**, if you haven't done this before, follow [this official guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).


## 1. Folder Structure

Open **Terminal**.

First, create two directories: one for git repositories and one for storing model files. Everything is based on the home folder for robustness and repeatability.

```bash
mkdir ~/git
mkdir ~/.models
```

`~/git` stores any cloned repositories.
`~/.models` stores downloaded models from HuggingFace (the `.` prefix makes it a hidden folder to keep your home directory tidy).

## 2. Clone Repository

Navigate into the git folder:

```bash
cd ~/git
```

And clone the project repository:

```bash
cd ~/git
git clone git@github.com:mholubinkamudano/acn-local-llm.git
```

This downloads the project files, including the server startup script we'll use later.

## 3. System Dependencies

First, we update Homebrew to make sure we have the latest package versions and definitions:

```bash
brew update
brew upgrade
```

Then install the required tools:

```bash
brew install cmake python
```
**python** is required for installing the huggingface-hub packages and interacting with our locally deployed model.
**cmake** is the build tool needed to compile llama.cpp from source and make use of the Metal GPU acceleration.

## 4. Virtual Environment Set Up

A virtual environment keeps Python packages isolated from the rest of the system. Let's create a local LLM specific virtual environment that we can share across Python projects for easy and quick prototyping.

Create and activate it:

```bash
python3 -m venv ~/llama-venv
source ~/llama-venv/bin/activate
```

After activation, the terminal prompt changes to show `(llama-venv)` at the start, to show that you're working inside the virtual environment.

When turning a prototype into a production release candidate or expanding it beyond the initial development phase, create a unique virtual environment to manage the required packages for just that project with pinned versions and minimal dependencies.

Now, upgrade pip (Python's package manager) to the latest version:

```bash
pip3 install --upgrade pip
```

## 5. Download LLM from Hugging Face

First install the Hugging Face Hub CLI tool, which lets us download models from [Hugging Face](https://huggingface.co/):

```bash
pip3 install huggingface-hub
```

We're going to use the Llama 3.1 8B model. This is a quantised, compressed, version that will run well on a machine with 16GB of RAM:

```bash
hf download bartowski/Meta-Llama-3.1-8B-Instruct-GGUF \
  Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf \
  --local-dir ~/.models
```

> **Note:** This download is approximately 5GB. It may take a while depending on your internet connection.

## 6. Build llama.cpp

llama.cpp is the engine that will run our downloaded model. We're going to compile it from source with Metal (Apple GPU) support enabled for best performance on our hardware.

First, clone the llama.cpp repository and navigate to it:

```bash
cd ~/git
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
```
Next, compile and then configure the model for release. We're going to use all available CPU cores to speed this up.

```bash
cmake -B llama-cpp-metal -DGGML_METAL=ON
cmake --build llama-cpp-metal --config Release -j $(sysctl -n hw.ncpu)
```

This command will take a few minutes to finish. When it completes, our server binary will be found at `~/git/llama.cpp/llama-cpp-metal/bin/llama-server`.

## 7. Set up the single-command launcher

This repository includes a startup script that launches the LLM as a local server. 

First, make it executable:

```bash
chmod +x ~/git/acn-local-llm/macos/scripts/activate.sh
```

Nom, we create a system-wide alias so that this command can be executed anywhere by adding a shortcut to our shell configuration.

```bash
echo 'alias local-llm="~/git/acn-local-llm/macos/scripts/activate.sh"' >> ~/.zshrc
```

Finally, reload the shell configuration to make the alias available to us.

```bash
source ~/.zshrc
```

## 8. Launch our local LLM

From any terminal window type:

```bash
local-llm
```

This start's the llama.cpp server and provides an OpenAI-compatible API available at:

```
http://localhost:8080/v1
```

To stop the server, press `Ctrl+C` in the terminal window.

## Updating llama.cpp

llama.cpp is in constant active development and is updated frequently. To take advantage of these updates and improvements in local execution, we perform a full, clean rebuild:

```bash
cd ~/git/llama.cpp
git pull origin master
rm -rf llama-cpp-metal
cmake -B llama-cpp-metal -DGGML_METAL=ON
cmake --build llama-cpp-metal --config Release -j $(sysctl -n hw.ncpu)
```

`rm -rf llama-cpp-metal` fully removes our old build to avoid any stale cache issues. We store the model files separately in `~/.models` so that they are not affected.

## Example API Usage with Python

With the server running in one terminal, open VS Code and activate our systemwide prototyping environment:

```bash
source ~/llama-venv/bin/activate
```

Running our LLM locally, is the first step in rapid, cheap and secure agent prototyping. Let's test our new LLM server using the [Langchain Agent Framework](https://www.langchain.com/) in Python.

Install the required packages:

```bash
pip3 install langchain langchain-openai
```

And write an executable Python script to test our server:

```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatOpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed",
    model="llama-3.1-8b",
    temperature=0.7,
)

response = llm.invoke([
    SystemMessage(content="You are a helpful assistant specialised in Agentic Business Transformation. Provide all answers in Markdown."),
    HumanMessage(content="Generate a project plan for putting a Python-based AI Agent into production.")
])

print(response.content)
```

## Troubleshooting

**Server starts but responses are very slow**
Check that Metal GPU offloading is working. The server logs should mention Metal on startup. Make sure you built with `-DGGML_METAL=ON` and are running with `-ngl 99`.

**Out of memory errors**
Close memory-heavy apps (browsers, IDEs). Apple Silicon uses unified memory shared between the CPU and GPU, so every GB counts. If issues persist, try reducing context size by changing `-c 4096` to `-c 2048` in the startup script.

**Model not found error on startup**
Verify the model file exists at `~/.models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf`. If the download was interrupted, re-run the `hf download` command — it will resume where it left off.
