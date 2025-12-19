---
layout: post
# author: "Epy Blog"
title: "OpenWebUI Pipelines <em><br> Getting Started, Setup, Pitfalls, and First Pipeline</em>"
tags:
  - OpenWebUI
  - LLMs
  - OpenRouter
usemathjax:     true
more_updates_card: false
giscus_term: openwebui-pipelines-getting-started
yt_community_link: false
excerpt_separator: <!--more-->
---

Open WebUI is not just a chat frontend for OpenAI-style APIs—it also supports **Pipelines**, a plugin framework that lets you add **custom logic, RAG workflows, filters, and integrations** directly into the system. <!--more-->

In this post, we’ll walk through everything you need to know to set up Pipelines locally (without Docker), configure them correctly, and run your very first pipeline—while also covering the common errors and fixes you’ll likely encounter along the way.


## What are Pipelines?

* **Pipelines = models you write yourself.** <br>
  Each pipeline is just a Python file placed into the `pipelines/` directory. It can appear in the chat dropdown like any model, or wrap existing models as a **filter**.

* Two main types:

  1. **Pipe** → Acts like a model. You select it in chat; it decides how to handle queries.
  2. **Filter** → Middleware that transparently wraps other models, editing requests/responses before/after they hit the model.

* **Why bother with Pipelines instead of just running a FastAPI RAG server?**
  Because Pipelines integrate tightly with WebUI:

  * Auto-discovery of new `.py` files
  * Configurable knobs (**valves**) in the Admin panel
  * Global wrappers across all models (filters)
  * Priority-based chaining of multiple filters

---

## Step 1: Prerequisites

Make sure you’re running the right environment:

* **Python 3.11** (the only officially supported version)
* **Conda/Anaconda** recommended to isolate dependencies
* **Open WebUI installed via pip** (`pip install open-webui`)
* An OpenAI-compatible key provider (e.g., OpenRouter) for pipelines that call LLMs

Check versions (if `open-webui` is installed in any Conda env other than base, please activate that env first and then run these commands):

```bash
python --version   # should be 3.11.x
pip show open-webui
```

---

## Step 2: Clone and Setup Pipelines

Clone the pipelines repository:

```bash
git clone https://github.com/open-webui/pipelines.git
cd pipelines
```

Create and activate a Conda environment:

```bash
conda create -n pipelines python=3.11 -y
conda activate pipelines
```

Install dependencies:

```bash
pip install -r requirements.txt
```


{% capture mycard %}

Our **PINNs Masterclass** helps you bridge the gap between theory and code — with crystal-clear walkthroughs, real examples, and zero guesswork.

{% endcapture %}

{% include promo-card-md.html
   heading="Physics Informed Neural Networks (PINNs) - Masterclass"
   body=mycard
   button_link="https://exly.co/PvxFUL"
   button_text="Enroll Now →"
%}




---

## Step 3: Fix Common Setup Errors

### 1. **Line endings (`dos2unix` issue)**

If you’re on Windows/WSL and get errors like:

```
cannot execute binary file: Exec format error
```

Run:

```bash
sudo apt install -y dos2unix
dos2unix start.sh
chmod +x start.sh
```

### 2. **`main.py` app not found**

If you see:

```
ERROR: Error loading ASGI app. Attribute "app" not found in module "main".
```

You’re not in the correct folder. Always run `start.sh` from the **pipelines repo root**.

### 3. **`No module named 'faiss'`** (or some other missing library)

If your pipeline uses FAISS (or someother libraries), install it:

```bash
pip install faiss-cpu
```
---

## 🛠️ Step 4: Configure Environment Variables

Before starting the Pipelines server, you should configure a few environment variables so that Open WebUI knows how to authenticate and where to look for your pipeline files.

### 1. Edit `.bashrc`

Open your shell config (`~/.bashrc` if you’re on bash, `~/.zshrc` if zsh):

```bash
nano ~/.bashrc
```

Add these lines at the end:

