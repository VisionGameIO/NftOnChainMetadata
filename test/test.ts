import { expect } from "chai";
import { ethers } from "hardhat";
import { TestToken } from "../typechain-types/contracts/test/TestToken";

const parseDataURL = require("data-urls");

describe("TestToken", function () {
  async function getContract(): Promise<TestToken> {
    const ContractFactory = await ethers.getContractFactory("TestToken");

    const instance = await ContractFactory.deploy() as TestToken;
    await instance.deployed();

    return instance
  }

  it("should deploy", async function () {
    const instance = await getContract();

    expect(await instance.name()).to.equal("Test NFT");
  });

  it("tokenURI call should fail until metadata is set", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.safeMint(owner.address);
    expect(contract.tokenURI(0)).to.be.revertedWith("Token metadata field 'name' is not set");

    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("name"), "Awesome NFT!");
    expect(contract.tokenURI(0)).to.be.revertedWith("Token metadata field 'description' is not set");
  });

  it("tokenURI call should succeed when basic metadata is set", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.safeMint(owner.address);
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("name"), "Awesome NFT!");
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("description"), "Awesome Description!");

    const uri = await contract.tokenURI(0);
    const uriBody = new TextDecoder().decode(parseDataURL(uri).body);
    console.log(uriBody);
    expect(uri).to.equal("data:application/json;base64,eyJuYW1lIjoiQXdlc29tZSBORlQhIiwiZGVzY3JpcHRpb24iOiJBd2Vzb21lIERlc2NyaXB0aW9uISJ9");
    expect(uriBody).to.equal(`{"name":"Awesome NFT!","description":"Awesome Description!"}`);
  });

  it("tokenURI call return should be valid with attributes data set", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.safeMint(owner.address);
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("name"), "Awesome NFT!");
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("description"), "Awesome Description!");
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("trait_value"), ["Sad", "152", "76", "Quirky"]);
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("trait_type"), ["Mood", "Power Level", "Health Bonus", ""]);
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("trait_display"), ["", "numeric", "boost_percentage", ""]);
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("max_value"), ["", "500", "", ""]);

    const uri = await contract.tokenURI(0);
    const uriBody = new TextDecoder().decode(parseDataURL(uri).body);
    console.log(uriBody);
    expect(uriBody).to.equal(`{"name":"Awesome NFT!","description":"Awesome Description!","attributes":[{"trait_type":"Mood","value":"Sad"},{"trait_type":"Power Level","value":152,"display_type":"numeric","max_value":500},{"trait_type":"Health Bonus","value":76,"display_type":"boost_percentage"},{"value":"Quirky"}]}`);
  });

  it("dynamic JSON data generation must succeed", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.safeMint(owner.address);
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("name"), "Awesome NFT!");
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("description"), "Awesome Description!");
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("trait_value"), ["Sad", "152", "76", "Quirky"]);
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("trait_type"), ["Mood", "Power Level", "Health Bonus", ""]);
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("trait_display"), ["", "numeric", "boost_percentage", ""]);
    await contract.setDefaultTokenMetadataValues(ethers.utils.formatBytes32String("max_value"), ["", "500", "", ""]);

    const uri = await contract.testDynamicTokenURI(0);
    const uriBody = new TextDecoder().decode(parseDataURL(uri).body);
    console.log(uriBody);
    const json: any = JSON.parse(uriBody);

    expect(json.animation_url).to.equal(`http://ipfs.example.com/ipfs/?address=${contract.address.toLowerCase()}&tokenId=0`);
  });

  
  it("mint with traits succeeds and produces valid JSON", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("name"), "Awesome NFT!");
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("description"), "Awesome Description!");
    await contract.safeMintWithTraits(owner.address, {
      emotion: "Surprised",
      healthBonus: 43,
      powerLevel: 186,
      mood: 2
    });

    const uri = await contract.tokenURI(0);
    const uriBody = new TextDecoder().decode(parseDataURL(uri).body);
    console.log(uriBody);
    expect(uriBody).to.equal(`{"name":"Awesome NFT!","description":"Awesome Description!","attributes":[{"trait_type":"Mood","value":2,"display_type":"numeric"},{"trait_type":"Power Level","value":186,"display_type":"numeric"},{"trait_type":"Health Bonus","value":43,"display_type":"boost_percentage"},{"trait_type":"Emotion","value":"Surprised"}]}`);
  });

  it("contractURI call should fail until basic metadata is set", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.safeMint(owner.address);
    expect(contract.contractURI()).to.be.revertedWith("Token metadata field 'name' is not set");

    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("name"), "Contract Awesome NFT!");
    expect(contract.contractURI()).to.be.revertedWith("Token metadata field 'description' is not set");
  });

  it("contractURI call should succeed when all metadata is set", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.safeMint(owner.address);
    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("name"), "Contract Awesome NFT!");
    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("description"), "Contract Awesome Description!");
    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("image"), "http://placekitten.com/200/300");
    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("external_url"), "http://example.com/external");

    const uri = await contract.contractURI();
    const uriBody = new TextDecoder().decode(parseDataURL(uri).body);
    expect(uriBody).to.equal(`{"name":"Contract Awesome NFT!","description":"Contract Awesome Description!","image":"http://placekitten.com/200/300"}`);
  });

  it("contractURI shouldn't use any token metadata", async function () {
    const [owner, user] = await ethers.getSigners();
    const contract: TestToken = await getContract();

    await contract.safeMint(owner.address);

    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("name"), "Awesome NFT!");
    await contract.setDefaultTokenMetadataValue(ethers.utils.formatBytes32String("description"), "Awesome Description!");

    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("name"), "Contract Awesome NFT!");
    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("description"), "Contract Awesome Description!");
    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("image"), "http://placekitten.com/200/300");
    await contract.setContractMetadataValue(ethers.utils.formatBytes32String("external_link"), "http://example.com/external");

    const uri = await contract.contractURI();
    const uriBody = new TextDecoder().decode(parseDataURL(uri).body);
    expect(uriBody).to.equal(`{"name":"Contract Awesome NFT!","description":"Contract Awesome Description!","image":"http://placekitten.com/200/300","external_link":"http://example.com/external"}`);
  });
});
