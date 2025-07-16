const hre = require("hardhat");

async function main() {
  console.log("Starting deployment of Digital Certificate Verification contract...");
  
  // Get the deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  
  // Get deployer balance
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");
  
  // Deploy the contract
  const Project = await hre.ethers.getContractFactory("Project");
  console.log("Deploying Project contract...");
  
  const project = await Project.deploy();
  await project.waitForDeployment();
  
  const contractAddress = await project.getAddress();
  console.log("Project contract deployed to:", contractAddress);
  
  // Verify the deployment
  console.log("Verifying contract deployment...");
  const owner = await project.owner();
  const totalCertificates = await project.totalCertificates();
  
  console.log("Contract owner:", owner);
  console.log("Total certificates:", totalCertificates.toString());
  
  // Save deployment info
  const deploymentInfo = {
    contractAddress: contractAddress,
    deployer: deployer.address,
    network: hre.network.name,
    blockNumber: await hre.ethers.provider.getBlockNumber(),
    timestamp: new Date().toISOString()
  };
  
  console.log("\n=== Deployment Summary ===");
  console.log("Contract Address:", deploymentInfo.contractAddress);
  console.log("Deployer Address:", deploymentInfo.deployer);
  console.log("Network:", deploymentInfo.network);
  console.log("Block Number:", deploymentInfo.blockNumber);
  console.log("Timestamp:", deploymentInfo.timestamp);
  
  // Test basic functionality
  console.log("\n=== Testing Basic Functionality ===");
  try {
    // Test issuing a certificate
    const tx = await project.issueCertificate(
      "John Doe",
      "Blockchain Development",
      "Tech University",
      "0x1234567890abcdef1234567890abcdef12345678"
    );
    const receipt = await tx.wait();
    console.log("Test certificate issued successfully!");
    console.log("Transaction hash:", receipt.hash);
    
    // Get the certificate ID from the event
    const event = receipt.logs.find(log => {
      try {
        const parsedLog = project.interface.parseLog(log);
        return parsedLog.name === "CertificateIssued";
      } catch (e) {
        return false;
      }
    });
    
    if (event) {
      const parsedEvent = project.interface.parseLog(event);
      const certificateId = parsedEvent.args.certificateId;
      console.log("Certificate ID:", certificateId);
      
      // Verify the certificate
      const verification = await project.verifyCertificate(certificateId);
      console.log("Certificate verification result:");
      console.log("  Valid:", verification[0]);
      console.log("  Recipient:", verification[1]);
      console.log("  Course:", verification[2]);
      console.log("  Institution:", verification[3]);
      console.log("  Issue Date:", new Date(Number(verification[4]) * 1000).toLocaleString());
    }
    
  } catch (error) {
    console.error("Error during testing:", error.message);
  }
  
  console.log("\n=== Deployment Complete ===");
  console.log("Remember to:");
  console.log("1. Save the contract address:", contractAddress);
  console.log("2. Update your frontend configuration");
  console.log("3. Verify the contract on the block explorer if needed");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
