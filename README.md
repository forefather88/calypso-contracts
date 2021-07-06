# Here is my guide on deploying our upgradable smart contracts with truffle.

Preparation:
1. Install truffle compiler with npm "install -g truffle" command;
2. Go to https://infura.io/dashboard/ethereum and generate an API key for Kovan network;
3. In truffle-config.js file input your endpoint "wss://kovan.infura.io/ws/v3/your_api_key"
4. Generate an API Key on your Etherscan account on https://etherscan.io/apis;
5. In the root folder create ".env" file with "KOVANAPI = 'YOUR_API_KEY'" line (this one will be needed for verifying SC on the Etherscan);
6. In the root folder create "metamask.txt" file and print your metamask account mnemonic;

Deploying and upgrading:
1. Read carefully how to write and make changes in upgradable SC's on https://docs.openzeppelin.com/upgrades-plugins/1.x/;
2. Make changes in a smart contract;
3. Put the migration file in the migrations folder. Always keep 1_initial_migration.js in migrations folder and make sure that it will be the first file by name;
4. I suggest deploying and upgrading SC's one by one, so the migrations of SC's that won't be deployed or upgraded should be stored in NO_DEPLOY folder;
5. If you are deploying an SC, uncomment Deploy section in a migration file and comment Upgrade section. If you are upgrading - do the opposite;
6. Make sure that the build folder is deleted, for some reason it won't work if the folder exists. SC's will be re-compiled in any case;
7. Run "npx truffle migrate --network kovan" command in a terminal. After after upgrading the contract it's address won't be changed!
