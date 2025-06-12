git add -A
git commit -m "Notebook CI/CD setup"
git push origin main
if [ $? -eq 0 ]; then
    echo "Changes pushed successfully."
else
    echo "Failed to push changes."
fi
# Check if the script is being run in a git repository
if [ ! -d .git ]; then
    echo "This script must be run in a git repository."
    exit 1
fi
# Check if there are any changes to commit
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit."
    exit 0
fi