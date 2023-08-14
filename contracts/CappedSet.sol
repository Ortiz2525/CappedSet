// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CappedSet {
    struct Element {
        address addr;
        uint256 value;
        uint256 next;   //index of next element.
    }

    uint256 constant private NULL_INDEX = 0;
    uint256 private HEAD_INDEX = 0;

    uint256 private numElements;    //element count.
    uint256 private lastIndex;     
    uint256 private maxElements;    //max element count.
    mapping(uint256 => Element) private elements;


    /**
     * @dev Constructor to initialize the contract.
     * @param _numElements The maximum number of elements allowed in the contract.
     */
    constructor(uint256 _numElements) {
        require(_numElements > 0, "Max elements must be greater than zero");
        maxElements = _numElements;
        numElements = 0;
        lastIndex = 0;
        elements[HEAD_INDEX] = Element(address(0), 0, NULL_INDEX);
    }

    /**
     * @dev Function to add a new element to the contract.
     * @param _addr The address of the element.
     * @param _value The value of the element.
     * @return The address and value of the new lowest value element.
     */
    function insert(address _addr, uint256 _value) public returns (address, uint256) {
        require(_addr != address(0), "Address cannot be zero");
        require(_value > 0, "Value must be greater than zero");

        uint256 prevAddrIndex = findPrevIndex(_addr);
        // If address exist, update value
        if(elements[prevAddrIndex].next != NULL_INDEX) {
            (address lowestAddr, uint256 lowestValue)=update(_addr, _value);
            return (lowestAddr, lowestValue);
        }
        uint256 prevIndex = findPrevIndex(_value);
        uint256 newIndex = ++lastIndex;
        numElements++;
        // If there isn't any element (HEAD_INDEX == 0), or new value is same with value of HEADINDEX
        if(prevIndex == 0) {
            elements[newIndex] = Element(_addr, _value, HEAD_INDEX);
            HEAD_INDEX = newIndex;
        } else {
            elements[newIndex] = Element(_addr, _value, elements[prevIndex].next);
            elements[prevIndex].next = newIndex;
        } 
        // If the element count reaches maxCount, remove lowest one.
        if (numElements > maxElements) {
            HEAD_INDEX = elements[HEAD_INDEX].next;
            numElements--;
        }

        return (elements[HEAD_INDEX].next == NULL_INDEX) ? 
        (address(0), 0) : (elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
    }
    /**
     * @dev Function to update the value of an existing element.
     * @param _addr The address of the element.
     * @param _newVal The new value for the element.
     * @return The address and value of the new lowest value element.
     */
    function update(address _addr, uint256 _newVal) public returns (address, uint256) {
        require(_addr != address(0), "Address cannot be zero");
        require(_newVal > 0, "Value must be greater than zero");

        uint256 prevIndex = findPrevIndex(_addr);
        require(elements[prevIndex].next != NULL_INDEX,"Element doesn't exist");
        uint256 prevValIndex = findPrevIndex(_newVal);
        uint256 currentIndex = elements[prevIndex].next;

        elements[currentIndex].value = _newVal;
        //if new Value smaller than previous element value.
        if(_newVal < elements[prevIndex].value) {
            elements[prevIndex].next=elements[currentIndex].next; //link previous element and next element.
            if(prevValIndex == 0) {
                HEAD_INDEX = currentIndex;
                elements[currentIndex].next = HEAD_INDEX;
            } else {
                elements[currentIndex].next = elements[prevValIndex].next; // update nextIndex.
                elements[prevValIndex].next = currentIndex; //link preValElement to current element.
            }
        }
        //if new Value bigger than previous element value.
        else if(elements[currentIndex].next != NULL_INDEX && _newVal > elements[elements[currentIndex].next].value) {
            elements[prevIndex].next=elements[currentIndex].next; //link previous element and next element.
            elements[currentIndex].next = elements[prevValIndex].next; // update nextIndex.
            elements[prevValIndex].next = currentIndex; //link preValElement to current element.
        }

        return  (elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
    }

    /**
     * @dev Function to remove element based on its address.
     * @param _addr The address of the element.
     * @return The address and value of the new lowest value element.
     */
    function remove(address _addr) public returns (address, uint256) {
        require(_addr != address(0), "Address cannot be zero");
        uint256 prevIndex = findPrevIndex(_addr);
        require(elements[prevIndex].next != NULL_INDEX, "Element doesn't exist"); 
        if(prevIndex == 0) {
            HEAD_INDEX = elements[HEAD_INDEX].next;
        } else {
            elements[prevIndex].next = elements[elements[prevIndex].next].next;
        }
        --numElements;
        return (elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
    }

    /**
     * @dev Function to get the value of an element.
     * @param _addr The address of the element.
     * @return The value of the element.
     */
    function getValue(address _addr) public view returns (uint256) {
        uint256 currentIndex = elements[HEAD_INDEX].next;

        while (currentIndex != NULL_INDEX) {
            if (elements[currentIndex].addr == _addr) {
                return elements[currentIndex].value;
            }
            currentIndex = elements[currentIndex].next;
        }

        revert("Element does not exist");
    }

    /**
     * @dev Function to find the previous index of an element based on its value.
     * @param _value The value of the element.
     * @return The previous index of the element.
     */
    function findPrevIndex(uint256 _value) private view returns (uint256) {
        require(_value >= elements[HEAD_INDEX].value,"prevIndex doesn't exist");
        if(_value == elements[HEAD_INDEX].value || HEAD_INDEX == 0) return 0;
        uint256 currentIndex = HEAD_INDEX;

        while (elements[currentIndex].next != NULL_INDEX && elements[elements[currentIndex].next].value < _value) {
            currentIndex = elements[currentIndex].next;
        }
        return currentIndex;
    }

    /**
     * @dev Function to find the previous index of an element based on its address.
     * @param _addr The address of the element.
     * @return The previous index of the element.
     */
    function findPrevIndex(address _addr) private view returns (uint256) {
        if(elements[HEAD_INDEX].addr == _addr) return 0;
        uint256 currentIndex = HEAD_INDEX;

        while (elements[currentIndex].next != NULL_INDEX && elements[elements[currentIndex].next].addr != _addr) {
            currentIndex = elements[currentIndex].next;
        }
        return currentIndex;
    }
}
