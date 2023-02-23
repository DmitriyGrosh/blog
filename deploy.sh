echo "Switching to branch main"
git checkout main

echo "Building app..."
yarn build

echo "Deploying files to server..."
scp -r dist/* grosh@158.160.30.152:/var/www/groshidze/dist

echo "Done!"
