import subprocess
import sys
 
subprocess.run(["npm", "run", "build"], cwd="frontend", check=True) 