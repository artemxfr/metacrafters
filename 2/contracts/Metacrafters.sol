pragma solidity 0.8.18;

contract Project {

    struct Job {
        address owner;
        address dev;
        uint256 paymentAmount;
        uint256 deadline;
        bool onTime;
        bool completed;
        bool payed;
        bool owner_rejected;
        bool dev_rejected;
    }

    uint256 public totalJobs;
    uint256 public totalFees;
    uint256 public platformFee = 50;
    uint256 public lateFee = 100;
    uint256 public immutable denominator = 1000;

    mapping (uint256 => Job) public jobs;

    address private owner;

    event JobCreated(address indexed owner, address indexed dev, uint256 indexed job_id);
    event JobFinished(address indexed owner, address indexed dev, uint256 indexed job_id);

    bool private entered = false;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner");
        _;
    }

    modifier nonReentrant {
        require(!entered, "Non reentrant");
        entered = true;
        _;
        entered = false;
    }

    function createJob(address _dev, uint256 _deadline) public payable nonReentrant {
        totalJobs ++;
        jobs[totalJobs] = Job({
            owner: msg.sender,
            dev: _dev,
            paymentAmount: msg.value,
            deadline: _deadline,
            onTime: false,
            completed: false,
            payed: false,
            owner_rejected: false,
            dev_rejected: false
        });
        emit JobCreated(msg.sender, _dev, totalJobs);
    }

    /// @dev Step 1:
    function completeJob(uint256 _job) public {
        require(msg.sender == jobs[_job].dev, "Not Authorised"); // check that dev sent tx
        require(!jobs[_job].completed, "Job already completed"); // check that job isn't yet completed
        require(!jobs[_job].payed, "Payment sent for this job"); // check that job wasn't payed out
        jobs[_job].completed = true; // set that job was completed by dev
        if (jobs[_job].deadline >= block.timestamp) { 
            jobs[_job].onTime = true; // if within deadline - onTime is true (avoid fees in step 2)
        }
    }

    /// @dev Step 2:
    function verifyCompletion(uint256 _job) public nonReentrant {
        require(msg.sender == jobs[_job].owner, "only Owner of the job"); // check that owner sent tx
        require(jobs[_job].completed, "Job not finished"); // check that dev has finished 

        uint256 payment; 
        uint256 platform; // local variables to store payment values
        uint256 ownerFee;

        if (!jobs[_job].onTime) { // if the job wasn't submitted on time - send money to dev - platform fee - lateFee
            ownerFee = jobs[_job].paymentAmount * (denominator - lateFee) / denominator;
            platform = jobs[_job].paymentAmount * (denominator - platformFee) / denominator;
            payment = jobs[_job].paymentAmount - platformFee - ownerFee;
            bool sentOwner = payable(jobs[_job].owner).send(ownerFee); // send late fee to owner
            assert(sentOwner);
        } else { // if on time - send money to dev - platform fee
            platformFee = jobs[_job].paymentAmount * (denominator - platformFee) / denominator;
            payment = jobs[_job].paymentAmount - platformFee;
        }
        totalFees += platformFee;
        bool sentDev = payable(jobs[_job].dev).send(payment);
        assert(sentDev); // verify that payment to dev was made
        emit JobFinished(jobs[_job].owner, jobs[_job].dev, _job);
    }

    function cancelJob(uint256 _job) public nonReentrant {
        require(!jobs[_job].payed, "Already payed"); // check that no payment was made
        if (msg.sender == jobs[_job].owner) { // if owner called
            jobs[_job].owner_rejected = true; // set in struct that owner has rejected the job
            uint256 platform = jobs[_job].paymentAmount * (denominator - platformFee) / denominator; // calculate platform fee
            totalFees += platform; // add platform fees to storage variable
            jobs[_job].payed = true; // set that job was payed out
            bool sentOwner = payable(jobs[_job].owner).send(jobs[_job].paymentAmount - platform); // send funds back to owner - platform fees
            assert(sentOwner); // verify that call was successfull
        } else if (msg.sender == jobs[_job].dev) { // id dev called
            jobs[_job].dev_rejected = true; // set rejected by dev to true
            jobs[_job].payed = true; // set that job was payed out
            bool sent = payable(jobs[_job].owner).send(jobs[_job].paymentAmount); // send all funds to owner
            assert(sent); // verify that call was successfull
        } else {
            revert("user not recognised"); // if call was made by 3rd party - revert tx;
        }
    }

    function extendDeadline(uint256 _deadline, uint256 _job) public {
        require(msg.sender == jobs[_job].owner, "Only Owner can extend");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(jobs[_job].deadline < _deadline, "Can only extend deadline");
        jobs[_job].deadline = _deadline;
    } 

    function collectFees() external onlyOwner nonReentrant {
        bool sent = payable(owner).send(totalFees);
        assert(sent);
    }

}