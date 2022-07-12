import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import {
  CROSS_CHAIN_SEAPORT_ADDRESS,
  EMPTY_BYTES32,
  ItemType,
  NULL_ADDRESS,
  OrderType,
} from "./constants";

import type {
  SeaportVerifier,
  TestERC1155,
  TestERC721,
} from "../typechain-types";
import type {
  OrderParametersStruct,
  OrderStruct,
} from "../typechain-types/contracts/SeaportVerifier";
import type { TestERC20 } from "../typechain-types/contracts/test/TestERC20";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Validate Orders", function () {
  async function deployFixture() {
    const [owner, ...otherAccounts] = await ethers.getSigners();

    const Verifier = await ethers.getContractFactory("SeaportVerifier");
    const TestERC721Factory = await ethers.getContractFactory("TestERC721");
    const TestERC1155Factory = await ethers.getContractFactory("TestERC1155");
    const TestERC20Factory = await ethers.getContractFactory("TestERC20");

    const verifier = await Verifier.deploy();
    const erc721_1 = await TestERC721Factory.deploy("NFT1", "NFT1");
    const erc721_2 = await TestERC721Factory.deploy("NFT2", "NFT2");
    const erc1155_1 = await TestERC1155Factory.deploy("uri_here");
    const erc20_1 = await TestERC20Factory.deploy("ERC20", "ERC20");

    return {
      verifier,
      owner,
      otherAccounts,
      erc721_1,
      erc721_2,
      erc1155_1,
      erc20_1,
    };
  }

  describe("Validate Offer Items", function () {
    let baseOrderParameters: OrderParametersStruct;
    let verifier: SeaportVerifier;
    let owner: SignerWithAddress;
    let otherAccounts: SignerWithAddress[];
    let erc721_1: TestERC721;
    let erc721_2: TestERC721;
    let erc1155_1: TestERC1155;
    let erc20_1: TestERC20;

    before(async function () {
      baseOrderParameters = {
        offerer: NULL_ADDRESS,
        zone: NULL_ADDRESS,
        orderType: OrderType.FULL_OPEN,
        startTime: "0",
        endTime: 0, // Math.round(Date.now() / 1000 - 100).toString(),
        salt: "0",
        totalOriginalConsiderationItems: 0,
        offer: [],
        consideration: [],
        zoneHash: EMPTY_BYTES32,
        conduitKey: EMPTY_BYTES32,
      };
    });

    beforeEach(async function () {
      const res = await loadFixture(deployFixture);
      verifier = res.verifier;
      owner = res.owner;
      otherAccounts = res.otherAccounts;
      erc721_1 = res.erc721_1;
      erc721_2 = res.erc721_2;
      erc1155_1 = res.erc1155_1;
      baseOrderParameters.offerer = owner.address;
      erc20_1 = res.erc20_1;
    });

    it("Zero offer items", async function () {
      const order: OrderStruct = {
        parameters: baseOrderParameters,
        signature: "0x",
      };

      expect(
        await verifier.validateOfferItems(order.parameters)
      ).to.have.deep.property("errors", ["Need at least one offer item"]);
    });

    it("Invalid item type", async function () {
      const order: OrderStruct = {
        parameters: baseOrderParameters,
        signature: "0x",
      };

      order.parameters.offer = [
        {
          itemType: ItemType.NATIVE,
          token: NULL_ADDRESS,
          identifierOrCriteria: "0",
          startAmount: "1",
          endAmount: "1",
        },
      ];

      expect(
        await verifier.validateOfferItems(order.parameters)
      ).to.have.deep.property("errors", ["invalid item type"]);
    });

    describe("ERC721", async function () {
      it("No approval", async function () {
        await erc721_1.mint(owner.address, 2);

        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC721,
            token: erc721_1.address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", ["no token approval"]);
      });

      it("Not owner", async function () {
        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC721,
            token: erc721_1.address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", [
          "not owner of token",
          "no token approval",
        ]);

        await erc721_1.mint(otherAccounts[0].address, 2);
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", [
          "not owner of token",
          "no token approval",
        ]);
      });

      it("Success", async function () {
        await erc721_1.mint(owner.address, 2);
        await erc721_1.approve(CROSS_CHAIN_SEAPORT_ADDRESS, 2);

        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC721,
            token: erc721_1.address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", []);
      });

      it("Invalid token: contract", async function () {
        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC721,
            token: erc20_1.address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", [
          "Invalid ERC721 token",
          "not owner of token",
          "no token approval",
        ]);
      });

      it("Invalid token: null address", async function () {
        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC721,
            token: NULL_ADDRESS,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", [
          "Invalid ERC721 token",
          "not owner of token",
          "no token approval",
        ]);
      });

      it("Invalid token: eoa", async function () {
        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC721,
            token: otherAccounts[2].address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", [
          "Invalid ERC721 token",
          "not owner of token",
          "no token approval",
        ]);
      });
    });

    describe("ERC1155", async function () {
      it("No approval", async function () {
        await erc1155_1.mint(owner.address, 2, 1);

        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC1155,
            token: erc1155_1.address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", ["no token approval"]);
      });

      it("Insufficient amount", async function () {
        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC1155,
            token: erc1155_1.address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", [
          "no token approval",
          "insufficient token balance",
        ]);
      });

      it("Success", async function () {
        await erc1155_1.mint(owner.address, 2, 1);
        await erc1155_1.setApprovalForAll(CROSS_CHAIN_SEAPORT_ADDRESS, true);

        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC1155,
            token: erc1155_1.address,
            identifierOrCriteria: "2",
            startAmount: "1",
            endAmount: "1",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", []);
      });
    });

    describe("ERC20", async function () {
      it("No approval", async function () {
        await erc20_1.mint(owner.address, 2000);

        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC20,
            token: erc20_1.address,
            identifierOrCriteria: "0",
            startAmount: "1000",
            endAmount: "1000",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", ["insufficient token allowance"]);
      });

      it("Insufficient amount", async function () {
        await erc20_1.mint(owner.address, 900);
        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC20,
            token: erc20_1.address,
            identifierOrCriteria: "0",
            startAmount: "1000",
            endAmount: "1000",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", [
          "insufficient token allowance",
          "insufficient token balance",
        ]);
      });

      it("Success", async function () {
        await erc20_1.mint(owner.address, 2000);
        await erc20_1.approve(CROSS_CHAIN_SEAPORT_ADDRESS, 1000);

        const order: OrderStruct = {
          parameters: baseOrderParameters,
          signature: "0x",
        };
        order.parameters.offer = [
          {
            itemType: ItemType.ERC20,
            token: erc20_1.address,
            identifierOrCriteria: "0",
            startAmount: "1000",
            endAmount: "1000",
          },
        ];
        expect(
          await verifier.validateOfferItems(order.parameters)
        ).to.have.deep.property("errors", []);
      });
    });
  });

  // it("test", async function () {
  //   const testOrder = { parameters: testOrderParameters, signature: "0xdd5c86abf5b890e5a8fe43206f0b080bdb528208c44d81af9adca5bd47a214ef124bb4287a894c5f957c9a0f4dff6a850712f5c717bede3b014981f86e3582521c" };
  //   const res = await verifier.callStatic.isValidOrder(testOrder);
  // })
});
