import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.27",
  // networks: {
  //   hardhat: {
  //     forking: {
  //       url: process.env.MAINNET_RPC_URL || "",
  //       blockNumber: 14505032,
  //     },
  //   },
  // },
};

export default config;
