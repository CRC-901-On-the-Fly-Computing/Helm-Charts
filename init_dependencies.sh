# script to recursively update helm dependencies

echo "===== Dependency Script ====="
echo "    Updating dependencies"
echo "============================="

# Find: all files with the name requirements.yaml, sed strips off the file name and leaves the directory, sort -u sorts and removes doubles
for D in $(find . -type f -name 'requirements.yaml' | sed -r 's|/[^/]+$||' |sort -u)
do
    echo "Updating ${D}"   # your processing here
    cd $D
    helm dependency update
    cd -
done
