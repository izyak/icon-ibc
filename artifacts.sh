#!/bin/bash 

rm -rf artifacts
mkdir artifacts
cd artifacts

if [ -z "$1" ]; then
  echo "Please provide version of contracts to deploy"
  exit 0
else
  echo "IBC Version selected: $1"
  ibc_version="$1"
  echo "Xcall Version selected: $2"
  xcall_version="$2"
fi

curl -L https://api.github.com/repos/icon-project/IBC-Integration/releases | grep $ibc_version | grep browser_download_url > urls.txt
curl -L https://api.github.com/repos/icon-project/xcall-multi/releases | grep $xcall_version | grep browser_download_url >> urls.txt

urls=()

while IFS= read -r line; do
  if [[ $line == *"browser_download_url"* ]]; then
    url="${line##*browser_download_url\": \"}"
    url="${url%"\""}"
    urls+=("$url")
  fi
done < "urls.txt"
rm urls.txt

# download assets
for url in "${urls[@]}"; do
  curl -O "$url"
done


for file in *; do
  if [[ -f "$file" ]]; then
    # Remove version numbers and "optimized" from the filename
    new_name=$(echo "$file" | sed -E 's/(_[0-9]+\.[0-9]+\.[0-9]+|-[0-9]+\.[0-9]+\.[0-9]+-optimized)//g')

    # Rename the file
    if [ "$file" != "$new_name" ]; then
      mv "$file" "$new_name"
      echo "Renamed $file to $new_name"
    fi
  fi
done

cd ..