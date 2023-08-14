import { ethers } from 'hardhat';
import { expect } from 'chai';
import { Contract, Signer, utils } from "ethers";

let cappedSet: Contract;
let addr: Signer[];
let zeroAddress: any;
describe('YourContract', () => {
    it('should revert when _numElements is not greater than zero', async () => {
        const CappedSet = await ethers.getContractFactory('CappedSet');
        // Deploy the contract with an invalid input
        await expect(CappedSet.deploy(0)).to.be.revertedWith('Max elements must be greater than zero');
    });
});
describe('CappedSet', () => {
    beforeEach(async () => {
        addr = await ethers.getSigners();
        const CappedSet = await ethers.getContractFactory('CappedSet');
        cappedSet = await CappedSet.deploy(10);
        await cappedSet.deployed();
        zeroAddress = utils.getAddress('0x0000000000000000000000000000000000000000');
    });

    it('should insert one new element', async () => {
        await expect(cappedSet.insert(addr[0].getAddress(), 100))
            .to.emit(cappedSet, "lowestElement")
            .withArgs(await addr[0].getAddress(), 100);
    });

    it('should update one existing element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await expect(cappedSet.update(addr[0].getAddress(), 50))
            .to.emit(cappedSet, "lowestElement")
            .withArgs(await addr[0].getAddress(), 50);
    });

    it('should remove one existing element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await expect(cappedSet.remove(addr[0].getAddress()))
            .to.emit(cappedSet, "lowestElement")
            .withArgs(zeroAddress, 0);
    });

    it('should get the value of an existing element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        const value = await cappedSet.getValue(addr[0].getAddress());
        await expect(value).to.be.equal(100);
    });

    it('should handle inserting an existing element by updating its value', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.insert(addr[0].getAddress(), 600);
        const value = await cappedSet.getValue(addr[0].getAddress());
        await expect(value).to.be.equal(600);
    });

    it('should handle inserting an element with the same value as the head element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.insert(addr[5].getAddress(), 100);
        const value = await cappedSet.getValue(addr[5].getAddress());
        await expect(value).to.be.equal(100);
    });

    it('should handle inserting an existed element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.insert(addr[2].getAddress(), 200);
        const value = await cappedSet.getValue(addr[2].getAddress());
        await expect(value).to.be.equal(200);
    });

    it('should handle inserting an element with a value greater than the head element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.insert(addr[5].getAddress(), 600);
        const value = await cappedSet.getValue(addr[5].getAddress());
        await expect(value).to.be.equal(600);
    });

    it("should handle updating an middle element a value greater than largest value", async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.update(addr[1].getAddress(), 700);
        const value = await cappedSet.getValue(addr[1].getAddress());
        await expect(value).to.be.equal(700);
    });

    it("should handle updating an middle element a value greater than it's value", async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.update(addr[1].getAddress(), 350);
        const value = await cappedSet.getValue(addr[1].getAddress());
        await expect(value).to.be.equal(350);
    });

    it("should handle updating an middle element a value smaller than it's value", async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.update(addr[3].getAddress(), 150);
        const value = await cappedSet.getValue(addr[3].getAddress());
        await expect(value).to.be.equal(150);
    });

    it("should handle updating an middle element a value smaller than the head element", async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.update(addr[3].getAddress(), 50);
        const value = await cappedSet.getValue(addr[3].getAddress());
        await expect(value).to.be.equal(50);
    });

    it('should handle removing the head element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.remove(addr[0].getAddress());
        const value = await cappedSet.getValue(addr[1].getAddress());
        await expect(value).to.be.equal(200);
    });

    it('should handle removing a non-head element', async () => {
        await cappedSet.insert(addr[0].getAddress(), 100);
        await cappedSet.insert(addr[1].getAddress(), 200);
        await cappedSet.insert(addr[2].getAddress(), 300);
        await cappedSet.insert(addr[3].getAddress(), 400);
        await cappedSet.insert(addr[4].getAddress(), 500);
        await cappedSet.remove(addr[2].getAddress());
        const value = await cappedSet.getValue(addr[3].getAddress());
        await expect(value).to.be.equal(400);
    });

    it('should revert when trying to update a non-existing element', async () => {
        await expect(cappedSet.update(addr[0].getAddress(), 50)).to.be.revertedWith("Element doesn't exist");
    });

    it('should revert when trying to remove a non-existing element', async () => {
        await expect(cappedSet.remove(addr[0].getAddress())).to.be.revertedWith("Element doesn't exist");
    });

    it('should revert when trying to get the value of a non-existing element', async () => {
        await expect(cappedSet.getValue(addr[0].getAddress())).to.be.revertedWith("Element does not exist");
    });

    it('should revert when trying to insert 0 value', async () => {
        await expect(cappedSet.insert(addr[0].getAddress(), 0)).to.be.revertedWith("Value must be greater than zero");
    });

    it('should revert when trying to update to 0 value', async () => {
        await expect(cappedSet.update(addr[0].getAddress(), 0)).to.be.revertedWith("Value must be greater than zero");
    });

    it('should revert when trying to insert zeroAddress', async () => {
        await expect(cappedSet.insert(zeroAddress, 100)).to.be.revertedWith("Address cannot be zero");
    });

    it('should revert when trying to update zeroAddress', async () => {
        await expect(cappedSet.update(zeroAddress, 100)).to.be.revertedWith("Address cannot be zero");
    });

    it('should revert when trying to remove zeroAddress', async () => {
        await expect(cappedSet.remove(zeroAddress)).to.be.revertedWith("Address cannot be zero");
    });

    it('should insert more than max count and remove lowest', async () => {
        for (let i = 0; i < 13; i++) await cappedSet.insert(addr[i].getAddress(), 100 * i + 100);
    });

});