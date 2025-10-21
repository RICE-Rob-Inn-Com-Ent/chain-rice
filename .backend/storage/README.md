# Decentralized Storage - IPFS & Arweave

## Overview

Decentralized storage solutions for permanent, censorship-resistant data storage.

## IPFS (InterPlanetary File System)

### Features

- ✅ **Content Addressing** - Files referenced by hash
- ✅ **Distributed** - P2P network
- ✅ **Deduplication** - Automatic content deduplication
- ✅ **Offline First** - Works without internet
- ✅ **Free** - No storage costs

### Quick Start

```bash
# Install IPFS
wget https://dist.ipfs.tech/kubo/v0.27.0/kubo_v0.27.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.27.0_linux-amd64.tar.gz
cd kubo
sudo bash install.sh

# Initialize
ipfs init

# Start daemon
ipfs daemon
```

### Upload Files

```bash
# Add file
ipfs add myfile.txt
# Returns: QmHash...

# Add directory
ipfs add -r ./mydir

# Retrieve file
ipfs cat QmHash... > downloaded.txt

# Pin file (keep permanently)
ipfs pin add QmHash...
```

### Go Client

```go
package main

import (
    shell "github.com/ipfs/go-ipfs-api"
    "fmt"
    "os"
)

func main() {
    sh := shell.NewShell("localhost:5001")

    // Upload file
    file, _ := os.Open("myfile.txt")
    hash, _ := sh.Add(file)
    fmt.Printf("File uploaded: %s\n", hash)

    // Retrieve file
    data, _ := sh.Cat(hash)
    // Use data...

    // Pin file
    sh.Pin(hash)
}
```

### Python Client

```python
import ipfshttpclient

# Connect to IPFS
client = ipfshttpclient.connect('/ip4/127.0.0.1/tcp/5001/http')

# Upload file
res = client.add('myfile.txt')
print(f"File hash: {res['Hash']}")

# Upload JSON
import json
data = {'name': 'Alice', 'age': 30}
res = client.add_json(data)

# Retrieve file
file_content = client.cat(res)

# Pin file
client.pin.add(res)

# Get file stats
stats = client.object.stat(res)
```

## Arweave (Permanent Storage)

### Features

- ✅ **Permanent Storage** - Pay once, store forever
- ✅ **Immutable** - Cannot be deleted or modified
- ✅ **Decentralized** - Distributed across miners
- ✅ **Low Cost** - One-time payment for permanent storage

### Upload to Arweave

```javascript
// Node.js example
import Arweave from "arweave";
import fs from "fs";

const arweave = Arweave.init({
  host: "arweave.net",
  port: 443,
  protocol: "https",
});

async function uploadFile() {
  // Load wallet
  const wallet = JSON.parse(fs.readFileSync("wallet.json", "utf8"));

  // Read file
  const data = fs.readFileSync("myfile.pdf");

  // Create transaction
  const transaction = await arweave.createTransaction(
    {
      data: data,
    },
    wallet
  );

  // Add tags
  transaction.addTag("Content-Type", "application/pdf");
  transaction.addTag("App-Name", "MyApp");

  // Sign
  await arweave.transactions.sign(transaction, wallet);

  // Upload
  const response = await arweave.transactions.post(transaction);

  console.log(`Transaction ID: ${transaction.id}`);
  console.log(`File URL: https://arweave.net/${transaction.id}`);
}
```

### Python Arweave Client

```python
import arweave

# Initialize
wallet = arweave.Wallet('wallet.json')
client = arweave.Arweave(
    wallet=wallet,
    api_url='https://arweave.net'
)

# Upload file
with open('myfile.pdf', 'rb') as f:
    tx = arweave.Transaction(wallet, data=f.read())
    tx.add_tag('Content-Type', 'application/pdf')
    tx.sign()
    tx.send()

print(f"TX ID: {tx.id}")
print(f"URL: https://arweave.net/{tx.id}")

# Retrieve file
data = client.transactions.get_data(tx.id)
```

## Bundlr (Arweave Scaling)

```javascript
import { WebBundlr } from "@bundlr-network/client";

const bundlr = new WebBundlr("https://node1.bundlr.network", "arweave", privateKey);

// Upload
const tx = await bundlr.upload(fileBuffer, {
  tags: [
    { name: "Content-Type", value: "image/png" },
    { name: "App-Name", value: "MyApp" },
  ],
});

console.log(`URL: https://arweave.net/${tx.id}`);
```

## IPFS Pinning Services

### Pinata

```javascript
const pinataSDK = require("@pinata/sdk");
const pinata = new pinataSDK(apiKey, apiSecret);

// Upload file
const fs = require("fs");
const readableStreamForFile = fs.createReadStream("./myfile.png");

const options = {
  pinataMetadata: {
    name: "MyFile.png",
  },
  pinataOptions: {
    cidVersion: 1,
  },
};

const result = await pinata.pinFileToIPFS(readableStreamForFile, options);
console.log(result.IpfsHash);

// Upload JSON
const body = {
  name: "Alice",
  description: "User profile",
};

const jsonResult = await pinata.pinJSONToIPFS(body, {
  pinataMetadata: { name: "user-profile.json" },
});
```

### Web3.Storage

```javascript
import { Web3Storage } from "web3.storage";

const client = new Web3Storage({ token: API_TOKEN });

// Upload files
const files = [new File(["Hello World"], "hello.txt")];

const cid = await client.put(files);
console.log(`IPFS CID: ${cid}`);
console.log(`URL: https://w3s.link/ipfs/${cid}`);
```

## Use Cases

### 1. NFT Metadata Storage

```javascript
// Store NFT metadata on IPFS
const metadata = {
  name: "My NFT",
  description: "Awesome NFT",
  image: "ipfs://QmImageHash",
  attributes: [{ trait_type: "Rarity", value: "Legendary" }],
};

const metadataHash = await ipfs.add(JSON.stringify(metadata));
const tokenURI = `ipfs://${metadataHash}`;
```

### 2. Document Storage

```python
# Store legal documents on Arweave
def store_document(file_path):
    with open(file_path, 'rb') as f:
        tx = arweave.Transaction(wallet, data=f.read())
        tx.add_tag('Content-Type', 'application/pdf')
        tx.add_tag('Document-Type', 'Legal')
        tx.add_tag('Timestamp', str(time.time()))
        tx.sign()
        tx.send()

    return f"https://arweave.net/{tx.id}"
```

### 3. Backup System

```go
// Backup to IPFS with redundancy
func backupToIPFS(data []byte) (string, error) {
    sh := shell.NewShell("localhost:5001")

    // Add to local IPFS
    hash, err := sh.Add(bytes.NewReader(data))
    if err != nil {
        return "", err
    }

    // Pin to ensure availability
    err = sh.Pin(hash)
    if err != nil {
        return "", err
    }

    // Also pin to Pinata for redundancy
    pinToPinata(data, hash)

    return hash, nil
}
```

## References

- [IPFS Docs](https://docs.ipfs.tech/)
- [Arweave Docs](https://docs.arweave.org/)
- [Bundlr Network](https://docs.bundlr.network/)
