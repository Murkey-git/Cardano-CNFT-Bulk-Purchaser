[CmdletBinding(DefaultParametersetName='Help')]
param 
(
  [Parameter(Position=0,Mandatory=$false)][int]$count=0,
  [Parameter(Position=1,Mandatory=$false)][switch]$safemode,
  [Parameter(ParameterSetName='Send',Position=1,Mandatory=$true)][decimal]$cost=0,
  [Parameter(ParameterSetName='Send',Position=2,Mandatory=$true)][string]$receiver,
  [Parameter(ParameterSetName='Build',Position=1,Mandatory=$true)][switch]$build,
  [Parameter(ParameterSetName='Verify',Position=1,Mandatory=$true)][switch]$verify,
  [Parameter(ParameterSetName='Redeem',Position=1,Mandatory=$true)][string]$wallet
)

# Constants required for program functionality
$BASE_PATH = "$PSScriptRoot\address"
$PAYMENT = "payment"
$NODE_PATH = (Get-WmiObject Win32_Process -Filter "name = 'cardano-node.exe'" | Select-Object ExecutablePath).ExecutablePath
$CLI_PATH = [System.IO.Path]::Combine((Get-Item $NODE_PATH).Directory.FullName, "cardano-cli.exe")
$TITLE = "Warning!"
$CHOICES = '&Yes','&No'

# Socket path to communicate with the blockchain using cardano-node
$socket_path = (Get-WmiObject Win32_Process -Filter "name = 'cardano-node.exe'" | Select-Object CommandLine).CommandLine.Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)[3]
$env:CARDANO_NODE_SOCKET_PATH = $socket_path

# The name of the script and the mode it will execute in
$paramSetName = $PsCmdlet.ParameterSetName
$programName = $MyInvocation.MyCommand

if ($count -le 0)
{
  Write-Host "ERROR: The -count argument must be greater than 0." -ForegroundColor Red
  $paramSetName = "Help"
}

