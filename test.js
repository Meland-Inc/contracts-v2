const ethers = require('ethers');
const getRevertReason = require('eth-revert-reason')

const provider = new ethers.providers.JsonRpcProvider(`https://polygon-mumbai.g.alchemy.com/v2/fIbA8DRSTQXPAhcHKiPFo19SPqhHNHam`);

function hex_to_ascii(str1) {
  var hex = str1.toString();
  var str = '';
  for (var n = 0; n < hex.length; n += 2) {
    str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
  }
  return str;
}

async function reason(txhash) {
  let tx = await provider.getTransaction(txhash);
  if (!tx) {
    console.log('tx not found');
  } else {
    let r = await getRevertReason(txhash, "mumbai", tx.blockNumber, provider)
    // console.debug(tx);
    // delete tx.gasPrice
    // let code = await provider.call(tx, tx.blockNumber);
    // let reason = hex_to_ascii(code);
    // console.log('revert reason:', code, reason);
    return r;
  }
}

reason("0x2ecd32775b30c87ba82f944898639aefcbe5d3d8e0369de4592e38b715084f52").then(
console.log
)