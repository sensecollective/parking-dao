module Main where

import Prelude

import Chanterelle (deployMain)
import Chanterelle.Deploy (deployContract)
import Chanterelle.Internal.Types (DeployM, DeployConfig(..))
import ContractConfig (foamCSRConfig, makeParkingAuthorityConfig, simpleStorageConfig)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Exception (EXCEPTION)
import Control.Monad.Reader.Class (ask)
import Data.Lens ((?~))
import Data.Maybe (fromJust)
import Network.Ethereum.Web3 (Address, ETH, _from, _gas, defaultTransactionOptions)
import Network.Ethereum.Web3.Types.BigNumber (parseBigNumber, decimal)
import Node.FS.Aff (FS)
import Node.Process (PROCESS)
import Partial.Unsafe (unsafePartial)

main :: forall e. Eff (console :: CONSOLE, eth :: ETH, fs :: FS, process :: PROCESS, exception :: EXCEPTION | e) Unit
main = deployMain deployScript



type DeployResults =
  (foamCSR :: Address, simpleStorage :: Address, parkingAuthority :: Address)

deployScript :: forall eff. DeployM eff (Record DeployResults)
deployScript = do
  deployCfg@(DeployConfig {primaryAccount}) <- ask
  let bigGasLimit = unsafePartial fromJust $ parseBigNumber decimal "4712388"
      txOpts = defaultTransactionOptions # _from ?~ primaryAccount
                                         # _gas ?~ bigGasLimit
  simpleStorage <- deployContract txOpts simpleStorageConfig
  foamCSR <- deployContract txOpts foamCSRConfig
  let parkingAuthorityConfig = makeParkingAuthorityConfig {foamCSR: foamCSR.deployAddress}
  parkingAuthority <- deployContract txOpts parkingAuthorityConfig
  pure { foamCSR: foamCSR.deployAddress
       , simpleStorage: simpleStorage.deployAddress
       , parkingAuthority: parkingAuthority.deployAddress
       }
