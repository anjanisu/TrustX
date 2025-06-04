// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TrustX {
    // Struct for freelancer profile
    struct Freelancer {
        address freelancerAddress;
        uint256 rating; // Average rating (0-5, scaled to 50 for precision)
        uint256 jobCount;
        bool isVerified; // AI verification status
    }

    // Struct for job
    struct Job {
        uint256 jobId;
        address client;
        address freelancer;
        uint256 amount;
        string deliverables; // IPFS hash or description
        bool isCompleted;
        bool isDisputed;
        uint256 deadline;
    }

    // Mappings
    mapping(address => Freelancer) public freelancers;
    mapping(uint256 => Job) public jobs;
    uint256 public jobCounter;

    // Events
    event JobCreated(uint256 jobId, address client, address freelancer, uint256 amount);
    event JobCompleted(uint256 jobId, string deliverables);
    event FundsReleased(uint256 jobId, address freelancer, uint256 amount);
    event RatingSubmitted(address freelancer, uint256 rating);
    event ProfileVerificationRequested(address freelancer);
    event ProfileVerified(address freelancer, bool isVerified);
    event DisputeRaised(uint256 jobId, address raiser);

    // Modifiers
    modifier onlyClient(uint256 _jobId) {
        require(msg.sender == jobs[_jobId].client, "Only client can call this");
        _;
    }

    modifier onlyFreelancer(uint256 _jobId) {
        require(msg.sender == jobs[_jobId].freelancer, "Only freelancer can call this");
        _;
    }

    // Create a new job
    function createJob(address _freelancer, uint256 _deadline) external payable {
        require(msg.value > 0, "Payment required");
        require(freelancers[_freelancer].freelancerAddress != address(0), "Freelancer not registered");
        require(freelancers[_freelancer].isVerified, "Freelancer not verified");

        jobCounter++;
        jobs[jobCounter] = Job({
            jobId: jobCounter,
            client: msg.sender,
            freelancer: _freelancer,
            amount: msg.value,
            deliverables: "",
            isCompleted: false,
            isDisputed: false,
            deadline: _deadline
        });

        emit JobCreated(jobCounter, msg.sender, _freelancer, msg.value);
    }

    // Freelancer submits deliverables
    function submitDeliverables(uint256 _jobId, string memory _deliverables) external onlyFreelancer(_jobId) {
        Job storage job = jobs[_jobId];
        require(!job.isCompleted, "Job already completed");
        require(!job.isDisputed, "Job is disputed");

        job.deliverables = _deliverables;
        job.isCompleted = true;

        emit JobCompleted(_jobId, _deliverables);
    }

    // Client releases funds
    function releaseFunds(uint256 _jobId) external onlyClient(_jobId) {
        Job storage job = jobs[_jobId];
        require(job.isCompleted, "Job not completed");
        require(!job.isDisputed, "Job is disputed");

        address payable freelancer = payable(job.freelancer);
        freelancer.transfer(job.amount);

        emit FundsReleased(_jobId, job.freelancer, job.amount);
    }

    // Client or freelancer raises dispute
    function raiseDispute(uint256 _jobId) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client || msg.sender == job.freelancer, "Not authorized");
        require(!job.isCompleted, "Job already completed");
        require(!job.isDisputed, "Dispute already raised");

        job.isDisputed = true;
        emit DisputeRaised(_jobId, msg.sender);
    }

    // Register freelancer
    function registerFreelancer() external {
        require(freelancers[msg.sender].freelancerAddress == address(0), "Already registered");
        freelancers[msg.sender] = Freelancer({
            freelancerAddress: msg.sender,
            rating: 0,
            jobCount: 0,
            isVerified: false
        });
        emit ProfileVerificationRequested(msg.sender);
    }

    // External AI verification (called by off-chain service)
    function verifyProfile(address _freelancer, bool _isVerified) external {
        // In production, restrict this to an authorized AI service address
        Freelancer storage freelancer = freelancers[_freelancer];
        require(freelancer.freelancerAddress != address(0), "Freelancer not registered");
        freelancer.isVerified = _isVerified;
        emit ProfileVerified(_freelancer, _isVerified);
    }

    // Client submits rating
    function submitRating(uint256 _jobId, uint256 _rating) external onlyClient(_jobId) {
        require(_rating <= 5, "Rating must be 0-5");
        Job storage job = jobs[_jobId];
        require(job.isCompleted, "Job not completed");

        Freelancer storage freelancer = freelancers[job.freelancer];
        freelancer.rating = ((freelancer.rating * freelancer.jobCount) + (_rating * 10)) / (freelancer.jobCount + 1);
        freelancer.jobCount++;

        emit RatingSubmitted(job.freelancer, _rating);
    }

    // Get job details
    function getJob(uint256 _jobId) external view returns (Job memory) {
        return jobs[_jobId];
    }

    // Get freelancer details
    function getFreelancer(address _freelancer) external view returns (Freelancer memory) {
        return freelancers[_freelancer];
    }
}