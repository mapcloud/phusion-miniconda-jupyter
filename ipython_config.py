## Configuration file for ipython.
## The docker container will read from this working directory, so volumes in host
## that want to have their packages available in the container should point to this
## docker -v $(pwd):/opt/notebooks
c.InteractiveShellApp.exec_files = ['import sys; sys.path.append("/opt/notebooks/")']
