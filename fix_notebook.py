from nbformat import v4, write
from nbformat.v4 import new_notebook, new_code_cell

nb = new_notebook(cells=[
    new_code_cell("print('Notebook ran successfully!')")
])

with open("my-notebook-project/notebooks/my_analysis.ipynb", "w") as f:
    write(nb, f)
