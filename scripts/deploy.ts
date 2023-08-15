import { ethers } from "hardhat";
import { verify } from "../utils/verify";

let Contract: any;

export async function deploy(contractName: string, params: any[]) {
  const ContractArtifact = await ethers.getContractFactory(contractName);
  console.log(params[0]);
  const gasPrice = await ContractArtifact.signer.getGasPrice();
  console.log(`Current gas price: ${gasPrice}`);

  const estimatedGas = await ContractArtifact.signer.estimateGas(
    ContractArtifact.getDeployTransaction(...params)
  );
  console.log(
    contractName + "contract deployment " + `estimated gas: ${estimatedGas}`
  );

  const deploymentPrice = gasPrice.mul(estimatedGas);
  const deployerBalance = await ContractArtifact.signer.getBalance();
  console.log(
    contractName +
      ` Deployment price:  ${ethers.utils.formatEther(deploymentPrice)}`
  );
  console.log(
    `Deployer balance:  ${ethers.utils.formatEther(deployerBalance)}`
  );

  if (deployerBalance.lt(deploymentPrice)) {
    throw new Error(
      `Insufficient funds. Top up your account balance by ${ethers.utils.formatEther(
        deploymentPrice.sub(deployerBalance)
      )}`
    );
  }
  Contract = await ContractArtifact.deploy(...params);

  await Contract.deployed();

  console.log(contractName + `contract deployed to ${Contract.address}`);
  await new Promise((resolve) => setTimeout(resolve, 10000));
  await verify(Contract.address, params);
  console.log(`Contract ${contractName} verified successfully.`);
}

deploy("CappedSet", ["20"]).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
