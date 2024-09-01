// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEigenPodManager} from "@eigenlayer-core/contracts/Interfaces/IEigenPodManager.sol";
import {RerollyerLST} from "./RerollyerLST.sol";

contract Rerollyer {
    // Address of the EigenLayer contract
    IEigenPodManager public eigenLayerPodManager;

    // Minimum ETH threshold for L2 deployment
    uint256 public constant MIN_ETH_THRESHOLD = 32 ether;

    // Struct to store information about each project
    struct Project {
        string name;
        string description;
        string lstName;
        string lstSymbol;
        uint256 ethContributed;
        address eigenPodAddress;
        address lst;
        address owner;
        bool isL2Deployed;
        bool exists;
    }

    // Couting of projects
    uint256 public projectIdCount = 0;

    // Mapping of project IDs to Project structs
    mapping(uint256 => Project) public projects;

    // Mapping to track user contributions to projects
    mapping(address => mapping(uint256 => uint256)) public userContributions;

    // Events
    event ProjectCreated(uint256 indexed projectId);
    event Deposit(
        address indexed user,
        uint256 indexed projectId,
        uint256 amount
    );
    event L2Deployed(uint256 indexed projectId);

    modifier onlyProjectOwner(uint256 projectId) {
        require(
            projects[projectId].owner == msg.sender,
            "Only the project owner can call this function"
        );
        _;
    }

    // Constructor to initialize the EigenLayer contract addresses
    constructor(address _eigenLayerPodManager) {
        eigenLayerPodManager = IEigenPodManager(_eigenLayerPodManager);
    }

    // Function to create a project profile
    function createProject(
        string memory _name,
        string memory description,
        string memory _lstName,
        string memory _lstSymbol,
        address _owner
    ) external {
        require(!projects[projectIdCount].exists, "Project already exists");

        address _lst = address(new RerollyerLST(_lstName, _lstSymbol));
        address _eigenPodAddress = eigenLayerPodManager.createPod();

        projects[projectIdCount] = Project({
            name: _name,
            description: description,
            lstName: _lstName,
            lstSymbol: _lstSymbol,
            ethContributed: 0,
            isL2Deployed: false,
            eigenPodAddress: _eigenPodAddress,
            owner: _owner,
            lst: _lst,
            exists: true
        });

        emit ProjectCreated(projectIdCount);

        projectIdCount++;
    }

    // Function for users to deposit ETH and select a project to support
    function deposit(uint256 projectId) external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        require(projects[projectId].exists, "Project does not exist");

        // Update project contributions
        projects[projectId].ethContributed += msg.value;
        userContributions[msg.sender][projectId] += msg.value;

        emit Deposit(msg.sender, projectId, msg.value);
    }

    // Internal function to deploy an L2 solution when the threshold is met
    function deployL2(uint256 projectId) external onlyProjectOwner(projectId) {
        require(
            projects[projectId].ethContributed >= MIN_ETH_THRESHOLD,
            "Not enough ETH to deploy L2"
        );
        require(!projects[projectId].isL2Deployed, "L2 already deployed");

        projects[projectId].isL2Deployed = true;
        emit L2Deployed(projectId);
    }

    // Function to get project details
    function getProjectDetails(
        uint256 projectId
    ) external view returns (uint256 ethContributed, bool isL2Deployed) {
        Project memory project = projects[projectId];
        return (project.ethContributed, project.isL2Deployed);
    }

    // Function to get user contributions to a specific project
    function getUserContribution(
        address user,
        uint256 projectId
    ) external view returns (uint256) {
        return userContributions[user][projectId];
    }

    // Fallback function to handle direct ETH transfers
    receive() external payable {
        revert("Direct transfers not allowed");
    }
}
