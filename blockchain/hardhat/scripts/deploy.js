const { ethers } = require("hardhat");

async function main() {
  const Decentradonate = await ethers.getContractFactory("Decentradonate");
  const contract = await Decentradonate.deploy();
  await contract.waitForDeployment();
  console.log(`Decentradonate deployed to: ${contract.target}`);
  console.log(`Network: localhost (chainId: 31337)`);
  console.log(`Block number: ${await ethers.provider.getBlockNumber()}`);

  const campaigns = [
    { title: "Bantu Renovasi Sekolah Darurat di Cianjur", target: 5 },
    { title: "Sumur Bor untuk Desa Terpencil", target: 3 },
    { title: "Bantuan Alat Belajar Anak Yatim", target: 1 },
    { title: "Pembangunan Poskesdes Desa Cibitung", target: 10 },
    { title: "Bantuan Benih Pertanian Petani Lembang", target: 7 },
    { title: "Rumah Ibadah Desa Margahayu", target: 15 },
    { title: "Bantuan Kuliah Anak Papua", target: 8 },
  ];

  for (const c of campaigns) {
    const tx = await contract.createCampaign(c.title, c.target);
    await tx.wait();
    console.log(`Created campaign: "${c.title}" (target: ${c.target})`);
  }

  const count = await contract.getCampaignCount();
  console.log(`Total campaigns: ${count.toString()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