switch($paramSetName)
{
  "Help"
  {
    Write-Host "********************************************************************************"
    Write-Host "* HELP MENU"
    Write-Host "* "
    Write-Host "* Modes: The $programName module has 4 modes: [Build, Verify, Send, Redeem]"
    Write-Host "* [Build]: Build [-count N] number of new addresses and payment keys used for purchasing"
    Write-Host "* [Verify]: Verify [-count N] the contents of each generated address, to ensure it has the appropriate funds. The UTXO will be cached to optimize [Send] mode speed"
    Write-Host "* [Send]: Send [-count N -cost X -receiver addr] {X} ADA to the specified receiver {addr}, using {N} generated addresses"
    Write-Host "* [Redeem]: Redeem [-count N -wallet addr] all ADA and purchased NFT back to owner wallet {addr}, using {N} generated addresses"
    Write-Host "* "
    Write-Host "* Arguments:" -ForegroundColor Gray
    Write-Host "* -count: The number of wallets and addresses to build / verify / send / redeem from"
    Write-Host "* -build: Set the build flag to execute [Build] mode"
    Write-Host "* -verify: Set the verify flag to execute [Verify] mode"
    Write-Host "* -cost: The price in ADA that the [Send] mode will send to [-receiver] address"
    Write-Host "* -receiver: The address to send ADA to in [Send] mode - e.g., the wallet address for purchasing NFTs"
    Write-Host "* -wallet: The address to send ADA to in [Receive] mode - e.g., your own wallet for redeeming the NFTs and any dust"
    Write-Host "* -safemode: Set the [Send] or [Receive] mode to run in safety mode, and prompt for approval before sending assets"
    Write-Host "* ";
    Write-Host "* Example scenario:" -ForegroundColor Gray
    Write-Host "* .\$programName -count 3 -build" 
    Write-Host "* -- Verify That Wallets Are Populated And Cache UTXOs --" -ForegroundColor Gray
    Write-Host "* .\$programName -count 3 -verify" 
    Write-Host "* .\$programName -count 3 -cost 15 -receiver addr1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    Write-Host "* -- Verify That Wallets Received NFTs --" -ForegroundColor Gray
    Write-Host "* .\$programName -count 3 -verify"
    Write-Host "* .\$programName -count 3 -safemode -wallet addr1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    Write-Host "* "
    Write-Host "* If this script is useful for you, please consider donating ADA to the following address:" -ForegroundColor Green
    Write-Host "* addr1q9afhw5v8rkydmvd34kl6mjvllr58lsf8kjv8wnyftf73g4utnxgcn0srryfpc4tmlq0n9lr9w5uhzqax88dneyhs48q84wugk" -ForegroundColor Green
    Write-Host "* "
    Write-Host "*********************************************************************************"
    
    break;
  }
  "Build"
  {
    # Create the $BASE_PATH directory if it does not exist already
    if ([System.IO.Directory]::Exists($BASE_PATH) -eq $false)
    {
      [System.IO.Directory]::CreateDirectory($BASE_PATH)
    }
    
    # From 1 to $count, check that none of the key or address files already exist to ensure an empty build
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $verifyKeyFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.vkey")
      $signKeyFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.skey")
      $addressFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.addr")
      if ([System.IO.File]::Exists($verifyKeyFile) -eq $true) { throw "The file [$verifyKeyFile] already exists. Please ensure all [$PAYMENT.*] files are cleared of any funds and do not exist before performing the build operation." }
      if ([System.IO.File]::Exists($signKeyFile) -eq $true) { throw "The file [$signKeyFile] already exists. Please ensure all [$PAYMENT.*] files are cleared of any funds and do not exist before performing the build operation." }
      if ([System.IO.File]::Exists($addressFile) -eq $true) { throw "The file [$addressFile] already exists. Please ensure all [$PAYMENT.*] files are cleared of any funds and do not exist before performing the build operation." }
    }
    
    # From 1 to $count, generate the key and address files
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $verifyKeyFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.vkey")
      $signKeyFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.skey")
      $addressFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.addr")
      &$CLI_PATH address key-gen --verification-key-file "$verifyKeyFile" --signing-key-file "$signKeyFile"
      &$CLI_PATH address build --payment-verification-key-file "$verifyKeyFile" --out-file "$addressFile" --mainnet
      $address = type $addressFile
      Write-Host "Wallet Address ${i}: $address"
    }
    
    # Recommend the minimum amount to fund a wallet, based on the mint cost of the CNFT
    $mintCost = -1
    do
    {
      Try
      {
        $val = Read-Host "What is the cost in ADA for the NFT mint?";
        $mintCost = [System.Decimal]::Parse($val);
      }
      Catch
      {
        $mintCost = -1
      }
    } while ($mintCost -lt 0);
    
    Write-Host "It is recommended to send at least $($mintCost + 2) ADA to each wallet in order to cover transaction costs of sending and redeeming all assets."
    break;
  }
  "Verify"
  {
    # From 1 to $count, check that the required address files exist
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $addressFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.addr")
      if ([System.IO.File]::Exists($addressFile) -eq $false) { throw "The file [$addressFile] does not exist. Please ensure all [$PAYMENT.*] files are generated using the build operation and funded with ADA." }
    }
    
    # From 1 to $count, query each address on the blockchain and return any UTXO data
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $addressFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.addr")
      $cacheFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.cache")
      $address = type $addressFile
      $utxo = &$CLI_PATH query utxo --address $address --mainnet
      $utxo = $utxo.Split("-", [System.StringSplitOptions]::RemoveEmptyEntries)
      
      # if the UTXO data does not contain any ADA, write a warning
      if ($utxo.Count -le 1) 
      { 
        Write-Host "ERROR: The address [$address] from [$addressFile] has no UTXOs. Please fund the address and re-run the verify step." 
        continue  
      }
      
      # For each UTXO in the address, write out the transaction hash, ix, amount, and any tokens if they exist
      for ($x = 1; $x -lt $utxo.Count; $x = $x + 1)
      {
        $utxoData = $utxo[$x].Trim()
        $utxoData = $utxoData -replace "\s{2,}","{ZZ}"
        $utxoData = $utxoData -split "{zz}"
        $txHash = $utxoData[0]
        $txIx = $utxoData[1]
        $amount = $utxoData[2].Split(" ")[0].ToString()
        $tokenData = (((($utxoData[2] -replace "TxOutDatumHashNone","") -split "lovelace")[1] -replace "\+","") -replace "^\s+","").Trim()
        if ($tokenData -ne "")
        {
          $tokenData = ", Tokens=[$tokenData]"
        }
        
        Write-Host "[$address] UTXO Data: Hash=$txHash, Ix=$txIx, Amount=$($amount/1000000) ADA$($tokenData)"
        
        # Cache the first UTXO to disk, which will be used during [Send] mode for purchasing a CNFT
        if ($x -eq 1)
        {
          "$txHash,$txIx,$amount" | Out-File -Encoding "ASCII" "$cacheFile"
        }
      }
    }
    break;
  }
  "Send" 
  {
    # Prompt the user if they passed in the -safemode flag so they can double-check any details before proceeding
    if ($safemode -eq $true) 
    {
      $question = "Are you sure you want to proceed sending [$cost] ADA to the following address: [$receiver]?"
      $decision = $Host.UI.PromptForChoice($TITLE, $question, $CHOICES, 1)
      if ($decision -eq 1)
      {
        Write-Host "Aborting operation";
        return;
      }
    }
    
    # Create the necessary protocol.json file needed for calculating the minimum fees
    $protocolFile = [System.IO.Path]::Combine($BASE_PATH, "protocol.json")
    &$CLI_PATH query protocol-parameters --mainnet --out-file "$protocolFile"
    
    # From 1 to $count, check that the appropriate key and address files exist
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $signKeyFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.skey")
      $addressFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.addr")
      if ([System.IO.File]::Exists($signKeyFile) -eq $false) { throw "The file [$signKeyFile] does not exist. Please ensure all [$PAYMENT.*] files are generated using the build operation and funded with ADA." }
      if ([System.IO.File]::Exists($addressFile) -eq $false) { throw "The file [$addressFile] does not exist. Please ensure all [$PAYMENT.*] files are generated using the build operation and funded with ADA." }
    }
    
    # From 1 to $count, send the $cost amount of ADA to the $receiver address
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $signKeyFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.skey")
      $addressFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.addr")
      $cacheFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.cache")
      $draftFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.draft")
      $signFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.sign")
      $sendfee = 0
      $sendoutput = 0
      $lovelace = ($cost * 1000000).ToString("N0").Replace(",","")
      $address = type $addressFile
      
      # If the cached UTXO file exists, use this for faster performance
      if ([System.IO.File]::Exists($cacheFile) -eq $true) 
      {
        $utxo = type $cacheFile
        $utxo = $utxo -split ","
        $txHash = $utxo[0]
        $txIx = $utxo[1]
        $amount = $utxo[2]
        Write-Host "Using Cache File"
      }
      
      # If there is no cache file, query the UTXO from the blockchain
      else 
      {
        $utxo = &$CLI_PATH query utxo --address $address --mainnet
        $utxo = $utxo.Split("-", [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($utxo.Count -le 1) { throw "The address [$address] from [$addressFile] has no UTXOs. Please fund the address and re-run the verify step." }
        $utxo = $utxo[1].Trim()
        $utxo = $utxo -replace "\s{2,}","{ZZ}"
        $utxo = $utxo -split "{zz}"
        $txHash = $utxo[0]
        $txIx = $utxo[1]
        $amount = ($utxo[2] -split " ")[0]
        Write-Host "Querying Chain"
      }
      
      # Build raw transaction with empty fee parameters, and calculate the minimum fee
      &$CLI_PATH transaction build-raw --tx-in "$txHash#$txIx" --tx-out "$receiver+$lovelace" --tx-out "$address+$sendoutput" --fee $sendfee --out-file "$draftFile"
      $sendfee=(&$CLI_PATH transaction calculate-min-fee --tx-body-file "$draftFile" --tx-in-count 1 --tx-out-count 2 --witness-count 1 --mainnet --protocol-params-file "$protocolFile").split(" ")[0]
      $sendoutput = $amount-$sendfee-$lovelace
      
      # Using the new calculated minimum fee, build a new raw transaction and calculate minimum fee again as transaction size has slightly changed
      &$CLI_PATH transaction build-raw --tx-in "$txHash#$txIx" --tx-out "$receiver+$lovelace" --tx-out "$address+$sendoutput" --fee $sendfee --out-file "$draftFile"
      $sendfee2=(&$CLI_PATH transaction calculate-min-fee --tx-body-file "$draftFile" --tx-in-count 1 --tx-out-count 2 --witness-count 1 --mainnet --protocol-params-file "$protocolFile").split(" ")[0]
      $sendoutput = $amount-$sendfee2-$lovelace
      
      # sign the transaction and send
      &$CLI_PATH transaction sign --signing-key-file "$signKeyFile" --mainnet --tx-body-file "$draftFile" --out-file "$signFile"
      $result = &$CLI_PATH transaction submit --tx-file "$signFile" --mainnet
      Write-Host "[$(Get-Date -Format 'MM/dd/yyyy HH:mm:ss:fff')] $result"
    }
    break;
  }
  "Redeem"
  {
    # Prompt the user if they passed in the -safemode flag so they can double-check any details before proceeding
    if ($safemode -eq $true) 
    {
      $question = "Are you sure you want to proceed sending all received assets to the following address: [$wallet]?"
      $decision = $Host.UI.PromptForChoice($TITLE, $question, $CHOICES, 1)
      if ($decision -eq 1)
      {
        Write-Host "Aborting operation";
        return;
      }
    }
    
    $protocolFile = [System.IO.Path]::Combine($BASE_PATH, "protocol.json")
    
    # From 1 to $count, check that the appropriate key and address files exist
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $signKeyFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.skey")
      $addressFile = [System.IO.Path]::Combine($BASE_PATH, "$PAYMENT$i.addr")
      if ([System.IO.File]::Exists($signKeyFile) -eq $false) { throw "The file [$signKeyFile] does not exist. Please ensure all [$PAYMENT.*] files are generated using the build operation and funded with ADA." }
      if ([System.IO.File]::Exists($addressFile) -eq $false) { throw "The file [$addressFile] does not exist. Please ensure all [$PAYMENT.*] files are generated using the build operation and funded with ADA." }
    }
    
    # From 1 to $count, send all assets to the $wallet address
    for ($i = 1; $i -le $count; $i = $i + 1)
    {
      $sendfee = 0
      $funds = 0
      $lovelace = 0
      $projectid = ""
      $signKeyFile = [System.IO.Path]::Combine($BASE_PATH, "payment$i.skey")
      $draftFile = [System.IO.Path]::Combine($BASE_PATH, "payment$i.draft")
      $signFile = [System.IO.Path]::Combine($BASE_PATH, "payment$i.sign")
      $addressFile = $addressFile = [System.IO.Path]::Combine($BASE_PATH, "payment$i.addr")
      $address = type $addressFile
      $utxo = &$CLI_PATH query utxo --address $address --mainnet
      $utxo = $utxo.Split("-", [System.StringSplitOptions]::RemoveEmptyEntries)
      $txIn = @()
      $txOutAssets = ""
      
      # If the wallet has an empty UTXO, skip it and move on to the next
      if ($utxo.Count -le 1) 
      { 
        Write-Host "WARNING: The address [$address] from [$addressFile] has no UTXOs. Please ensure the address contains assets with the verify step before redeeming the contents."
        continue
      }
      
      # For each UTXO in the address, extract the ADA amount and any token information
      for ($x = 1; $x -lt $utxo.Count; $x = $x + 1)
      {
        $utxoChunk = $utxo[$x].Trim()
        $utxoChunk =(($utxoChunk -replace "\s{2,}","{ZZ}") -split "TxOutDatumHashNone")
        $utxoChunk = $utxoChunk -split "{ZZ}"
        $txIn += "--tx-in"
        $txIn += """$($utxoChunk[0])#$($utxoChunk[1])"""
        $txData = $utxoChunk[2] -split " "
        $funds += $txData[0]
        $lovelace += $txData[0]
        if ($txData.Length -gt 4)
        {
          $assetCount = $txData[3]
          $assetInfo = $txData[4]
          $txOutAssets += "+""$assetCount $assetInfo"""
        }
      }
        
      # Build raw transaction with empty fee parameters, and calculate the minimum fee
      &$CLI_PATH transaction build-raw $txIn --tx-out "$($wallet)+$($lovelace)$($txOutAssets)" --fee $sendfee --out-file "$draftFile"
      $sendfee=(&$CLI_PATH transaction calculate-min-fee --tx-body-file "$draftFile" --tx-in-count $utxo.Length --tx-out-count 1 --witness-count 1 --mainnet --protocol-params-file "$protocolFile").split(" ")[0]
      $lovelace = $funds - $sendfee
      
      # Using the new calculated minimum fee, build a new raw transaction and calculate minimum fee again as transaction size slightly changes
      &$CLI_PATH transaction build-raw $txIn --tx-out "$wallet+$lovelace$txOutAssets" --fee $sendfee --out-file "$draftFile"
      $sendfee2=(&$CLI_PATH transaction calculate-min-fee --tx-body-file "$draftFile" --tx-in-count $utxo.Length --tx-out-count 1 --witness-count 1 --mainnet --protocol-params-file "$protocolFile").split(" ")[0]
      $lovelace = $funds - $sendfee2
      
      # Sign the transaction, prompt the user again that they are redeeming to the correct $wallet address, and send the transaction
      &$CLI_PATH transaction sign --signing-key-file "$signKeyFile" --mainnet --tx-body-file "$draftFile" --out-file "$signFile"
      $ada = $lovelace/1000000
      $questionAssets = ($txOutAssets.Split("+", [System.StringSplitOptions]::RemoveEmptyEntries) -replace """","") -join ","
      $question = "Are you sure you want to proceed sending [$($lovelace/1000000)] ADA and the assets [$questionAssets] to the following address: [$wallet]?"
      $decision = $Host.UI.PromptForChoice($TITLE, $question, $CHOICES, 1)
      if ($decision -eq 1)
      {
        Write-Host "Skipping this wallet and continuing.";
        continue;
      }
      $result = &$CLI_PATH transaction submit --tx-file "$signFile" --mainnet
      Write-Host "[$(Get-Date -Format 'MM/dd/yyyy HH:mm:ss:fff')] $result"
    }
    break;
  }
}