#!/bin/bash

set -ex

echo "Cleaning /public directory"
cd zealoct.github.io/
git rm -r *
cd ..

echo "Building new pages"
hugo --theme=hugo-classic

cp CNAME zealoct.github.io/
cp robots.txt zealoct.github.io/

echo "Git commit"
cp -r public/* zealoct.github.io/
cd zealoct.github.io/
git add .
git commit -am "Site updated"

echo "Check we are on the right remote"
git remote show origin

echo "Pushing to Github"
git push

cd ..
