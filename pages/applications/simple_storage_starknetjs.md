# Simple Storage (Starknet-js + Cairo)

In this example, we will use a SimpleStorage Cairo contract deployed on Starknet Sepolia Testnet and show how you can interact with the contract using Starknet-js.

## Writing SimpleStorage contract in Cairo

The SimpleStorage contract has only one purpose: storing a number. We want the users to interact with the stored number by **writing** to the currently stored number and **reading** the number in the contract.

We will use the following SimpleStorage contract. In the [Storage Variables](/getting-started/basics/variables) page, you can find explanations for each component of the contract:

```cairo
// [!include ~/listings/applications/simple_storage_starknetjs/src/storage.cairo:contract]
```

Because we want to interact with the get and set functions of the SimpleStorage contract using Starknet-js, we define the function signatures in `#[starknet::interface]`. The functions are defined under the macro `#[abi(embed_v0)]` where external functions are written.

Only deployed instances of the contract can be interacted with. You can refer to the [How to Deploy](/getting-started/interacting/how_to_deploy) page. Note down the address of your contract, as it is needed for the following part.

## Interacting with SimpleStorage contract

We will interact with the SimpleStorage contract using Starknet-js. Firstly, create a new folder and inside the directory of the new folder, initialize the npm package (click Enter several items, you can skip adding the package info):

```bash [Terminal]
npm init
```

Now, `package.json{:md}` file is created. Change the type of the package to a module.

```json
"type": "module"
```

Let's add Starknet-js as a dependency:

```bash [Terminal]
npm install starknet@next
```

Create a file named `index.js{:md}` where we will write JavaScript code to interact with our contract. Let's start our code by importing from Starknet-js, and from other libraries we will need:

```js
// [!include ~/listings/applications/simple_storage_starknetjs/index.js:imports]
```

Let's create our provider object, and add our account address as a constant variable. We need the provider in order to send our queries and transactions to a Starknet node that is connected to the Starknet network: 

```js
// [!include ~/listings/applications/simple_storage_starknetjs/index.js:provider]
const accountAddress = // 'PASTE_ACCOUNT_ADDRESS_HERE';
```

The next step is creating an `Account` object that will be used to sign transactions, so we need to import the account private key. You can access it directly from your keystore with the following command using Starkli: 

```bash [Terminal]
starkli signer keystore inspect-private /path/to/starkli-wallet/keystore.json --raw
```

Create a `.env{:md}` file in your project folder, and paste your private key as shown in the following line:

```bash [Terminal]
// [!include ~/listings/applications/simple_storage_starknetjs/.env.example]
```

:::warning
Using `.env{:md}` files is not recommended for production environments, please use `.env{:md}` files only for development purposes! It is HIGHLY recommended to add `.gitignore{:md}`, and include your .env file there if you will be pushing your project to GitHub.
:::

Now, import your private key from the environment variables and create your Account object.
```js
const accountAddress = // 'PASTE_ACCOUNT_PUBLIC_ADDRESS_HERE';
// [!include ~/listings/applications/simple_storage_starknetjs/index.js:account]
```

Now, let's create a Contract object in order to interact with our contract. In order to create the Contract object, we need the ABI and the address of our contract. The ABI contains information about what kind of data structures and functions there are in our contract so that we can interact with them using SDKs like Starknet-js. 

We will copy `./target/simple_storage_SimpleStorage.contract_class.json{:md}` to `abi.json{:md}` in the Scarb project folder. The beginning of the content of the ABI file should look like this: 

```json
{"sierra_program":["0x1","0x5","0x0","0x2","0x6","0x3","0x98","0x68","0x18", //...
```

We can then create the Account object and the Contract object in our `index.js{:md}` file:

```js
const contractAddress = 'PASTE_CONTRACT_ADDRESS_HERE';
// [!include ~/listings/applications/simple_storage_starknetjs/index.js:contract]
```

The setup is finished! By calling the `fn get(self: @ContractState) -> u128` function, we will be able to read the `stored_data` variable from the contract:

```js
// [!include ~/listings/applications/simple_storage_starknetjs/index.js:get]
```

In order to run your code, run the command `node index.js{:md}` in your project directory. After a short amount of time, you should see a "0" as the stored data.

Now, we will set a new number to the `stored_data` variable by calling the `fn set(self: @mut ContractState, new_data: u128)` function. This is an `INVOKE{:md}` transaction, so we need to sign the transaction with our account's private key and pass along the calldata.

The transaction is signed and broadcasted to the network and it can takes a few seconds for the transaction to be confirmed.

```js
// [!include ~/listings/applications/simple_storage_starknetjs/index.js:set]
```