```bash
# API key that Open WebUI will use to connect to the Pipelines server.
# You can keep the default "0p3n-w3bu!" or choose your own.
export PIPELINES_API_KEY="0p3n-w3bu!"

# Directory where your pipeline .py files live.
# This must point to the *inner* pipelines folder inside the repo.
# Example if you cloned into /mnt/d/.../pipelines:
export PIPELINES_DIR="/mnt/d/OneDrive_2_3-18-2025/97-openwebui-tool-4/pipelines/pipelines/"

# Directory where Pipelines should look for requirements.txt.
# Default is ./pipelines, but set explicitly to avoid 'requirements.txt not found' warnings.
export PIPELINES_REQUIREMENTS_PATH="/mnt/d/OneDrive_2_3-18-2025/97-openwebui-tool-4/t2-implementation/pipelines/requirements.txt"
```

> 💡 **Note:** If you already run `pip install -r requirements.txt` manually when setting up your environment, you can skip setting `PIPELINES_REQUIREMENTS_PATH`. It’s only needed if you want the `start.sh` script to automatically install requirements on each run, or if you’re managing multiple pipeline folders with different `requirements.txt` files. 


Save and reload:

```bash
source ~/.bashrc
```

---

### 2. Why These Variables Matter

* **`PIPELINES_API_KEY`**

  * Shared secret between WebUI and Pipelines.
  * You’ll enter this same value in WebUI → Admin → Settings → Connections.

* **`PIPELINES_DIR`**

  * Pipelines auto-scan this folder for `.py` files.
  * If you cloned the repo into a folder named `pipelines`, your actual structure looks like this:

    ```
    /mnt/d/.../pipelines/            <-- repo root
    ├── start.sh
    ├── main.py
    ├── schemas.py
    └── pipelines/                   <-- THIS is the scan folder
        ├── hello_pipe.py
        ├── rate_limit_filter_pipeline.py
        └── ...
    ```

    ✅ Always point `PIPELINES_DIR` to the inner `pipelines/` directory (not the repo root).

* **`PIPELINES_REQUIREMENTS_PATH`**

  * Tells the server where to find `requirements.txt`.
  * Without it, you’ll see warnings like `requirements.txt not found`.

---

### 3. Verify

After setting these environment variables, **start (or restart) the Pipelines server** as explained in **Step 5**:

```bash
start or restart the server --> instructions in Step-5
```

If everything is correct, you should see logs like:

```
INFO:     Started server process
INFO:     Waiting for application startup.
Loaded module: hello_pipe
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:9099
```

And listing pipelines should work:

```bash
curl -s -H "Authorization: Bearer 0p3n-w3bu!" http://localhost:9099/pipelines | python -m json.tool
```

👉 With this step in place, you now have a stable foundation: pipelines auto-load correctly, dependencies are found, and WebUI can authenticate.


---

## Step 5: Start the Pipelines Server

From inside the `pipelines/` folder:

```bash
bash start.sh --mode run
```

You should see:

```
INFO:     Uvicorn running on http://0.0.0.0:9099
```

That’s your **pipelines server**.

> 💡 **Note:** If you already run `pip install -r requirements.txt` manually and **don’t specify `PIPELINES_REQUIREMENTS_PATH` in `.bashrc`**, you will still see a message like `PIPELINES_REQUIREMENTS_PATH not specified. Skipping installation of requirements.` when starting the server. That’s completely fine — as long as you’ve installed the requirements upfront and continue maintaining/updating the required libraries in your environment from time to time.


---

## Step 6: Connect Pipelines to Open WebUI

1. Go to **Admin Panel → Settings → Connections** in Open WebUI.
2. Toggle ON `OpenAI API` (it should turn green).
2. Click `+` and Add a new connection:

   * **API URL** → `http://localhost:9099`
   * **API key** → `0p3n-w3bu!` (default) - You can change this to any string you like, but if you do, make sure to also update the same value in your `~/.bashrc` (where you set `PIPELINES_API_KEY`). Both WebUI and the Pipelines server must use the same key.
