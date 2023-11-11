'''
Goal: Create a Python script that will automatically push to Github but check all files in the 
current directory for sensitive 
information such as AWS secret keys and AWS access keys and will return back to the 
terminal a message saying what document the sensitive information is in and 
what the sensitive information is. Also, it stops the script from being pushed to GitHub
'''

# Import Modules
import os
import subprocess
import re

# Create a function that finds access_key and secret_key variables in file content
def filecontentchecker(filecontent):
    aws_key_pattern = re.compile(r'(?i)(access_key|secret_key)\s*=\s*[\'"]?([\w\/+=]+)[\'"]?')
    findmatches = re.findall(aws_key_pattern, filecontent)
    return findmatches

# Define paths
rootdirectory = "/home/ubuntu/deployment6"
gitignore = "/home/ubuntu/deployment6/.gitignore"

# Check if .gitignore file exists, if not create a file
if os.path.exists(gitignore):
    print("File exists")
else:
    with open(".gitignore", "w"):
        pass

# Iterate through the local repository and see if the file has access_key and secret_key variables with a specific patterns
for root, _, files in os.walk(rootdirectory):
    for filename in files:
        filepath = os.path.join(root, filename)
        with open(filepath, "r", errors = "ignore") as file:
            filecontent = file.read()
            filesearch = filecontentchecker(filecontent)
            if bool(filesearch) == 1:
                access = re.compile(r'^[A-Z0-9]{20}$')
                secret = re.compile(r'^[A-Za-z0-9/+=]{40}$')
                # Print out the the name of the path and the sensitive information
                if access.match(filesearch[0][1]) or secret.match(filesearch[1][1]):
                    print(f"The file {filepath} contains {filesearch}")
                    # Append the files with sensitive information to .gitignore file
                    with open(gitignore, "a") as gitignorefile:
                        gitignorefile.write(f'\n{filepath}\n')

# Push files and .gitignore file up to Github repository
try:
    subprocess.run(["git", "push", "origin", "main"], check=True)
except subprocess.CalledProcessError as error:

