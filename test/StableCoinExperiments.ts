import { ethers } from "hardhat";
import { expect } from "chai";
import dotenv from "dotenv";
import { StableCoinExperiments, IERC20 } from "../typechain-types";
dotenv.config();

const USDT = ethers.getAddress("0xdac17f958d2ee523a2206206994597c13d831ec7");
const USDC = ethers.getAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48");
const UNISWAP_V2_ROUTER = ethers.getAddress(
  "0x7a250d5630b4cf539739df2c5dacb4c659f2488d"
);
const USDT_WHALE = ethers.getAddress(
  "0x7055b17a1b911b6b971172c01ff0cc27881aea94"
);

// NOTE: You must configure your mainnet RPC in .env
const RPC = process.env.MAINNET_RPC_URL || "";

describe("StableCoinExperiments", function () {
  let contract: StableCoinExperiments;
  let usdt: IERC20;
  let usdc: IERC20;
  let whaleSigner: any;

  beforeEach(async () => {
    // Fork mainnet
    await ethers.provider.send("hardhat_reset", [
      {
        forking: {
          jsonRpcUrl: RPC,
          // blockNumber: 22771066,
        },
      },
    ]);

    await ethers.provider.send("hardhat_impersonateAccount", [USDT_WHALE]);

    // Fund with 1 ETH so whale can pay gas
    await ethers.provider.send("hardhat_setBalance", [
      USDT_WHALE,
      "0x1000000000000000000",
    ]);

    whaleSigner = await ethers.getSigner(USDT_WHALE);
    whaleSigner = await ethers.getSigner(USDT_WHALE);

    const ContractFactory = await ethers.getContractFactory(
      "StableCoinExperiments"
    );
    contract = await ContractFactory.deploy(USDT, USDC, UNISWAP_V2_ROUTER);
    await contract.waitForDeployment();

    usdt = await ethers.getContractAt("IERC20", USDT);
    usdc = await ethers.getContractAt("IERC20", USDC);

    // Transfer USDT from whale to contract

    await usdt
      .connect(whaleSigner)
      .transfer(await contract.getAddress(), 1000n);
  });

  it("should return USDT and USDC balances", async () => {
    const [usdtBalance, usdcBalance] = await contract.getTokenBalances();
    expect(usdtBalance).to.be.gt(0);
    expect(usdcBalance).to.equal(0);
  });

  it("should return potential swap info", async () => {
    const [amountOut, path] = await contract.getPotentialSwapInfoV2();
    console.log(amountOut, path);
    expect(amountOut).to.be.gt(0);
  });

  it("should perform a profitable swap from USDT to USDC", async () => {
    await contract.swapTokenFirstToSecond();
    const [usdtBalance, usdcBalance] = await contract.getTokenBalances();
    expect(usdtBalance).to.be.lt(1000n);
    expect(usdcBalance).to.be.gt(0);
  });

  it("should run doSwapV2 and decide direction", async () => {
    await contract.doSwapV2();
    const [usdtBalance, usdcBalance] = await contract.getTokenBalances();
    expect(usdcBalance).to.be.gt(0);
  });
});
