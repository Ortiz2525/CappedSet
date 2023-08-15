// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CappedSet {
    struct Element {
        address addr;
        uint256 value;
        uint256 next; //index of next element.
    }

    uint256 private constant NULL_INDEX = 0;
    uint256 private HEAD_INDEX = 0;

    uint256 private numElements; //element count.
    uint256 private lastIndex;
    uint256 private maxElements; //max element count.
    mapping(uint256 => Element) private elements;

    event lowestElement(address addr, uint256 value);

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
        // If _addr exist in elements, update it's value.
        // elements[prevAddrIndex].next != NULL_INDEX means prevIndex of element exist, so _addr exist in elements.
        // if _addr is same with addr of  HEAD element, prevIndex of head element doesn't exist so should add this case.
        if (elements[prevAddrIndex].next != NULL_INDEX || (elements[HEAD_INDEX].addr == _addr)) {
            (address lowestAddr, uint256 lowestValue) = update(_addr, _value);
            return (lowestAddr, lowestValue);
        }
        uint256 prevIndex = findPrevIndex(_value);
        uint256 newIndex = ++lastIndex;
        numElements++;
        // If there isn't any element (HEAD_INDEX == 0) or new value is same with value of HEADINDEX,
        // should set new Index to HEAD_INDEX.
        if (prevIndex == 0) {
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
        emit lowestElement(elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
        return
            (elements[HEAD_INDEX].next == NULL_INDEX)
                ? (address(0), 0)
                : (elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
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
        uint256 currentIndex = elements[prevIndex].next;
        //if _addr is same with addr of HEAD element, set HEAD value to _newVal.
        if (prevIndex == 0 && numElements > 0) {
            elements[HEAD_INDEX].value = _newVal;
        } else {
            require(elements[prevIndex].next != NULL_INDEX, "Element doesn't exist");

            //find location of _newVal.
            uint256 prevValIndex = findPrevIndex(_newVal); //prev index of location of _newVal.
            elements[currentIndex].value = _newVal;
            if (prevValIndex == 0) {
                //if _newVal is same with or smaller than value of HEAD element
                HEAD_INDEX = currentIndex;
                elements[currentIndex].next = HEAD_INDEX;
            } else if (
                (elements[currentIndex].next != NULL_INDEX &&
                    _newVal > elements[elements[currentIndex].next].value) ||
                _newVal < elements[prevIndex].value
            ) {
                //if new _newVal smaller than value of previous element or greater tahn value of next element
                elements[prevIndex].next = elements[currentIndex].next; //link the previous and next elements of the old currentIndex element
                elements[currentIndex].next = elements[prevValIndex].next; // update nextIndex of currentIndex element
                elements[prevValIndex].next = currentIndex; //link preValIndex element to new currentIndex element.
            }
            // In other cases, location of currentIndex element same with previous location.
        }
        emit lowestElement(elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
        return (elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
    }

    /**
     * @dev Function to remove element based on its address.
     * @param _addr The address of the element.
     * @return The address and value of the new lowest value element.
     */
    function remove(address _addr) public returns (address, uint256) {
        require(_addr != address(0), "Address cannot be zero");
        uint256 prevIndex = findPrevIndex(_addr);

        //if _addr is same with addr of HEAD element, set HEAD to next element.
        if (prevIndex == 0 && numElements > 0) {
            HEAD_INDEX = elements[HEAD_INDEX].next;
        } else {
            require(elements[prevIndex].next != NULL_INDEX, "Element doesn't exist");
            elements[prevIndex].next = elements[elements[prevIndex].next].next;
        }
        --numElements;
        emit lowestElement(elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
        return (elements[HEAD_INDEX].addr, elements[HEAD_INDEX].value);
    }

    /**
     * @dev Function to get the value of an element.
     * @param _addr The address of the element.
     * @return The value of the element.
     */
    function getValue(address _addr) public view returns (uint256) {
        if (elements[HEAD_INDEX].addr == _addr) return elements[HEAD_INDEX].value;
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
        if (_value <= elements[HEAD_INDEX].value) return 0;
        uint256 prevIndex = HEAD_INDEX;

        while (
            elements[prevIndex].next != NULL_INDEX &&
            elements[elements[prevIndex].next].value < _value
        ) {
            prevIndex = elements[prevIndex].next;
        }
        return prevIndex;
    }

    /**
     * @dev Function to find the previous index of an element based on its address.
     * @param _addr The address of the element.
     * @return The previous index of the element.
     */
    function findPrevIndex(address _addr) private view returns (uint256) {
        if (elements[HEAD_INDEX].addr == _addr) return 0;
        uint256 prevIndex = HEAD_INDEX;

        while (
            elements[prevIndex].next != NULL_INDEX &&
            elements[elements[prevIndex].next].addr != _addr
        ) {
            prevIndex = elements[prevIndex].next;
        }
        return prevIndex;
    }
}
