import { useState } from 'react';
import './App.css';

import abi from './contractAbi.json';

import { ethers } from "ethers";
import {format} from 'date-fns';

function App() {

  let contractAddress = '0xed8F2aF05f40614bAA80A587158d06BB2104934a';

  const [userAccount, setUserAccount] = useState(null);
  const [errorMessage, setErrorMessage] = useState(null);

  const [provider, setProvider] = useState(null);
	const [signer, setSigner] = useState(null);
	const [contract, setContract] = useState(null);

  const [jobDetails, setJobDetails] = useState([]);
  const [endTime, setEndTime] = useState(0);
  const [jobDetailsError, setJobDetailsError] = useState("");

  const connectWalletHandler = () => {
		if (window.ethereum && window.ethereum.isMetaMask) {
			console.log('MetaMask Here!');

			window.ethereum.request({ method: 'eth_requestAccounts'})
			.then(result => {
				accountChangedHandler(result[0]);
			})
			.catch(error => {
				setErrorMessage(error.message);
			});


      let tempProvider = new ethers.providers.Web3Provider(window.ethereum);
      setProvider(tempProvider);

      let tempSigner = tempProvider.getSigner();
      setSigner(tempSigner);

      let tempContract = new ethers.Contract(contractAddress, abi, tempSigner);
      setContract(tempContract);	

		} else {
			console.log('Need to install MetaMask');
			setErrorMessage('Please install MetaMask browser extension to interact');
		}
	}

	// update account, will cause component re-render
	const accountChangedHandler = (newAccount) => {
		setUserAccount(newAccount);
	}

  const chainChangedHandler = () => {
		// reload the page to avoid any errors with chain change mid use of application
		window.location.reload();
	}

  const getJobDetails = async(e) => {
    e.preventDefault();
    let jobDetails = await contract.jobs(e.target.inputJobId.value);
    if (jobDetails[0] !== '0x0000000000000000000000000000000000000000') {
      setJobDetails(jobDetails);
      handleTime(jobDetails[3]);
    } else {
      setJobDetails([]);
      setJobDetailsError("Job doesn't exist");
    }

  }

  const handleTime = async(time) => {
    var tt = format(new Date(parseFloat(time+'000')), 'HH:mm dd MMM y')
    setEndTime(tt);
  }

  const createJob = async(e) => {
    e.preventDefault();
    let EndDate = Math.floor(new Date(e.target.endDate.value).getTime() / 1000);
    try {
      let txId = await contract.createJob(e.target.devaddress.value, EndDate, {value: ethers.utils.parseUnits(e.target.value.value.toString(), "ether")});
      window.alert('Success! TX Hash: '+txId);
    } catch (e) {
      window.alert('Error! '+e.message)
    }

  }


	// listen for account changes
	window.ethereum.on('accountsChanged', accountChangedHandler);

	window.ethereum.on('chainChanged', chainChangedHandler);

  return (
    <div className="App">
      <div className='App-header'>
        <h1>Solidity Gigs</h1>
        <p>All-in-1 Solidity freelance escrow platform</p>
        <div>
          {userAccount === null ? (
            <button onClick={connectWalletHandler}>Connect Wallet</button>
          ) : (
            <div>
              <div>
                <form onSubmit={getJobDetails}>
                  <p>Check job details by JobID</p>
                  <input id='inputJobId' type='number' placeholder='Job Id'></input>
                  <button>Look up</button>
                </form>
                {jobDetails.length !== 0 ? (
                  <div>
                    <h3>Job details:</h3>
                    <table>
                      <tr>
                        <th style={{textAlign: 'left'}}>Owner</th>
                        <td style={{textAlign: 'right'}}>{jobDetails[0]}</td>
                      </tr>
                      <tr>
                        <th style={{textAlign: 'left'}}>Dev</th>
                        <td style={{textAlign: 'right'}}>{jobDetails[1]}</td>
                      </tr>
                      <tr>
                        <th style={{textAlign: 'left'}}>Payment Amount</th>
                        <td style={{textAlign: 'right'}}>{ethers.utils.formatEther(jobDetails[2])} BNB</td>
                      </tr> 
                      <tr>
                        <th style={{textAlign: 'left'}}>Deadline</th>
                        <td style={{textAlign: 'right'}}>{endTime}</td>
                      </tr>
                    </table>
                  </div>
                ) : (
                  <p>{jobDetailsError !== "" ? ('Error: '+jobDetailsError) : (null)}</p>
                )}
              </div>
              <div className='createjob'>
                  <h3>Create Job:</h3>
                  <form onSubmit={createJob}>
                    <p style={{marginBottom: '0px', textAlign: 'left', }}>Dev Address: </p>
                    <input type="text" maxLength={42} id="devaddress" placeholder='Input Dev. Address'></input>
                    <p style={{marginBottom: '0px', textAlign: 'left', }}>Deadline:</p>
                    <input type="datetime-local" id="endDate" placeholder='Select Date'></input>
                    <p style={{marginBottom: '0px', textAlign: 'left', }}>Payment Amount:</p>
                    <input type="decimal" id="value" placeholder='Enter Payment Amount'></input>
                    <button>Create!</button>
                  </form>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
