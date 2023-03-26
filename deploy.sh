echo "Switching to branch main"
git checkout main

echo "Building app..."
yarn build

echo "Deploying files to server..."
scp -r dist/* grosh@51.250.51.225:/var/www/groshidze/dist

echo "Done!"

# 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
#        mkdir -p ~/.ssh
#        echo "$SSH_PRIVATE_KEY" | tr -d '\r' > ~/.ssh/id_ed25519
#        chmod 700 ~/.ssh/id_ed25519
#        eval "$(ssh-agent -s)"
#        ssh-add ~/.ssh/id_rsa
#        ssh-keyscan -t rsa 158.160.30.152 > ~/.ssh/known_hosts
#        echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
#        chmod 644 ~/.ssh/known_hosts
#        ls
#        echo "Switching to branch main"
#        git checkout main
#        echo "Init deps..."
#        yarn install
#        echo "Building app..."
#        yarn build
#        echo "Deploying files to server..."
#        scp -r dist/* grosh@158.160.30.152:/var/www/groshidze/dist
#        echo "Done!"
