# Jupyter Notebook CI/CD Deployment to EC2

This repository contains a GitHub Actions CI/CD pipeline that runs a Jupyter notebook using **Papermill**, then deploys the executed notebook output to a remote EC2 instance. The pipeline includes Slack notifications for success, failure, and unstable statuses.

---

## 📁 Project Structure

```
.
├── my-notebook-project
│   └── notebooks
│       └── my_analysis.ipynb
├── output
│   └── my_analysis_output.ipynb (generated)
├── test-images
│   └── (your test images here)
├── .github
│   └── workflows
│       └── deploy-notebook.yml
├── requirements.txt
└── README.md
```

---

## Prerequisites

- An AWS EC2 instance with SSH access
- GitHub repository with secrets configured (see below)
- Python 3.10 environment for running the notebook locally or on CI
- The following Python packages installed (also listed in `requirements.txt`):
  - `jupyter`
  - `papermill`
  - `nbconvert`
  - `nbformat`

---

## GitHub Secrets Configuration

Set the following secrets in your GitHub repository:

- `EC2_HOST` — Public IP or DNS of your EC2 instance
- `EC2_KEY` — Your private SSH key for accessing EC2 (PEM format)
- `SLACK_WEBHOOK_URL` — Slack Incoming Webhook URL for notifications

---

## How It Works

1. On push to the `main` branch, triggered only if files under `notebooks/` or the workflow file `.github/workflows/deploy-notebook.yml` are changed.
2. The pipeline:
   - Checks out the repo
   - Sets up Python 3.10
   - Installs dependencies from `requirements.txt`
   - Runs the notebook `my-notebook-project/notebooks/my_analysis.ipynb` using Papermill, saving output in `output/my_analysis_output.ipynb`
   - Copies the output notebook to the EC2 server using SCP
   - Sends Slack notifications based on the job outcome

---

## Usage

### Running Locally

If you want to generate or fix your notebook file programmatically (to avoid JSON formatting errors like `NameError: name 'null' is not defined`), use the provided Python helper script:

```python
# fix_notebook.py
from nbformat import write
from nbformat.v4 import new_notebook, new_code_cell

nb = new_notebook(cells=[
    new_code_cell("print('Notebook ran successfully!')")
])

with open("my-notebook-project/notebooks/my_analysis.ipynb", "w") as f:
    write(nb, f)
```

Run this script:

```bash
pip install nbformat
python fix_notebook.py
```

This will produce a valid notebook JSON format compatible with Papermill.

### Running the CI/CD Pipeline

Just push changes to your notebooks or workflow file on the `main` branch, and the GitHub Actions workflow will execute automatically.

---

## Troubleshooting

### Papermill Execution Errors

- **Error:** `NameError: name 'null' is not defined`

  This error means the notebook JSON contains `null` instead of Python's `None` or the notebook file is malformed.

  **Fix:** Recreate the notebook properly with `nbformat` as shown in `fix_notebook.py`. Do **not** edit the notebook JSON manually using a text editor.

### Python Module Not Found: `nbformat`

- If you see `ModuleNotFoundError: No module named 'nbformat'` while running `fix_notebook.py`:

  Run:

  ```bash
  pip install nbformat
  ```

  This installs the package needed to create or fix notebooks programmatically.

---

## Requirements File (`requirements.txt`)

```txt
jupyter
papermill
nbconvert
nbformat
```

---

## GitHub Actions Workflow (`.github/workflows/deploy-notebook.yml`)

(Your workflow YAML as provided, handling notebook execution, SCP to EC2, and Slack notifications)

---

## 📡 Slack Integration

Slack notifications are triggered based on job status:
- ✅ Success
- ❌ Failure
- ⚠️ Unstable (cancelled/skipped)

---

## 🔧 How to Run the Notebook in Browser (Local EC2 Access)

1. SSH into your EC2 instance:
   ```bash
   ssh -i /path/to/key.pem ubuntu@<EC2_PUBLIC_IP>
   ```

2. Install Jupyter and Matplotlib if not present:
   ```bash
   pip install jupyter matplotlib
   ```

3. Run Jupyter Notebook and make it accessible from the browser:
   ```bash
   jupyter notebook --no-browser --ip=0.0.0.0 --port=8888
   ```

4. Open the notebook in your browser:
   ```
   http://<EC2_PUBLIC_IP>:8888
   ```
   > You'll need the token printed in your SSH terminal output to log in.

---

## 🧪 Sample Test Code for Notebook

Paste this codes into a notebook cells to verify it works:

1. Basic Print
```python
print("Hello, Jupyter is working!")
```
2. Simple Arithmetic
```python
a = 10
b = 5
print("Sum:", a + b)
print("Product:", a * b)
```
3. Python Loop
```python
for i in range(5):
    print(f"Count {i}")
```
4. Define and Use a Function
```python
def greet(name):
    return f"Hello, {name}!"

print(greet("Cyprien"))
```
5. Simple Plot with Matplotlib
```python
import matplotlib.pyplot as plt

x = [1, 2, 3, 4]
y = [10, 20, 25, 30]

plt.plot(x, y)
plt.title("Sample Plot")
plt.xlabel("X-axis")
plt.ylabel("Y-axis")
plt.show()
```

---

## How to Run These:

1. Open your Jupyter notebook in the browser (via the URL and token).
2. Create a new notebook or open your existing one.
3. Copy-paste each code snippet into a separate cell.
4. Press Shift + Enter to run the cell.
5. Check the output below each cell.

You can also refer to the test-images folder that content all the images related to the test of this project here.
[test-images](https://github.com/cyprientemateu/github-action/blob/main/my-notebook-project/notebooks/test-images)

---

## ✅ Troubleshooting Summary

- **ModuleNotFoundError: matplotlib**  
  Cause: Jupyter kernel environment missing module.  
  Fix: Run `!pip install matplotlib` on the Jupyter notebook itself.

              ### Or  

- **ModuleNotFoundError: matplotlib**  
  Cause: Jupyter kernel environment missing module.  
  Fix: Run `pip install matplotlib` on the EC2 instance.

- **Can't see pasted content in Jupyter cell**  
  Cause: Sometimes browser/editor-related glitch.  
  Fix: Refresh the browser or restart Jupyter server.

---

## Contact & Support

For questions or issues, please open an issue in this repository.

---
