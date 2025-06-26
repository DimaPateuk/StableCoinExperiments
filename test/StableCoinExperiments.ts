import { ethers } from "hardhat";
import { expect } from "chai";
import dotenv from "dotenv";
import { StableCoinExperiments, IERC20 } from "../typechain-types";
import JSBI from "jsbi";
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

  describe("swaps v2", () => {
    it("should return USDT and USDC balances", async () => {
      const [usdtBalance, usdcBalance] = await contract.getTokenBalances();
      expect(usdtBalance).to.be.gt(0);
      expect(usdcBalance).to.equal(0);
    });

    it("should return potential swap info", async () => {
      try {
        await contract.getPotentialSwapInfoV2();
      } catch (error) {
        expect((error as Error).message).to.include("No profit");
      }
    });

    it("should run doSwapV2 and decide direction", async () => {
      try {
        await contract.doSwapV2();
        expect(1).equal(2);
      } catch (error) {
        expect((error as Error).message).to.include("No profit");
      }
    });

    describe("getPotentialSwapInfoByAmountV2", () => {
      it("should return correct swap info from TOKEN_FIRST to TOKEN_SECOND", async () => {
        const inputAmount = ethers.parseUnits("100", 6);
        const [amountIn, amountOut, path] =
          await contract.getPotentialSwapInfoByAmountV2(inputAmount, true);

        expect(amountIn).to.equal(inputAmount);
        expect(amountOut).to.be.gt(0);
        expect(path[0]).to.equal(USDT);
        expect(path[1]).to.equal(USDC);
      });

      it("should return correct swap info from TOKEN_SECOND to TOKEN_FIRST", async () => {
        const inputAmount = ethers.parseUnits("100", 6);
        const [amountIn, amountOut, path] =
          await contract.getPotentialSwapInfoByAmountV2(inputAmount, false);

        expect(amountIn).to.equal(inputAmount);
        expect(amountOut).to.be.gt(0);
        expect(path[0]).to.equal(USDC);
        expect(path[1]).to.equal(USDT);
      });

      it("should return zero output for zero input", async () => {
        const inputAmount = 0;
        const [amountIn, amountOut, path] =
          await contract.getPotentialSwapInfoByAmountV2(inputAmount, true);

        expect(amountIn).to.equal(0);
        expect(amountOut).to.equal(0);
        expect(path.length).to.equal(2);
      });
    });

    describe("Swap Failure Scenarios", () => {
      it("should revert swap if no profit", async () => {
        const [owner] = await ethers.getSigners();

        // Ensure router returns same or less than amountIn
        // Usually this would require mocking the router
        await expect(contract.doSwapV2()).to.be.revertedWith(
          "No profit: output <= input"
        );
      });
    });
  });

  describe("Token Withdrawal", () => {
    it("should allow owner to withdraw tokens", async () => {
      const [owner] = await ethers.getSigners();
      const recipient = owner.address;

      const contractAddress = await contract.getAddress();
      const amountStr = (await usdt.balanceOf(contractAddress)).toString();
      const amount = JSBI.BigInt(amountStr);

      const initialStr = (await usdt.balanceOf(recipient)).toString();
      const initial = JSBI.BigInt(initialStr);

      await contract.withdrawToken(USDT, amountStr, recipient);

      const finalStr = (await usdt.balanceOf(recipient)).toString();
      const final = JSBI.BigInt(finalStr);

      // final - initial === amount
      const diff = JSBI.subtract(final, initial);
      expect(diff.toString()).to.equal(amount.toString());
    });
  });

  describe("Non-owner Access Control", () => {
    it("should not allow non-owner to call doSwapV2", async () => {
      const [, nonOwner] = await ethers.getSigners();
      await expect(contract.connect(nonOwner).doSwapV2()).to.be.reverted;
    });

    it("should not allow non-owner to withdraw tokens", async () => {
      const [, nonOwner] = await ethers.getSigners();
      await expect(
        contract.connect(nonOwner).withdrawToken(USDT, 1n, nonOwner.address)
      ).to.be.reverted;
    });
  });
});
