# sui-move-oracles

Simple Oracle Architecture built in Move for the Sui Ecosystem.

These contracts are currently built to serve as price oracles, however you can hypothetically transform them into oracles that serve any type of data that you need. Due to Sui's high throughput and fast finality, you're able to quickly and efficiently provide all kinds of off-chain data.

![Architecture](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/6064f01b-0e2a-4060-829c-effd41966cb9/Untitled.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20220730%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20220730T165331Z&X-Amz-Expires=86400&X-Amz-Signature=ad8a7a988613c8b25a78ab1dc40bc596e4d7e96e6db5f180c7956b98b1396e84&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Untitled.png%22&x-id=GetObject)

## Getting started

Before you clone and use this repository, make sure to install the Sui command-line tool in order to test your move code. You can find it [here])(https://docs.sui.io/build/install#summary).

Once you've cloned and entered into this repository, you can easily build and test the contracts as so:

```sh
# Build
sui move build

# Test
sui move test
```
