import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import {
  CROSS_CHAIN_SEAPORT_ADDRESS,
  EIP_712_ORDER_TYPE,
  EMPTY_BYTES32,
  ItemType,
  NULL_ADDRESS,
  OPENSEA_CONDUIT_ADDRESS,
  OPENSEA_CONDUIT_KEY,
  OrderType,
} from "./constants";

import type {
  ConsiderationInterface,
  SeaportValidator,
  TestERC1155,
  TestERC721,
  TestZone,
} from "../typechain-types";
import type {
  OrderParametersStruct,
  OrderStruct,
} from "../typechain-types/contracts/SeaportValidator";
import type { OrderComponentsStruct } from "../typechain-types/contracts/interfaces/ConsiderationInterface";
import type { TestERC20 } from "../typechain-types/contracts/test/TestERC20";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Validate Orders", function () {
  const feeRecipient = "0x0000000000000000000000000000000000000FEE";
  const coder = new ethers.utils.AbiCoder();
  let baseOrderParameters: OrderParametersStruct;
  let validator: SeaportValidator;
  let seaport: ConsiderationInterface;
  let owner: SignerWithAddress;
  let otherAccounts: SignerWithAddress[];
  let erc721_1: TestERC721;
  let erc721_2: TestERC721;
  let erc1155_1: TestERC1155;
  let erc20_1: TestERC20;

  before(async function () {
    seaport = await ethers.getContractAt(
      "ConsiderationInterface",
      CROSS_CHAIN_SEAPORT_ADDRESS
    );
  });

  async function deployFixture() {
    const [owner, ...otherAccounts] = await ethers.getSigners();

    const Validator = await ethers.getContractFactory("SeaportValidator");
    const TestERC721Factory = await ethers.getContractFactory("TestERC721");
    const TestERC1155Factory = await ethers.getContractFactory("TestERC1155");
    const TestERC20Factory = await ethers.getContractFactory("TestERC20");

    const validator = await Validator.deploy();

    const erc721_1 = await TestERC721Factory.deploy("NFT1", "NFT1");
    const erc721_2 = await TestERC721Factory.deploy("NFT2", "NFT2");
    const erc1155_1 = await TestERC1155Factory.deploy("uri_here");
    const erc20_1 = await TestERC20Factory.deploy("ERC20", "ERC20");

    return {
      validator,
      owner,
      otherAccounts,
      erc721_1,
      erc721_2,
      erc1155_1,
      erc20_1,
    };
  }

  beforeEach(async function () {
    baseOrderParameters = {
      offerer: NULL_ADDRESS,
      zone: NULL_ADDRESS,
      orderType: OrderType.FULL_OPEN,
      startTime: "0",
      endTime: Math.round(Date.now() / 1000 + 4000).toString(),
      salt: "0",
      totalOriginalConsiderationItems: 0,
      offer: [],
      consideration: [],
      zoneHash: EMPTY_BYTES32,
      conduitKey: EMPTY_BYTES32,
    };
    const res = await loadFixture(deployFixture);
    validator = res.validator;
    owner = res.owner;
    otherAccounts = res.otherAccounts;
    erc721_1 = res.erc721_1;
    erc721_2 = res.erc721_2;
    erc1155_1 = res.erc1155_1;
    baseOrderParameters.offerer = owner.address;
    erc20_1 = res.erc20_1;
  });

  describe("Validate Time", function () {
    beforeEach(function () {
      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC721,
          token: erc721_1.address,
          identifierOrCriteria: "2",
          startAmount: "1",
          endAmount: "1",
        },
      ];
    });

    it("Order expired", async function () {
      baseOrderParameters.endTime = 1000;

      expect(
        await validator.validateTime(baseOrderParameters)
      ).to.include.deep.ordered.members([["Order expired"], []]);
    });

    it("Order not yet active", async function () {
      baseOrderParameters.startTime = baseOrderParameters.endTime;
      baseOrderParameters.endTime = ethers.BigNumber.from(
        baseOrderParameters.startTime
      ).add(10000);

      expect(
        await validator.validateTime(baseOrderParameters)
      ).to.include.deep.ordered.members([[], ["Order not yet active"]]);
    });

    it("Success", async function () {
      expect(
        await validator.validateTime(baseOrderParameters)
      ).to.include.deep.ordered.members([[], []]);
    });

    it("End time must be after start", async function () {
      baseOrderParameters.startTime = ethers.BigNumber.from(
        baseOrderParameters.endTime
      ).add(100);

      expect(
        await validator.validateTime(baseOrderParameters)
      ).to.include.deep.ordered.members([
        ["endTime must be after startTime"],
        [],
      ]);
    });

    it("Duration less than 10 minutes", async function () {
      baseOrderParameters.startTime = Math.round(
        Date.now() / 1000 - 1000
      ).toString();
      baseOrderParameters.endTime = Math.round(
        Date.now() / 1000 + 10
      ).toString();

      expect(
        await validator.validateTime(baseOrderParameters)
      ).to.include.deep.ordered.members([
        [],
        ["Order duration is less than 30 minutes"],
      ]);
    });

    it("Expire in over 30 weeks", async function () {
      baseOrderParameters.endTime = Math.round(
        Date.now() / 1000 + 60 * 60 * 24 * 7 * 35
      ).toString();
      expect(
        await validator.validateTime(baseOrderParameters)
      ).to.include.deep.ordered.members([
        [],
        ["Order will expire in more than 30 weeks"],
      ]);
    });
  });

  describe("Validate Offer Items", function () {
    it("Zero offer items", async function () {
      const order: OrderStruct = {
        parameters: baseOrderParameters,
        signature: "0x",
      };

      expect(
        await validator.validateOfferItems(order.parameters)
      ).to.include.deep.ordered.members([["Need at least one offer item"], []]);
    });

    it("more than one offer items", async function () {
      await erc20_1.mint(owner.address, "4");
      await erc20_1.approve(CROSS_CHAIN_SEAPORT_ADDRESS, "4");

      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1",
          endAmount: "1",
        },
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "2",
          endAmount: "2",
        },
      ];

      expect(
        await validator.validateOfferItems(baseOrderParameters)
      ).to.include.deep.ordered.members([[], ["More than one offer item"]]);
    });

    it("ETH offer warning", async function () {
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
        await validator.validateOfferItems(order.parameters)
      ).to.include.deep.ordered.members([[], ["ETH offer item"]]);
    });

    it("invalid item", async function () {
      const order: OrderStruct = {
        parameters: baseOrderParameters,
        signature: "0x",
      };

      order.parameters.offer = [
        {
          itemType: 6,
          token: NULL_ADDRESS,
          identifierOrCriteria: "0",
          startAmount: "1",
          endAmount: "1",
        },
      ];

      await expect(validator.validateOfferItems(order.parameters)).to.be
        .reverted;
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([["no token approval"], []]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([
          ["not owner of token", "no token approval"],
          [],
        ]);

        await erc721_1.mint(otherAccounts[0].address, 2);
        expect(
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([
          ["not owner of token", "no token approval"],
          [],
        ]);
      });

      it("Set approval for all", async function () {
        await erc721_1.mint(owner.address, 2);
        await erc721_1.setApprovalForAll(CROSS_CHAIN_SEAPORT_ADDRESS, true);

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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([[], []]);
      });

      it("Set approval for one", async function () {
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([[], []]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([["Invalid ERC721 token"], []]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([["Invalid ERC721 token"], []]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([["Invalid ERC721 token"], []]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([["no token approval"], []]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([
          ["no token approval", "insufficient token balance"],
          [],
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([[], []]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([
          ["insufficient token allowance"],
          [],
        ]);
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([
          ["insufficient token allowance", "insufficient token balance"],
          [],
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
          await validator.validateOfferItems(order.parameters)
        ).to.include.deep.ordered.members([[], []]);
      });
    });
  });

  describe("Validate Zone", async function () {
    let testZone: TestZone;
    beforeEach(async function () {
      const TestZone = await ethers.getContractFactory("TestZone");
      testZone = await TestZone.deploy();
    });

    it("No zone", async function () {
      expect(
        await validator.isValidZone(baseOrderParameters)
      ).to.include.deep.ordered.members([[], []]);
    });

    it("Eoa zone", async function () {
      baseOrderParameters.zone = otherAccounts[1].address;
      expect(
        await validator.isValidZone(baseOrderParameters)
      ).to.include.deep.ordered.members([[], []]);
    });

    it("success", async function () {
      baseOrderParameters.zone = testZone.address;
      expect(
        await validator.isValidZone(baseOrderParameters)
      ).to.include.deep.ordered.members([[], []]);
    });

    it("invalid magic value", async function () {
      baseOrderParameters.zone = testZone.address;
      baseOrderParameters.zoneHash = coder.encode(["uint256"], [3]);
      expect(
        await validator.isValidZone(baseOrderParameters)
      ).to.include.deep.ordered.members([["Zone rejected order"], []]);
    });

    it("zone revert", async function () {
      baseOrderParameters.zone = testZone.address;
      baseOrderParameters.zoneHash = coder.encode(["uint256"], [1]);
      expect(
        await validator.isValidZone(baseOrderParameters)
      ).to.include.deep.ordered.members([["Zone rejected order"], []]);
    });

    it("zone revert2", async function () {
      baseOrderParameters.zone = testZone.address;
      baseOrderParameters.zoneHash = coder.encode(["uint256"], [2]);
      expect(
        await validator.isValidZone(baseOrderParameters)
      ).to.include.deep.ordered.members([["Zone rejected order"], []]);
    });

    it("not a zone", async function () {
      baseOrderParameters.zone = validator.address;
      baseOrderParameters.zoneHash = coder.encode(["uint256"], [1]);
      expect(
        await validator.isValidZone(baseOrderParameters)
      ).to.include.deep.ordered.members([["Zone rejected order"], []]);
    });
  });

  describe("Conduit Validation", async function () {
    it("null conduit", async function () {
      // null conduit key points to seaport
      expect(
        await validator.getApprovalAddress(EMPTY_BYTES32)
      ).to.include.deep.ordered.members([
        CROSS_CHAIN_SEAPORT_ADDRESS,
        [[], []],
      ]);
    });

    it("valid conduit key", async function () {
      expect(
        await validator.getApprovalAddress(OPENSEA_CONDUIT_KEY)
      ).to.include.deep.ordered.members([OPENSEA_CONDUIT_ADDRESS, [[], []]]);
    });

    it("invalid conduit key", async function () {
      expect(
        await validator.getApprovalAddress(
          "0x0000000000000000000000000000000000000000000000000000000000000099"
        )
      ).to.include.deep.ordered.members([
        NULL_ADDRESS,
        [["invalid conduit key"], []],
      ]);
    });

    it("isValidConduit valid", async function () {
      expect(
        await validator.isValidConduit(OPENSEA_CONDUIT_KEY)
      ).to.include.deep.ordered.members([[], []]);
    });

    it("isValidConduit invalid", async function () {
      expect(
        await validator.isValidConduit(
          "0x0000000000000000000000000000000000000000000000000000000000000099"
        )
      ).to.include.deep.ordered.members([["invalid conduit key"], []]);
    });
  });

  describe("Create Merkle Tree", function () {
    it("Test", async function () {
      const res = await validator.getMerkleRoot([...Array(10000).keys()]);
    }).timeout(30000);
  });

  describe("Validate Status", async function () {
    it("fully filled", async function () {
      await erc20_1.mint(otherAccounts[0].address, 2000);
      await erc20_1
        .connect(otherAccounts[0])
        .approve(CROSS_CHAIN_SEAPORT_ADDRESS, 2000);

      baseOrderParameters.offerer = otherAccounts[0].address;
      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1000",
          endAmount: "1000",
        },
      ];

      const order: OrderStruct = await signOrder(
        baseOrderParameters,
        otherAccounts[0]
      );

      await seaport.fulfillOrder(order, EMPTY_BYTES32);

      expect(
        await validator.validateOrderStatus(baseOrderParameters)
      ).to.include.deep.ordered.members([["Order is fully filled"], []]);
    });

    it("Order Cancelled", async function () {
      await erc20_1.mint(owner.address, 1000);
      await erc20_1.approve(CROSS_CHAIN_SEAPORT_ADDRESS, 1000);

      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1000",
          endAmount: "1000",
        },
      ];

      await seaport.cancel([
        await getOrderComponents(baseOrderParameters, owner),
      ]);

      expect(
        await validator.validateOrderStatus(baseOrderParameters)
      ).to.include.deep.ordered.members([["Order cancelled"], []]);
    });
  });

  describe("Full Scope", function () {
    it("success", async function () {
      await erc721_1.mint(otherAccounts[0].address, 1);
      await erc20_1.mint(owner.address, 1000);
      await erc20_1.approve(CROSS_CHAIN_SEAPORT_ADDRESS, 1000);

      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1000",
          endAmount: "1000",
        },
      ];
      baseOrderParameters.consideration = [
        {
          itemType: ItemType.ERC721,
          token: erc721_1.address,
          identifierOrCriteria: "1",
          startAmount: "1",
          endAmount: "1",
          recipient: owner.address,
        },
      ];

      const order: OrderStruct = {
        parameters: baseOrderParameters,
        signature: "0x",
      };

      await seaport.validate([order]);

      expect(
        await validator.callStatic.isValidOrder(order)
      ).to.include.deep.ordered.members([[], []]);
    });

    it("no sig", async function () {
      await erc721_1.mint(otherAccounts[0].address, 1);
      await erc20_1.mint(owner.address, 1000);
      await erc20_1.approve(CROSS_CHAIN_SEAPORT_ADDRESS, 1000);

      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1000",
          endAmount: "1000",
        },
      ];
      baseOrderParameters.consideration = [
        {
          itemType: ItemType.ERC721,
          token: erc721_1.address,
          identifierOrCriteria: "1",
          startAmount: "1",
          endAmount: "1",
          recipient: owner.address,
        },
      ];

      const order: OrderStruct = {
        parameters: baseOrderParameters,
        signature: "0x",
      };

      expect(
        await validator.callStatic.isValidOrder(order)
      ).to.include.deep.ordered.members([["invalid signature"], []]);
    });
  });

  describe("Protocol Fee Recipient", function () {
    it("success bid", async function () {
      const feeRecipient = "0x0000000000000000000000000000000000000FEE";
      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1000",
          endAmount: "1000",
        },
      ];
      baseOrderParameters.consideration = [
        {
          itemType: ItemType.ERC721,
          token: erc721_1.address,
          identifierOrCriteria: "1",
          startAmount: "1",
          endAmount: "1",
          recipient: owner.address,
        },
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "25",
          endAmount: "25",
          recipient: feeRecipient,
        },
      ];

      expect(
        await validator.validateFeeRecipients(
          baseOrderParameters,
          feeRecipient,
          "250"
        )
      ).to.include.deep.ordered.members([[], []]);
    });

    it("success ask", async function () {
      const feeRecipient = "0x0000000000000000000000000000000000000FEE";
      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC721,
          token: erc721_1.address,
          identifierOrCriteria: "1",
          startAmount: "1",
          endAmount: "1",
        },
      ];
      baseOrderParameters.consideration = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1000",
          endAmount: "1000",
          recipient: owner.address,
        },
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "25",
          endAmount: "25",
          recipient: feeRecipient,
        },
      ];

      expect(
        await validator.validateFeeRecipients(
          baseOrderParameters,
          feeRecipient,
          "250"
        )
      ).to.include.deep.ordered.members([[], []]);
    });

    it("mismatch", async function () {
      baseOrderParameters.offer = [
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "1000",
          endAmount: "1000",
        },
      ];
      baseOrderParameters.consideration = [
        {
          itemType: ItemType.ERC721,
          token: erc721_1.address,
          identifierOrCriteria: "1",
          startAmount: "1",
          endAmount: "1",
          recipient: owner.address,
        },
        {
          itemType: ItemType.ERC20,
          token: erc20_1.address,
          identifierOrCriteria: "0",
          startAmount: "25",
          endAmount: "25",
          recipient: owner.address,
        },
      ];

      expect(
        await validator.validateFeeRecipients(
          baseOrderParameters,
          feeRecipient,
          "250"
        )
      ).to.include.deep.ordered.members([
        ["Protocol fee recipient mismatch"],
        [],
      ]);

      baseOrderParameters.consideration[1] = {
        itemType: ItemType.ERC20,
        token: erc20_1.address,
        identifierOrCriteria: "0",
        startAmount: "24",
        endAmount: "25",
        recipient: feeRecipient,
      };

      expect(
        await validator.validateFeeRecipients(
          baseOrderParameters,
          feeRecipient,
          "250"
        )
      ).to.include.deep.ordered.members([
        ["Protocol fee start amount too low"],
        [],
      ]);

      baseOrderParameters.consideration[1] = {
        itemType: ItemType.ERC20,
        token: erc20_1.address,
        identifierOrCriteria: "0",
        startAmount: "25",
        endAmount: "24",
        recipient: feeRecipient,
      };

      expect(
        await validator.validateFeeRecipients(
          baseOrderParameters,
          feeRecipient,
          "250"
        )
      ).to.include.deep.ordered.members([
        ["Protocol fee end amount too low"],
        [],
      ]);

      baseOrderParameters.consideration[1] = {
        itemType: ItemType.ERC20,
        token: erc721_1.address,
        identifierOrCriteria: "0",
        startAmount: "25",
        endAmount: "25",
        recipient: feeRecipient,
      };
      expect(
        await validator.validateFeeRecipients(
          baseOrderParameters,
          feeRecipient,
          "250"
        )
      ).to.include.deep.ordered.members([["Protocol fee token mismatch"], []]);

      baseOrderParameters.consideration[1] = {
        itemType: ItemType.NATIVE,
        token: erc20_1.address,
        identifierOrCriteria: "0",
        startAmount: "25",
        endAmount: "25",
        recipient: feeRecipient,
      };
      expect(
        await validator.validateFeeRecipients(
          baseOrderParameters,
          feeRecipient,
          "250"
        )
      ).to.include.deep.ordered.members([
        ["Protocol fee item type mismatch"],
        [],
      ]);
    });
  });

  async function signOrder(
    orderParameters: OrderParametersStruct,
    signer: SignerWithAddress
  ): Promise<OrderStruct> {
    const sig = await signer._signTypedData(
      {
        name: "Seaport",
        version: "1.1",
        chainId: "1",
        verifyingContract: seaport.address,
      },
      EIP_712_ORDER_TYPE,
      await getOrderComponents(orderParameters, signer)
    );

    return {
      parameters: baseOrderParameters,
      signature: sig,
    };
  }

  async function getOrderComponents(
    orderParameters: OrderParametersStruct,
    signer: SignerWithAddress
  ): Promise<OrderComponentsStruct> {
    return {
      ...orderParameters,
      counter: await seaport.getCounter(signer.address),
    };
  }
});
