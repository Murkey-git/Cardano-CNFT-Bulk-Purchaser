# Cardano NFT Bulk Purchaser #

This tool is used to purchase Cardano NFT drops from multiple wallets using the cardano-cli, to allow for rapid purchases in high-demand drops.

The tool assumes that the CNFT drop uses or allows multiple purchases sent to a single address and that the cost of each CNFT is known before the drop.

This tool will leverage the cardano-cli.exe which ships with the Daedalus wallet, and communicates to the blockchain using the cardano-node.exe process which is executed when the Daedalus wallet is running. Please ensure Daedalus is executing before attempting to use this tool.

## Modules ##

This tool has 4 modes: [Build, Verify, Send, Redeem].

### Build ###


The `Build` module creates N new addresses and payment keys which can be used for purchasing CNFT tokens. Make sure to fund each address with a single UTXO covering the cost of the CNFT, plus a few extra ADA to cover transaction fees for sending and redeeming.

### Verify ###

The `Verify` module checks the current contents of each generated address for manual verification purposes, and caches the first UTXO to disk to ensure it can be sent as fast as possible.

### Send ###

The `Send` module will send `X` ADA from each generated wallet to the specified receiver wallet. This module will be used to purchase the CNFT.

### BulkSend ###

The `BulkSend` module will send `X` * `N` ADA from a single generated wallet to the specified bulkreceiver wallet. This module can be used to purchase CNFTs by sending multple output-transactions from a single wallet.

### Redeem ###

The `Redeem` module will extract all ADA and every CNFT, and send it back to the specified wallet.

## Arguments ##

`-count`: The number of wallets and addresses to [Build, Verify, Send, Redeem] from.

`-build`: Set the build flag to execute the `Build` module.

`-verify`: Set the verify flag to execute the `Verify` module.

`-cost`: The price in ADA that the `Send` module will send to the `-receiver` address.

`-receiver`: The address ADA is sent to when executing the `Send` module.

`-bulkcost`: The price in ADA that the `BulkSend` module will send to the `-bulkreceiver` address in each output transaction.

`-bulkreceiver`: The address ADA is sent to when executing the `BulkSend` module.

`-wallet`: The address ADA and CNFTs are sent to when executing the `Redeem` module.

`-safemode`: Set the `Send` or `Receive` mode to run in safety mode, prompting for approval before sending transactions. This will allow for extra time to double-check the command-line arguments to ensure ADA is sent to the correct location.

## Examples ##

--- Build 3 wallets ---
```
.\purchase.ps1 -count 3 -build

Wallet Address 1: addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Wallet Address 2: addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab
Wallet Address 3: addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaac
What is the cost in ADA for the NFT mint?: 1
It is recommended to send at least 3 ADA to each wallet in order to cover transaction costs of sending and redeeming all assets.
```

--- Verify wallet contents are populated and cache the UTXOs ---

```
.\purchase.ps1 -count 3 -verify

[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] UTXO Data: Hash=3ee0391dbe1025eb78b28a45f84678e7c1b0e38d3628cd97eac5b317a4adb36c, Ix=0, Amount=3 ADA
[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab] UTXO Data: Hash=6e04f8326e694aea13f25727cd4ce7d39eb8f63c0a6f546a8dd5007bb6cb2680, Ix=0, Amount=3 ADA
[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaac] UTXO Data: Hash=51a3a06daa64063d58c9991a2eeceb76bc5ba46439831a6bec1603e2f634a8e4, Ix=0, Amount=3 ADA

```

--- Send 1 ADA to a CNFT address ---

```
.\purchase.ps1 -count 3 -cost 1 -receiver addr1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz -safemode

Warning!
Are you sure you want to proceed sending [1] ADA to the following address:
[addr1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz]?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
Using Cache File
[10-11-2021 20:33:17:838] Transaction successfully submitted.
Using Cache File
[10-11-2021 20:33:17:994] Transaction successfully submitted.
Using Cache File
[10-11-2021 20:33:18:134] Transaction successfully submitted.
```

--- BulkSend 3 ADA to a CNFT address, using 3 output transactions of 1 ADA each ---

```
.\purchase.ps1 -count 3 -bulkcost 1 -bulkreceiver addr1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz -safemode

Warning!
Are you sure you want to proceed sending [1*3] ADA to the following address:
[addr1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz]?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
Using Cache File
[10-11-2021 20:33:17:838] Transaction successfully submitted.
```

--- Verify wallet contents received UTXOs ---

```
.\purchase.ps1 -count 3 -verify

[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] UTXO Data: Hash=47e8be3e57052a64de982398110aa4b78538f728a06f20ec49f75ebde6401115, Ix=1, Amount=1.824731 ADA
[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] UTXO Data: Hash=e3b3bfbf2e688bfb9451319c9804cc5003d2b34eba860832de02d11e558571be, Ix=0, Amount=1.37928 ADA, Tokens=[1 tttttttttttttttttttttttttttttttttttttttttttttttttttttttt.TOKEN1]
[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab] UTXO Data: Hash=4dfedb8a1344fea885fbb7e60f0af3e06f760995b9e7da84e154180d1efe651c, Ix=1, Amount=1.824731 ADA
[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab] UTXO Data: Hash=d87a8599c46780dfc22e33b6f8234862974262dc607584756a88b64a31557abb, Ix=0, Amount=1.37928 ADA, Tokens=[1 tttttttttttttttttttttttttttttttttttttttttttttttttttttttt.TOKEN2]
[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaac] UTXO Data: Hash=4f0ef523cd03a9b2a999e138bd76eab9b95846ddc601256d16b25aff5ca82a8a, Ix=0, Amount=1.37928 ADA, Tokens=[1 tttttttttttttttttttttttttttttttttttttttttttttttttttttttt.TOKEN3]
[addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaac] UTXO Data: Hash=c81c25bee1a4b8d451374d8e16e03b694fdc9be87bbf2b29c9e6ac044d0e83a7, Ix=1, Amount=1.824731 ADA
```

--- Redeem any leftover ADA and the CNFTs to original owner wallet ---

```
.\purchase.ps1 -count 3 -wallet addr1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

Warning!
Are you sure you want to proceed sending [3.025706] ADA and the assets [1 tttttttttttttttttttttttttttttttttttttttttttttttttttttttt.TOKEN1] to the following address:
[addr1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb]?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
[10-11-2021 20:34:21:104] Transaction successfully submitted.

Warning!
Are you sure you want to proceed sending [3.025706] ADA and the assets [1 tttttttttttttttttttttttttttttttttttttttttttttttttttttttt.TOKEN2] to the following address:
[addr1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb]?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
[10-11-2021 20:34:24:485] Transaction successfully submitted.

Warning!
Are you sure you want to proceed sending [3.025706] ADA and the assets [1 tttttttttttttttttttttttttttttttttttttttttttttttttttttttt.TOKEN3] to the following address:
[addr1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb]?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
[10-11-2021 20:34:26:824] Transaction successfully submitted.
```

## Donations ##
If this script is useful for you, please consider donating ADA to the following address:

```
addr1q9afhw5v8rkydmvd34kl6mjvllr58lsf8kjv8wnyftf73g4utnxgcn0srryfpc4tmlq0n9lr9w5uhzqax88dneyhs48q84wugk
```
