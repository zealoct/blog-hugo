echo "Cleaning /public directory"
cd public/
git rm *
cd ..

echo "Building new pages"
hugo_0.14_windows_amd64.exe --theme=hyde-x
copy CNAME public\
copy robots.txt public\

echo "Git commit"
cd public/
git add .
git commit -am "Site updated"

echo "Check we are on the right remote"
git remote show origin

echo "Pushing to Github"
git push