3. Save and verify. You’ll see a small **Pipelines** icon next to the connection if it’s detected.

---

## Step 7: Run Your First Pipeline

Pipelines auto-load any `.py` file inside the `pipelines/` folder.

Example: `hello_pipe.py`

```python
"""
title: Hello Pipeline
type: pipe
"""

from typing import List, Union, Generator
from pydantic import BaseModel

class Valves(BaseModel):
    # put any knobs you want here; defaults are fine
    greeting: str = "Hello"

class Pipeline:
    def __init__(self):
        self.valves = Valves()

    async def on_startup(self):
        pass

    async def on_shutdown(self):
        pass

    def pipe(self, user_message: str, model_id: str, messages: list, body: dict) -> str:
        return f"{self.valves.greeting}! You said: {user_message}"

```

Steps:

1. Save this file in the inner pipelines directory `./pipelines/hello_pipe.py`.
2. Restart pipelines:

   ```bash
   bash start.sh --mode run
   ```
3. In Open WebUI chat, select **hello\_pipe** as the model.
4. Type anything → it should echo back with a 👋.

---

## Step 8: Understanding Filters

Try a filter pipeline (e.g., auto-translate):

* Unlike a pipe, you **don’t select it in chat**.
* Instead, it runs **around any model you pick**.

So if you enable `libretranslate_filter.py`, you can still choose `DeepSeek` or `Claude` in chat, but all requests/responses will be translated automatically.

Great idea 👍 — a lot of confusion comes from `--mode run` vs `--mode full`. Here’s a clear point you can drop right into your setup guide:

---

### Understanding Modes (`--mode run` vs `--mode full`)

When starting Pipelines with `start.sh`, you can specify the mode:

* **`--mode run`**

  * Skips setup steps.
  * Only **runs the server** using whatever pipelines and dependencies are already present.
  * Faster, ideal once your environment is stable.

* **`--mode full`**

  * Runs **setup + run**.
  * Does three things:

    1. Installs dependencies from `requirements.txt` (or from each pipeline’s `requirements` in frontmatter).
    2. Downloads pipelines listed in `PIPELINES_URLS` (if configured).
    3. Then starts the server.
  * Useful when:

    * You just cloned the repo,
    * You added a new pipeline with extra requirements,
    * Or you want a “clean slate” reset (`RESET_PIPELINES_DIR=true`).

👉 In practice:

* Use `--mode run` for normal day-to-day running.
* Use `--mode full` the first time or whenever you add new pipelines/dependencies. (If you’re comfortable managing dependencies yourself (`pip install -r requirements.txt` manually), **I recommend avoiding `--mode full` entirely** — it may reinstall or override packages each run.)

---

## Lessons Learned from Setup Errors

From real setup attempts:

* **Wrong folder** → `main.app not found` error
* **Windows line endings** → `dos2unix` fixes
* **Missing deps** → Pipelines don’t install extras automatically; add them with `pip install`
* **Confusion about model dropdown**:

  * Pipes show up as *models* you can select.
  * Filters run transparently over whatever model you already select.

---

## Conclusion

Pipelines add a whole new dimension to Open WebUI:

* Write your own **pipe** to build RAG, query decomposition, or tool orchestration.
* Write your own **filter** to apply global policies like redaction, logging, translation.
* All with hot-plug `.py` files, valves for live tuning, and no separate UI coding.

👉 If you just want a simple standalone backend, a FastAPI server is enough.

👉 If you want **tight integration with Open WebUI**, pipelines are the way forward.


{% capture mycard %}

Our **PINNs Masterclass** helps you bridge the gap between theory and code — with crystal-clear walkthroughs, real examples, and zero guesswork.

{% endcapture %}

{% include promo-card-md.html
   heading="Physics Informed Neural Networks (PINNs) - Masterclass"
   body=mycard
   button_link="https://exly.co/PvxFUL"
   button_text="Enroll Now →"
%}